"""omp-hook: hand Notion PM Tasks `[本机·OMP]` tickets to the OMP pane in Herdr.

  serve     127.0.0.1 listener for the omp-hook-relay Worker (via cloudflared)
  scan      query PM Tasks for unclaimed tickets (needs NOTION_API_KEY), then dispatch
  dispatch  prompt OMP with queued tickets while it is idle
"""

import hashlib
import hmac
import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = int(os.environ.get("OMP_HOOK_PORT", "8791"))
HERDR = os.environ.get("HERDR_BIN", "herdr")
DATABASE_ID = os.environ.get("OMP_HOOK_DATABASE_ID", "8feaef70-3121-4743-bfbc-df222dcc263d")
TITLE_PREFIX = os.environ.get("OMP_HOOK_TITLE_PREFIX", "[本机·OMP]")
KEY_FILE = Path(os.environ.get("OMP_HOOK_KEY_FILE", Path.home() / ".config/omp-hook/secret"))
STATE = Path(os.environ.get("OMP_HOOK_STATE_DIR", Path.home() / ".local/state/omp-hook"))
QUEUE, SENT = STATE / "queue", STATE / "dispatched"
# A dispatched ticket that is still Not started after this long is offered again.
RETRY_AFTER = 3600
PAGE_ID = re.compile(r"^[0-9a-f]{32}$")
lock = threading.Lock()


def log(event, **fields):
    print(json.dumps({"event": event, **fields}, ensure_ascii=False), flush=True)


def enqueue(page_id, title=""):
    page_id = page_id.replace("-", "").lower()
    if not PAGE_ID.match(page_id):
        return "invalid"
    QUEUE.mkdir(parents=True, exist_ok=True)
    SENT.mkdir(parents=True, exist_ok=True)
    sent = SENT / page_id
    if sent.exists() and time.time() - sent.stat().st_mtime < RETRY_AFTER:
        return "already_dispatched"
    item = QUEUE / page_id
    if item.exists():
        return "already_queued"
    item.write_text(json.dumps({"page_id": page_id, "title": title, "queued_at": time.time()}))
    log("queued", page_id=page_id, title=title)
    return "queued"


def herdr(*args):
    out = subprocess.run([HERDR, *args], capture_output=True, text=True, timeout=30)
    try:
        return json.loads(out.stdout or "{}")
    except json.JSONDecodeError:
        return {"error": {"message": (out.stdout + out.stderr).strip()}}


def omp_pane():
    agents = herdr("agent", "list").get("result", {}).get("agents", [])
    omp = [a for a in agents if a.get("agent") == "omp"]
    idle = [a for a in omp if a.get("agent_status") in ("idle", "done")]
    if idle:
        return idle[0]["pane_id"], None
    return None, ",".join(a.get("agent_status", "?") for a in omp) or "no_omp_pane"


def dispatch():
    with lock:
        items = sorted(QUEUE.glob("*"), key=lambda p: p.stat().st_mtime) if QUEUE.exists() else []
        if not items:
            return
        pane, busy = omp_pane()
        if not pane:
            log("deferred", queued=len(items), omp=busy)
            return
        item = items[0]
        page_id = item.name
        url = f"https://www.notion.so/{page_id}"
        res = herdr("agent", "prompt", pane, f"领取 PM Tasks 单 {url} 并执行")
        if "error" in res:
            log("prompt_failed", page_id=page_id, pane=pane, error=res["error"])
            return
        SENT.mkdir(parents=True, exist_ok=True)
        item.replace(SENT / page_id)
        (SENT / page_id).touch()
        log("dispatched", page_id=page_id, pane=pane, remaining=len(items) - 1)


def scan():
    token = os.environ.get("NOTION_API_KEY")
    if not token:
        log("scan_skipped", reason="NOTION_API_KEY missing")
        return
    body = json.dumps({
        "filter": {"and": [
            {"property": "Status", "select": {"equals": "Not started"}},
            {"property": "Task name", "title": {"starts_with": TITLE_PREFIX}},
        ]},
        "sorts": [{"timestamp": "created_time", "direction": "ascending"}],
        "page_size": 20,
    }).encode()
    req = urllib.request.Request(
        f"https://api.notion.com/v1/databases/{DATABASE_ID}/query",
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Notion-Version": "2022-06-28",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        pages = json.load(resp).get("results", [])
    for page in pages:
        title = "".join(t.get("plain_text", "") for t in page["properties"]["Task name"]["title"])
        enqueue(page["id"], title)
    log("scanned", found=len(pages))


def load_key():
    key = KEY_FILE.read_text().strip()
    if not key:
        raise SystemExit(f"omp-hook: {KEY_FILE} is empty")
    return hashlib.sha256(key.encode()).digest()


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
        self.reply(200 if self.path == "/healthz" else 404, {"ok": self.path == "/healthz"})

    def do_POST(self):
        if self.path != "/hook":
            return self.reply(404, {"ok": False})
        got = hashlib.sha256(self.headers.get("X-OMP-Hook-Key", "").encode()).digest()
        if not hmac.compare_digest(got, self.key_digest):
            log("rejected", reason="bad_key")
            return self.reply(401, {"ok": False})
        try:
            length = min(int(self.headers.get("Content-Length", "0")), 65536)
            body = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError):
            return self.reply(400, {"ok": False, "error": "bad_json"})
        title = str(body.get("title", ""))
        if title and not title.startswith(TITLE_PREFIX):
            return self.reply(200, {"ok": True, "skipped": "prefix"})
        result = enqueue(str(body.get("page_id", "")), title)
        if result == "invalid":
            return self.reply(400, {"ok": False, "error": "bad_page_id"})
        threading.Thread(target=dispatch, daemon=True).start()
        self.reply(202, {"ok": True, "result": result})

    def log_message(self, fmt, *args):
        pass


def serve():
    Handler.key_digest = load_key()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    log("listening", port=PORT)
    server.serve_forever()


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "serve"
    if cmd == "serve":
        serve()
    elif cmd == "scan":
        scan()
        dispatch()
    elif cmd == "dispatch":
        dispatch()
    else:
        raise SystemExit(f"usage: {sys.argv[0]} serve|scan|dispatch")
