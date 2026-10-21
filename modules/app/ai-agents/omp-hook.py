"""omp-hook: hand Notion PM Tasks `[本机·OMP]` tickets to OMP (Orca or Herdr).

  serve     127.0.0.1 listener for the omp-hook-relay Worker / Notion automation
  scan      query PM Tasks for claimable tickets, queue them, then dispatch
  dispatch  claim + launch the oldest queued ticket when no job is active
  check <page_id>   read-only eligibility check of one row (no writes)

Global flag --dry-run (or OMP_HOOK_DRY_RUN=1): read Notion, but never PATCH and
never launch OMP.
"""

import datetime as dt
import hashlib
import hmac
import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

E = os.environ.get
HOME = Path.home()
PORT = int(E("OMP_HOOK_PORT", "8791"))
BACKEND = E("OMP_HOOK_BACKEND", "orca")  # orca | herdr
HERDR = E("HERDR_BIN", "herdr")
ORCA = E("ORCA_BIN", "orca")
# Orca matches worktrees by resolved path (~/agent-data is a symlink to /share/data/...).
JOBS_DIR = os.path.realpath(E("OMP_HOOK_JOBS_DIR", str(HOME / "agent-data/omp-jobs")))
DATABASE_ID = E("OMP_HOOK_DATABASE_ID", "8feaef70-3121-4743-bfbc-df222dcc263d")
TITLE_PREFIX = E("OMP_HOOK_TITLE_PREFIX", "[本机·OMP]")
BOT_VALUE = E("OMP_HOOK_BOT", "共享")  # empty = do not check Bot
OWNER_PROP = E("OMP_HOOK_OWNER_PROP", "")  # optional extra select/people check
OWNER_VALUE = E("OMP_HOOK_OWNER_VALUE", "本机·OMP")
SEAT = E("OMP_HOOK_SEAT", "本机·OMP")
LOCK_TTL = 2 * 3600  # v0.3.5: Run ID set and Claimed at < 2h => locked
JOB_TTL = int(E("OMP_HOOK_JOB_TTL", str(6 * 3600)))
AGENIX = Path(E("OMP_HOOK_AGENIX_FILE", f"{E('XDG_RUNTIME_DIR', '/run/user/%d' % os.getuid())}/agenix/api-keys-new.age"))
KEY_FILE = Path(E("OMP_HOOK_KEY_FILE", HOME / ".config/omp-hook/secret"))
NOTION_FILE = Path(E("OMP_HOOK_NOTION_FILE", HOME / ".config/omp-hook/notion-secret"))
BOOTSTRAP = Path(E("OMP_HOOK_BOOTSTRAP", HOME / ".omp/agent/notion-bootstrap.md"))
STATE = Path(E("OMP_HOOK_STATE_DIR", HOME / ".local/state/omp-hook"))
LOG_FILE = Path(E("OMP_HOOK_LOG", HOME / "agent-data/logs/omp-hook.log"))
QUEUE, ACTIVE = STATE / "queue", STATE / "active.json"
DRY = E("OMP_HOOK_DRY_RUN", "") not in ("", "0")
BRT = dt.timezone(dt.timedelta(hours=-3))
PAGE_ID = re.compile(r"[0-9a-f]{32}")
lock = threading.Lock()


def log(event, **fields):
    line = json.dumps({"ts": dt.datetime.now(BRT).isoformat(timespec="seconds"), "event": event,
                       "dry_run": DRY, **fields}, ensure_ascii=False)
    print(line, flush=True)
    try:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a") as f:
            f.write(line + "\n")
    except OSError:
        pass


def agenix_value(name):
    try:
        for raw in AGENIX.read_text().splitlines():
            k, _, v = raw.partition("=")
            if k.strip() == name and v.strip():
                return v.strip().strip('"').strip("'")
    except OSError:
        pass
    return ""


def file_value(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return ""


def hook_key():  # agenix first, legacy file as fallback
    return E("OMP_HOOK_KEY") or agenix_value("OMP_HOOK_KEY") or file_value(KEY_FILE)


def agent_launch_env():
    """Env for orca agent launch / OMP child: Notion token without grep or agenix files in the agent."""
    env = os.environ.copy()
    token = notion_token()
    if token:
        env["NOTION_API_KEY"] = token
    env.setdefault("OMP_HOOK_DATABASE_ID", DATABASE_ID)
    env.setdefault("OMP_HOOK_AGENIX_FILE", str(AGENIX))
    return env


def notion_token():
    return E("NOTION_API_KEY") or agenix_value("NOTION_API_KEY") or file_value(NOTION_FILE)


def notion(method, path, body=None):
    token = notion_token()
    if not token:
        raise RuntimeError("NOTION_API_KEY missing")
    req = urllib.request.Request(
        f"https://api.notion.com/v1/{path}", method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {token}", "Notion-Version": "2022-06-28",
                 "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def norm_id(value):
    m = PAGE_ID.search(str(value).replace("-", "").lower())
    return m.group(0) if m else ""


def prop_text(p):
    if not p:
        return ""
    t = p.get("type")
    if t in ("title", "rich_text"):
        return "".join(x.get("plain_text", "") for x in p[t])
    if t in ("select", "status"):
        return (p[t] or {}).get("name", "")
    if t == "multi_select":
        return ",".join(x["name"] for x in p[t])
    if t == "people":
        return ",".join(x.get("name", "") for x in p[t])
    if t == "date":
        return (p[t] or {}).get("start", "") or ""
    return ""


def summarize(page):
    pr = page.get("properties", {})
    return {k: prop_text(pr.get(k)) for k in ("Task name", "Status", "Bot", "Run ID", "Claimed at")} | (
        {OWNER_PROP: prop_text(pr.get(OWNER_PROP))} if OWNER_PROP else {})


def locked(s):
    if not s["Run ID"]:
        return False
    try:
        claimed = dt.datetime.fromisoformat(s["Claimed at"].replace("Z", "+00:00"))
        if claimed.tzinfo is None:
            claimed = claimed.replace(tzinfo=BRT)
    except ValueError:
        return True  # Run ID without a parsable time: treat as taken
    return (dt.datetime.now(BRT) - claimed).total_seconds() < LOCK_TTL


def eligibility(page):
    s = summarize(page)
    if page.get("archived") or page.get("in_trash"):
        return s, "archived"
    if not s["Task name"].startswith(TITLE_PREFIX):
        return s, "prefix"
    if s["Status"] != "Not started":
        return s, "status"
    if BOT_VALUE and s["Bot"] != BOT_VALUE:
        return s, "bot"
    if OWNER_PROP and OWNER_VALUE not in s[OWNER_PROP].split(","):
        return s, "owner"
    if locked(s):
        return s, "locked"
    return s, None


def claim(page_id):
    now = dt.datetime.now(BRT)
    run_id = f"{SEAT}-{now:%Y%m%d-%H%M}"
    notion("PATCH", f"pages/{page_id}", {"properties": {
        "Status": {"select": {"name": "In progress"}},
        "Run ID": {"rich_text": [{"text": {"content": run_id}}]},
        "Claimed at": {"date": {"start": now.isoformat(timespec="minutes")}},
    }})
    after = summarize(notion("GET", f"pages/{page_id}"))  # v0.3.5: re-read, exit if not ours
    if after["Run ID"] != run_id:
        raise RuntimeError(f"claim lost to {after['Run ID']!r}")
    return run_id


def build_prompt(page_id, title, run_id):
    page_id = norm_id(page_id)
    url = f"https://www.notion.so/{page_id}"
    boot = file_value(BOOTSTRAP)
    return f"""{boot}

---
你是 {SEAT}。omp-hook 已替你认领 PM Tasks 单（Status=In progress, Run ID={run_id}），不要再认领别的单。
任务单：{title}
链接：{url}
本单 page_id（API）：{page_id}
PM Tasks database_id（API）：{DATABASE_ID}

Notion 读写（必读，禁止在 $HOME 或全盘 grep/find 找 notion 命令或 MCP 配置）：
1. 优先用已接入的 Notion MCP（例如 notion-search、fetch、更新页面/数据库属性）。不要猜测 CLI 名称，也不要扫描磁盘。
2. 若无 MCP：用 NOTION_API_KEY + Notion REST（2022-06-28）。在 agenix-env 或 agent-env 子进程里执行，不要把 token 打进命令行参数或聊天：
   - 读/改本单：GET 或 PATCH https://api.notion.com/v1/pages/{page_id}
   - 查 PM Tasks：POST https://api.notion.com/v1/databases/{DATABASE_ID}/query
   - Header：Authorization: Bearer $NOTION_API_KEY，Notion-Version: 2022-06-28
   - 密钥来源：环境变量 NOTION_API_KEY，或 $XDG_RUNTIME_DIR/agenix/api-keys-new.age 里的 NOTION_API_KEY= 行（只读取变量，禁止 cat/echo 输出值）。
3. Sync Log 仍按 bootstrap 里的 collection 追加新行；不要用 grep 找 Sync Log id。

执行规则：
1. 先用 Notion（MCP 或 REST）读这张单的全文和五项交接字段，按单子做事。
2. 遇到以下任何一项，立即停下，不要执行：删除任何东西、花钱/付费/开通收费服务、给第三方发消息或对外发布、读取/输出/移动密钥或凭证、修改 NixOS / home-config / 服务器配置。此时把单子 Status 设为 Blocked，Note 写一句原因，并在 Sync Log 追加一行 Type=Blocker。
3. 完成后：在 Sync Log 追加一行（From=共享，To=孔明，Type=Update，Entry 以 [本机·OMP] 开头，Summary ≤3 句，附路径/链接），然后把这张单 Status 设为 Review，Note 写一行证据链接。
4. 不要把密钥、cookie、签名 URL 写进 Notion、git 或聊天。
"""


def launch(page_id, title, run_id):
    prompt = build_prompt(page_id, title, run_id)
    if BACKEND == "herdr":
        agents = herdr("agent", "list").get("result", {}).get("agents", [])
        idle = [a for a in agents if a.get("agent") == "omp" and a.get("agent_status") in ("idle", "done")]
        if not idle:
            raise RuntimeError("no idle OMP pane in herdr")
        res = herdr("agent", "prompt", idle[0]["pane_id"], prompt)
        if "error" in res:
            raise RuntimeError(str(res["error"]))
        return {"backend": "herdr", "pane": idle[0]["pane_id"]}
    out = subprocess.run([ORCA, "agent", "launch", "--agent", "omp", "--worktree", f"path:{JOBS_DIR}",
                          "--prompt", prompt, "--json"], stdin=subprocess.DEVNULL,
                         capture_output=True, text=True, timeout=120, cwd=JOBS_DIR,
                         env=agent_launch_env())
    try:
        res = json.loads(out.stdout)
    except json.JSONDecodeError:
        res = {"ok": False, "raw": (out.stdout + out.stderr)[-400:]}
    if not res.get("ok"):
        raise RuntimeError(json.dumps(res, ensure_ascii=False)[:400])
    return {"backend": "orca", "result": res.get("result", {}).get("outcome", res.get("result"))}


def herdr(*args):
    out = subprocess.run([HERDR, *args], capture_output=True, text=True, timeout=30, stdin=subprocess.DEVNULL)
    try:
        return json.loads(out.stdout or "{}")
    except json.JSONDecodeError:
        return {"error": {"message": (out.stdout + out.stderr).strip()}}


def enqueue(page_id, title=""):
    page_id = norm_id(page_id)
    if not page_id:
        return "invalid"
    QUEUE.mkdir(parents=True, exist_ok=True)
    item = QUEUE / page_id
    if item.exists():
        return "already_queued"
    item.write_text(json.dumps({"page_id": page_id, "title": title, "queued_at": time.time()}))
    log("queued", page_id=page_id, title=title)
    return "queued"


def active_job():
    """Return the active job, clearing it once its row left In progress or it timed out."""
    try:
        job = json.loads(ACTIVE.read_text())
    except (OSError, ValueError):
        return None
    try:
        status = summarize(notion("GET", f"pages/{job['page_id']}"))["Status"]
    except Exception as exc:  # keep the job on transient errors
        log("active_check_failed", page_id=job["page_id"], error=str(exc)[:200])
        return job
    if status != "In progress" or time.time() - job["started"] > JOB_TTL:
        log("job_finished", page_id=job["page_id"], status=status)
        ACTIVE.unlink(missing_ok=True)
        return None
    return job


def dispatch():
    with lock:
        items = sorted(QUEUE.glob("*"), key=lambda p: p.stat().st_mtime) if QUEUE.exists() else []
        if not items:
            return
        job = active_job()
        if job:
            log("deferred", queued=len(items), active=job["page_id"])
            return
        for item in items:
            page_id = item.name
            try:
                page = notion("GET", f"pages/{page_id}")
            except Exception as exc:
                log("fetch_failed", page_id=page_id, error=str(exc)[:200])
                return
            s, reason = eligibility(page)
            if reason:
                log("skipped", page_id=page_id, reason=reason, row=s)
                if not DRY:
                    item.unlink(missing_ok=True)
                continue
            if DRY:
                prompt = build_prompt(page_id, s["Task name"], f"{SEAT}-DRYRUN")
                log("would_launch", page_id=page_id, row=s, backend=BACKEND, prompt_chars=len(prompt))
                return
            try:
                run_id = claim(page_id)
            except Exception as exc:
                log("claim_failed", page_id=page_id, error=str(exc)[:200])
                item.unlink(missing_ok=True)
                continue
            item.unlink(missing_ok=True)
            try:
                info = launch(page_id, s["Task name"], run_id)
            except Exception as exc:
                log("launch_failed", page_id=page_id, run_id=run_id, error=str(exc)[:300])
                try:
                    notion("PATCH", f"pages/{page_id}", {"properties": {
                        "Status": {"select": {"name": "Blocked"}},
                        "Note": {"rich_text": [{"text": {"content": f"omp-hook launch failed ({run_id}); see ~/agent-data/logs/omp-hook.log"}}]}}})
                except Exception:
                    pass
                return
            STATE.mkdir(parents=True, exist_ok=True)
            ACTIVE.write_text(json.dumps({"page_id": page_id, "run_id": run_id, "started": time.time(), **info}))
            log("launched", page_id=page_id, run_id=run_id, **info)
            return


def scan():
    body = {"filter": {"and": [
        {"property": "Status", "select": {"equals": "Not started"}},
        {"property": "Task name", "title": {"starts_with": TITLE_PREFIX}},
    ]}, "sorts": [{"timestamp": "created_time", "direction": "ascending"}], "page_size": 20}
    try:
        pages = notion("POST", f"databases/{DATABASE_ID}/query", body).get("results", [])
    except Exception as exc:
        log("scan_failed", error=str(exc)[:200])
        return
    for page in pages:
        enqueue(page["id"], summarize(page)["Task name"])
    log("scanned", found=len(pages))


def page_id_from(body, query):
    for cand in (body.get("page_id"), (body.get("data") or {}).get("id"),
                 (body.get("entity") or {}).get("id"), body.get("id"), query.get("page_id", [""])[0]):
        pid = norm_id(cand or "")
        if pid:
            return pid
    return ""


class Handler(BaseHTTPRequestHandler):
    key_digest = b""

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        ok = urllib.parse.urlsplit(self.path).path == "/healthz"
        self.reply(200 if ok else 404, {"ok": ok, "backend": BACKEND, "dry_run": DRY})

    def do_POST(self):
        url = urllib.parse.urlsplit(self.path)
        if url.path not in ("/hook", "/notion"):
            return self.reply(404, {"ok": False})
        query = urllib.parse.parse_qs(url.query)
        try:
            length = min(int(self.headers.get("Content-Length", "0")), 262144)
            body = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError):
            return self.reply(400, {"ok": False, "error": "bad_json"})
        given = self.headers.get("X-OMP-Hook-Key") or query.get("key", [""])[0]
        authed = hmac.compare_digest(hashlib.sha256(given.encode()).digest(), self.key_digest)
        if isinstance(body, dict) and "verification_token" in body and len(body) == 1:
            # Notion API webhook subscription handshake: store token (0600), never log it.
            STATE.mkdir(parents=True, exist_ok=True)
            p = STATE / "notion-verification-token"
            p.write_text(str(body["verification_token"]))
            p.chmod(0o600)
            log("verification_token_received", path=str(p))
            return self.reply(200, {"ok": True})
        if not authed:
            log("rejected", reason="bad_key")
            return self.reply(401, {"ok": False})
        if not isinstance(body, dict):
            return self.reply(400, {"ok": False, "error": "bad_body"})
        pid = page_id_from(body, query)
        if not pid:
            return self.reply(400, {"ok": False, "error": "bad_page_id"})
        title = str(body.get("title", ""))
        if title and not title.startswith(TITLE_PREFIX):
            return self.reply(200, {"ok": True, "skipped": "prefix"})
        result = enqueue(pid, title)
        threading.Thread(target=dispatch, daemon=True).start()
        self.reply(202, {"ok": True, "result": result})

    def log_message(self, fmt, *args):
        pass


def serve():
    key = hook_key()
    if not key:
        raise SystemExit("omp-hook: no OMP_HOOK_KEY in agenix and key file empty")
    Handler.key_digest = hashlib.sha256(key.encode()).digest()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    log("listening", port=PORT, backend=BACKEND)
    server.serve_forever()


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    if len(args) != len(sys.argv[1:]):
        DRY = True
    cmd = args[0] if args else "serve"
    if cmd == "serve":
        serve()
    elif cmd == "scan":
        scan()
        dispatch()
    elif cmd == "dispatch":
        dispatch()
    elif cmd == "check" and len(args) > 1:
        s, reason = eligibility(notion("GET", f"pages/{norm_id(args[1])}"))
        print(json.dumps({"row": s, "eligible": reason is None, "reason": reason}, ensure_ascii=False))
    else:
        raise SystemExit(f"usage: {sys.argv[0]} [--dry-run] serve|scan|dispatch|check <page_id>")
