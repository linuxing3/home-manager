"""Read-only QQ INBOX -> Notion「QQ 邮件收件箱」.

Mail is only listed and read with `himalaya message read --preview`, so the
server-side Seen flag never changes; nothing is sent, moved or deleted.
"""

import argparse
import datetime as dt
import email.utils
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

NOTION_VERSION = "2022-06-28"
HEADERS = ["Message-ID", "Date", "From", "Subject"]
SUMMARY_MAX = 300
TODO_MAX = 120
BATCH = 10
STATE_KEEP = 5000

SENSITIVE_HEAD = re.compile(
    r"验证码|校验码|动态码|动态密码|安全码|一次性|密码|口令|重置|找回|银行|信用卡|储蓄卡|借记卡|"
    r"账单|对账单|转账|汇款|交易|支付|付款|扣款|退款|余额|登录提醒|登录通知|异地登录|安全提醒|"
    r"授权|新应用|帐户|账户|账号|新设备|oauth|third-party app|new device|recovery|security|"
    r"verif|one[- ]?time|\bOTP\b|security (?:code|alert)|passcode|password|reset|sign[- ]?in|"
    r"log[- ]?in alert|2FA|two[- ]factor|\bbank|banco|credit card|cart[aã]o|statement|fatura|"
    r"extrato|transfer|\bpix\b|payment|pagamento|invoice|receipt|recibo|senha|c[oó]digo|"
    r"alipay|paypal|nubank|ita[uú]|bradesco|santander|caixa|icbc|ccb|abchina|cmbchina|boc\b|"
    r"bankcomm|wise\.com",
    re.I,
)
SENSITIVE_BODY = re.compile(
    r"验证码|校验码|动态码|动态密码|重置密码|verification code|one[- ]time (?:pass(?:word|code)|code)|"
    r"security code|reset your password|c[oó]digo de (?:verifica[cç][aã]o|seguran[cç]a)",
    re.I,
)
ACTION = re.compile(
    r"请回复|请确认|请尽快|请于|请在|截止|到期|逾期|报名|缴费|填写|签字|签署|待办|需要您|需要你|请您|"
    r"会议邀请|邀请您|面试|预约|deadline|due (?:date|by|on)|action required|"
    r"please (?:reply|respond|confirm|complete|review|sign|submit|pay|update)|\brsvp\b|"
    r"confirm your|prazo|vencimento|confirme|responda",
    re.I,
)
BULK_FROM = re.compile(
    r"no-?reply|newsletter|marketing|promo|mailer|notifications?@|digest|"
    r"[<@\s.](?:info|news|mail|mails|email|em|e|mkt)[@.]",
    re.I,
)
# himalaya does not expose List-Unsubscribe, so detect bulk mail from the body.
BULK_BODY = re.compile(
    r"unsubscribe|退订|取消订阅|descadastr|cancelar (?:a )?inscri|manage (?:your )?(?:email )?preferences|"
    r"view (?:it |this email )?in (?:your )?browser|在浏览器中查看|vers[aã]o web|ver no seu navegador",
    re.I,
)
NO_REPLY = re.compile(r"(?:请勿|请不要|不要)回复|do not reply|don't reply|n[aã]o responda|no-?reply", re.I)
MARKUP = re.compile(r"<#/?part[^>]*>|<[^<>]{1,200}>")
INVISIBLE = re.compile("[\u00ad\u200b-\u200f\u2060\ufeff]")

URL = re.compile(r"(?:https?://|www\.)\S+", re.I)
EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
AMOUNT = re.compile(
    r"(?:R\$|US\$|\$|¥|￥|€|£|RMB|CNY|BRL|USD|EUR)\s?\d[\d.,]*|\d[\d.,]*\s?(?:元|块|reais|BRL|USD|CNY|RMB|EUR)",
    re.I,
)
LONG_DIGITS = re.compile(r"\d[\d\s-]{4,}\d")
QUOTE_START = re.compile(
    r"^(?:-- ?$|_{5,}|-{3,}\s*Original Message|On .+ wrote:|在.+写道|发件人[:：]|From: .+@|Em .+ escreveu:)",
    re.I,
)


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def read_key(path, name):
    for line in Path(path).read_text().splitlines():
        if line.startswith(name + "="):
            return line.split("=", 1)[1].strip()
    sys.exit(f"qq-mail-notion: {name} missing in {path}")


# ---------- himalaya (read-only) ----------


class Himalaya:
    def __init__(self, config):
        self.config = config

    def run(self, args, timeout=240):
        env = dict(os.environ, RUST_LOG="error")
        r = subprocess.run(
            ["himalaya", "-c", self.config, *args],
            capture_output=True, text=True, timeout=timeout, env=env,
        )
        if r.returncode != 0:
            err = "\n".join(line for line in r.stderr.splitlines() if "WARN" not in line)[-800:]
            raise RuntimeError(f"himalaya {args[0]} {args[1]} failed: {err}")
        return r.stdout

    def envelopes_since(self, cutoff, page_size=50, max_pages=40):
        out = []
        for page in range(1, max_pages + 1):
            envs = json.loads(self.run(
                ["envelope", "list", "-f", "INBOX", "-s", str(page_size), "-p", str(page), "-o", "json"]
            ) or "[]")
            if not envs:
                break
            recent = [e for e in envs if envelope_date(e) >= cutoff]
            out += recent
            if not recent:
                break
        return out

    def read(self, ids):
        args = ["message", "read", "--preview"]
        for h in HEADERS:
            args += ["-H", h]
        return self.run(args + list(ids))


def envelope_date(env):
    try:
        return dt.datetime.strptime(env.get("date", ""), "%Y-%m-%d %H:%M%z")
    except ValueError:
        return dt.datetime.max.replace(tzinfo=dt.timezone.utc)


def parse_message(text):
    head, _, body = text.partition("\n\n")
    hdrs = {}
    for line in head.splitlines():
        k, sep, v = line.partition(": ")
        if sep and k in HEADERS:
            hdrs[k] = v.strip()
    return hdrs, body


def split_messages(text):
    blocks, cur = [], None
    for line in text.splitlines(keepends=True):
        if line.startswith("Message-ID: "):
            if cur is not None:
                blocks.append("".join(cur))
            cur = []
        if cur is not None:
            cur.append(line)
    if cur is not None:
        blocks.append("".join(cur))
    return [parse_message(b) for b in blocks]


# ---------- content shaping ----------


def mask(s):
    s = INVISIBLE.sub("", html.unescape(s))
    s = URL.sub("", MARKUP.sub(" ", s))
    s = EMAIL.sub("[邮箱]", s)
    s = AMOUNT.sub("[金额]", s)
    return LONG_DIGITS.sub("[数字]", s)


def clean_body(body):
    kept = []
    for line in body.splitlines():
        t = line.strip()
        if QUOTE_START.match(t):
            break
        if t.startswith(">"):
            continue
        kept.append(t)
    return re.sub(r"\s+", " ", mask(" ".join(kept))).strip()


def clip(s, n):
    return s if len(s) <= n else s[: n - 1] + "…"


def load_names(path):
    try:
        return [n.strip() for n in Path(path).expanduser().read_text().splitlines() if n.strip()]
    except FileNotFoundError:
        return []


def mask_names(s, names):
    for n in names:
        s = s.replace(n, "[姓名]")
    return s


def build_row(hdrs, body, env, names=()):
    subject = hdrs.get("Subject") or env.get("subject") or "(无主题)"
    sender = hdrs.get("From") or (env.get("from") or {}).get("addr", "")
    mid = hdrs.get("Message-ID") or ""
    if not mid:
        digest = hashlib.sha1(f"{env.get('date')}|{sender}|{subject}".encode()).hexdigest()
        mid = f"<no-message-id:{digest}>"
    try:
        date = email.utils.parsedate_to_datetime(hdrs["Date"]).isoformat()
    except (KeyError, TypeError, ValueError):
        d = envelope_date(env)
        date = None if d.year == dt.MAXYEAR else d.isoformat()

    text = clean_body(body)
    sensitive = bool(SENSITIVE_HEAD.search(f"{subject} {sender}") or SENSITIVE_BODY.search(body[:4000]))
    bulk = bool(BULK_FROM.search(sender) or BULK_BODY.search(body))

    todo, needs = "", False
    if not bulk:
        if ACTION.search(NO_REPLY.sub("", subject)):
            needs, todo = True, "处理：" + clip(mask(subject), TODO_MAX - 3)
        if not sensitive:
            for sent in re.split(r"(?<=[。！？!?.])\s*", text):
                if ACTION.search(NO_REPLY.sub("", sent)):
                    needs, todo = True, clip(sent, TODO_MAX)
                    break
    if sensitive:
        summary = "敏感，略"
        if needs:
            todo = "敏感邮件，见主题并在邮箱内查看"
    else:
        summary = clip(text, SUMMARY_MAX) or "（无正文）"

    return {
        "subject": clip(mask_names(subject, names), 1900), "sender": clip(mask_names(sender, names), 1900),
        "date": date, "summary": mask_names(summary, names), "needs": needs,
        "todo": mask_names(todo, names), "mid": clip(mid, 1900), "sensitive": sensitive,
    }


# ---------- Notion ----------


class Notion:
    def __init__(self, token, database):
        self.token, self.database = token, database

    def call(self, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        for attempt in range(5):
            req = urllib.request.Request(
                "https://api.notion.com/v1/" + path, data=data, method=method,
                headers={"Authorization": "Bearer " + self.token, "Notion-Version": NOTION_VERSION,
                         "Content-Type": "application/json"},
            )
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    return json.load(r)
            except urllib.error.HTTPError as e:
                if e.code in (429, 500, 502, 503, 504) and attempt < 4:
                    time.sleep(float(e.headers.get("Retry-After") or 2 ** attempt))
                    continue
                raise RuntimeError(f"Notion {method} {path.split('/')[0]}: HTTP {e.code} {e.read()[:300]!r}")
        raise RuntimeError("Notion: retries exhausted")

    def exists(self, mid):
        r = self.call("POST", f"databases/{self.database}/query", {
            "filter": {"property": "Message-ID", "rich_text": {"equals": mid}}, "page_size": 1,
        })
        return bool(r.get("results"))

    def create(self, row):
        def rt(s):
            return {"rich_text": [{"type": "text", "text": {"content": s}}] if s else []}
        props = {
            "主题": {"title": [{"type": "text", "text": {"content": row["subject"]}}]},
            "发件人": rt(row["sender"]),
            "摘要": rt(row["summary"]),
            "是否需要处理": {"checkbox": row["needs"]},
            "待办": rt(row["todo"]),
            "状态": {"select": {"name": "新"}},
            "Message-ID": rt(row["mid"]),
        }
        if row["date"]:
            props["日期"] = {"date": {"start": row["date"]}}
        self.call("POST", "pages", {"parent": {"database_id": self.database}, "properties": props})


# ---------- state ----------


def env_key(env):
    raw = f"{env.get('id')}|{env.get('date')}|{(env.get('from') or {}).get('addr')}|{env.get('subject')}"
    return hashlib.sha1(raw.encode()).hexdigest()


def load_state(path):
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, ValueError):
        return []


def save_state(path, keys):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(keys[-STATE_KEEP:]))
    tmp.replace(path)


# ---------- main ----------


def pair_batch(mail, batch):
    parsed = split_messages(mail.read([e["id"] for e in batch]))
    if len(parsed) == len(batch):
        # himalaya does not keep input order; pair blocks back by subject
        by_subject = {}
        for hdrs, body in parsed:
            by_subject.setdefault(hdrs.get("Subject", ""), []).append((hdrs, body))
        if all(by_subject.get(e.get("subject", "")) for e in batch):
            return [(e, *by_subject[e.get("subject", "")].pop(0)) for e in batch]
    pairs = []
    for e in batch:
        one = split_messages(mail.read([e["id"]]))
        pairs.append((e, *(one[0] if one else parse_message(""))))
    return pairs


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--himalaya-config", required=True)
    ap.add_argument("--database-id", required=True)
    ap.add_argument("--keys-file", required=True, help="agenix env file holding NOTION_API_KEY")
    ap.add_argument("--days", type=float, default=2, help="look back this many days")
    ap.add_argument("--dry-run", action="store_true", help="print rows, write nothing")
    ap.add_argument("--mask-names", default="~/.config/qq-mail-notion/mask-names.txt",
                    help="local file, one name per line, replaced by [姓名]; keep it out of git")
    args = ap.parse_args()

    state_path = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "qq-mail-notion/seen.json"
    seen = load_state(state_path)
    seen_set = set(seen)
    names = load_names(args.mask_names)
    mail = Himalaya(args.himalaya_config)
    notion = None if args.dry_run else Notion(read_key(args.keys_file, "NOTION_API_KEY"), args.database_id)

    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=args.days)
    envs = mail.envelopes_since(cutoff)
    pending = [e for e in envs if env_key(e) not in seen_set]
    log(f"qq-mail-notion: {len(envs)} envelopes since {cutoff:%Y-%m-%d %H:%M}Z, {len(pending)} not yet processed")

    stats = {"created": 0, "duplicate": 0, "sensitive": 0, "needs": 0}
    for i in range(0, len(pending), BATCH):
        for e, hdrs, body in pair_batch(mail, pending[i:i + BATCH]):
            row = build_row(hdrs, body, e, names)
            if args.dry_run:
                print(json.dumps(row, ensure_ascii=False))
                continue
            if notion.exists(row["mid"]):
                stats["duplicate"] += 1
            else:
                notion.create(row)
                stats["created"] += 1
                stats["sensitive"] += row["sensitive"]
                stats["needs"] += row["needs"]
            seen.append(env_key(e))
        if not args.dry_run:
            save_state(state_path, seen)

    log("qq-mail-notion: " + ", ".join(f"{k}={v}" for k, v in stats.items()))


if __name__ == "__main__":
    main()
