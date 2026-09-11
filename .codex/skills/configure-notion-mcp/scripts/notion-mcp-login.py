#!/usr/bin/env python3
"""Tolerant Notion MCP OAuth for Cursor. Never prints tokens."""

from __future__ import annotations

import base64
import hashlib
import json
import os
import secrets
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

RESOURCE = "https://mcp.notion.com/mcp"
REDIRECT = "http://localhost:8787/callback"
RESULT = Path("/tmp/notion-mcp-login-result.json")
LOG = Path("/tmp/notion-mcp-login-req.log")
AUTHORIZE_URL = Path("/tmp/notion-mcp-authorize.url")
UA = (
    "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
)
DEFAULT_HEADERS = {
    "Accept": "application/json",
    "User-Agent": UA,
}


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def auth_files() -> list[Path]:
    extra = os.environ.get("NOTION_MCP_AUTH_FILE")
    files: list[Path] = []
    if extra:
        files.append(Path(extra))
    root = Path.home() / ".cursor" / "projects"
    if root.is_dir():
        files.extend(sorted(root.glob("*/mcp-auth.json")))
    # Unique, keep order.
    seen: set[str] = set()
    out: list[Path] = []
    for path in files:
        key = str(path)
        if key not in seen:
            seen.add(key)
            out.append(path)
    return out


def http_json(method: str, url: str, body: dict | None = None, headers: dict | None = None) -> dict:
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={**DEFAULT_HEADERS, "Content-Type": "application/json", **(headers or {})},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as err:
        raw = err.read().decode()
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {"error": raw[:300]}
        raise SystemExit(f"{method} {url} http={err.code} {payload}") from err


def form_json(url: str, fields: dict) -> dict:
    data = urllib.parse.urlencode(fields).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            **DEFAULT_HEADERS,
            "Content-Type": "application/x-www-form-urlencoded",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as err:
        raw = err.read().decode()
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {"error": raw[:300]}
        raise SystemExit(f"POST {url} http={err.code} {payload}") from err


class Callback(BaseHTTPRequestHandler):
    code = None
    state = None
    event = threading.Event()

    def log_message(self, fmt, *args):
        LOG.write_text((LOG.read_text() if LOG.exists() else "") + (fmt % args) + "\n")

    def _extract(self):
        raw = self.path or ""
        parsed = urllib.parse.urlparse(raw)
        qs = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
        if "code" not in qs and "code=" in raw:
            qs = urllib.parse.parse_qs(
                raw.split("?", 1)[-1] if "?" in raw else raw.replace("/callback", ""),
                keep_blank_values=True,
            )
        return parsed.path, qs

    def do_GET(self):
        path, qs = self._extract()
        LOG.write_text((LOG.read_text() if LOG.exists() else "") + f"GET path={path!r} keys={list(qs)}\n")
        if path in {"/sw.js", "/service-worker.js"}:
            js = (
                "self.addEventListener('install',e=>self.skipWaiting());"
                "self.addEventListener('activate',e=>e.waitUntil((async()=>{"
                "const keys=await caches.keys();await Promise.all(keys.map(k=>caches.delete(k)));"
                "await self.registration.unregister();"
                "})()));"
                "self.addEventListener('fetch',e=>{});"
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(js.encode())
            return
        code = (qs.get("code") or [None])[0]
        state = (qs.get("state") or [None])[0]
        err = (qs.get("error") or [None])[0]
        if code or err:
            Callback.code = code
            Callback.state = state
            body = (
                "<html><body style='background:#0c0c0d;color:#f4f4f5;font-family:sans-serif'>"
                "<p>Authorization complete. You can close this tab.</p>"
                "<script>navigator.serviceWorker.getRegistrations()"
                ".then(rs=>rs.forEach(r=>r.unregister()))</script>"
                "</body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body.encode())
            Callback.event.set()
            return
        body = (
            "<html><body style='background:#0c0c0d;color:#f4f4f5;font-family:sans-serif'>"
            "<p>OAuth listener is waiting. Close this tab and use the Notion authorize URL.</p>"
            "<script>navigator.serviceWorker.getRegistrations()"
            ".then(rs=>rs.forEach(r=>r.unregister()))</script>"
            "</body></html>"
        )
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body.encode())

    def do_HEAD(self):
        self.send_response(200)
        self.end_headers()


def save_tokens(client: dict, client_id: str, token: dict) -> list[str]:
    block = {
        "clientInfo": {
            "client_id": client_id,
            "client_id_issued_at": client.get("client_id_issued_at"),
            "redirect_uris": [REDIRECT, "http://127.0.0.1:8787/callback"],
            "token_endpoint_auth_method": "none",
            "grant_types": ["authorization_code", "refresh_token"],
            "response_types": ["code"],
            "client_name": "Cursor",
        },
        "tokens": {
            "access_token": token["access_token"],
            "token_type": token.get("token_type", "Bearer"),
            "expires_in": token.get("expires_in"),
            "refresh_token": token.get("refresh_token"),
            "scope": token.get("scope"),
        },
    }
    written: list[str] = []
    files = auth_files()
    if not files:
        fallback = Path.home() / ".cursor" / "projects" / "home-Designers-pi" / "mcp-auth.json"
        files = [fallback]
    for path in files:
        path.parent.mkdir(parents=True, exist_ok=True)
        current = json.loads(path.read_text()) if path.exists() else {}
        current["notion"] = block
        path.write_text(json.dumps(current, indent=2) + "\n")
        os.chmod(path, 0o600)
        written.append(str(path))
    return written


def main() -> int:
    LOG.write_text("")
    RESULT.write_text(json.dumps({"status": "starting"}))
    client = http_json(
        "POST",
        "https://mcp.notion.com/register",
        {
            "client_name": "Cursor",
            "redirect_uris": [REDIRECT, "http://127.0.0.1:8787/callback"],
            "token_endpoint_auth_method": "none",
            "grant_types": ["authorization_code", "refresh_token"],
            "response_types": ["code"],
        },
    )
    client_id = client["client_id"]
    verifier = b64url(secrets.token_bytes(32))
    challenge = b64url(hashlib.sha256(verifier.encode()).digest())
    state = b64url(
        json.dumps(
            {"id": "notion", "owner": {"workspaceId": "http://localhost:8787/callback"}, "attemptId": secrets.token_hex(8)},
            separators=(",", ":"),
        ).encode()
    )
    auth = "https://mcp.notion.com/authorize?" + urllib.parse.urlencode(
        {
            "response_type": "code",
            "client_id": client_id,
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "redirect_uri": REDIRECT,
            "state": state,
            "scope": "default",
            "resource": RESOURCE,
        }
    )
    AUTHORIZE_URL.write_text(auth + "\n")
    print(auth, flush=True)
    print(f"listening {REDIRECT} client_id={client_id}", file=sys.stderr, flush=True)
    httpd = HTTPServer(("0.0.0.0", 8787), Callback)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    RESULT.write_text(json.dumps({"status": "listening", "client_id": client_id}))
    if not Callback.event.wait(timeout=600):
        httpd.shutdown()
        RESULT.write_text(json.dumps({"status": "timeout"}))
        return 2
    httpd.shutdown()
    if not Callback.code:
        RESULT.write_text(json.dumps({"status": "no_code"}))
        return 3
    token = form_json(
        "https://mcp.notion.com/token",
        {
            "grant_type": "authorization_code",
            "code": Callback.code,
            "redirect_uri": REDIRECT,
            "client_id": client_id,
            "code_verifier": verifier,
            "resource": RESOURCE,
        },
    )
    if "access_token" not in token:
        RESULT.write_text(json.dumps({"status": "token_error", "keys": list(token)}))
        return 4
    written = save_tokens(client, client_id, token)
    RESULT.write_text(
        json.dumps(
            {
                "status": "ok",
                "has_access_token": True,
                "has_refresh_token": bool(token.get("refresh_token")),
                "token_type": token.get("token_type"),
                "expires_in": token.get("expires_in"),
                "auth_files": written,
            }
        )
    )
    print(f"saved {len(written)} mcp-auth.json files", file=sys.stderr, flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
