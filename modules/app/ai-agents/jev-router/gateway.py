#!/usr/bin/env python3
"""jev-router: a tiny OpenAI/Responses-compatible failover gateway.

OMP and codex-cli point at this loopback endpoint. It forwards each request to
an ordered list of upstreams (magpie first, cursor-to-openai next). It fails
over to the next upstream on connection errors, timeouts, or retry statuses
(429/5xx), applying per-upstream auth and an optional model rewrite. Secrets are
read from the environment at request time and are never logged.

Config (JSON) is taken from $JEV_ROUTER_CONFIG. See default.nix for the schema.
"""
from __future__ import annotations

import http.client
import json
import os
import socket
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

HOP_BY_HOP = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
    "content-length",
    "content-encoding",
}

DEFAULT_RETRY_STATUSES = [429, 500, 502, 503, 504]


def log(msg: str) -> None:
    sys.stderr.write(f"[jev-router {time.strftime('%H:%M:%S')}] {msg}\n")
    sys.stderr.flush()


def load_config() -> dict:
    path = os.environ.get("JEV_ROUTER_CONFIG")
    if not path:
        raise SystemExit("jev-router: JEV_ROUTER_CONFIG is not set")
    with open(path, "r", encoding="utf-8") as handle:
        cfg = json.load(handle)
    if not cfg.get("upstreams"):
        raise SystemExit("jev-router: config has no upstreams")
    return cfg


def secret_from_env(name):
    if not name:
        return ""
    return (os.environ.get(name) or "").strip()


class Gateway:
    def __init__(self, cfg: dict):
        self.upstreams = cfg["upstreams"]
        self.connect_timeout = float(cfg.get("connect_timeout", 5))
        self.read_timeout = float(cfg.get("read_timeout", 300))

    def _auth_headers(self, up: dict) -> dict:
        auth = up.get("auth") or {}
        kind = auth.get("type", "none")
        if kind == "none":
            return {}
        value = secret_from_env(auth.get("env"))
        if not value:
            # No secret materialized: forward without auth and let the upstream
            # reject it so failover can move on.
            return {}
        if kind == "bearer":
            return {"Authorization": f"Bearer {value}"}
        if kind == "cookie":
            return {"Cookie": f"{auth['cookie_name']}={value}"}
        if kind == "header":
            return {auth["header_name"]: value}
        return {}

    def _rewrite_body(self, up: dict, body: bytes) -> bytes:
        model_map = up.get("model_map")
        if not model_map or not body:
            return body
        try:
            payload = json.loads(body)
        except (json.JSONDecodeError, UnicodeDecodeError):
            return body
        if not isinstance(payload, dict) or "model" not in payload:
            return body
        current = payload.get("model")
        payload["model"] = model_map.get(current) or model_map.get("default") or current
        return json.dumps(payload).encode("utf-8")

    def _try_upstream(self, up: dict, method: str, path: str, headers: dict, body: bytes):
        """Return (conn, resp) to relay, or None to fail over."""
        base = urlsplit(up["base_url"])
        target_path = (base.path.rstrip("/") + path) if base.path.strip("/") else path
        out_headers = {
            k: v
            for k, v in headers.items()
            if k.lower() not in HOP_BY_HOP
            and k.lower() not in ("host", "authorization", "cookie")
        }
        out_headers.update(self._auth_headers(up))
        out_headers["Host"] = base.netloc
        send_body = self._rewrite_body(up, body)
        if method in ("POST", "PUT", "PATCH"):
            out_headers["Content-Length"] = str(len(send_body or b""))

        conn_cls = (
            http.client.HTTPSConnection
            if base.scheme == "https"
            else http.client.HTTPConnection
        )
        conn = conn_cls(base.hostname, base.port, timeout=self.connect_timeout)
        try:
            conn.connect()
            conn.sock.settimeout(self.read_timeout)
            conn.request(method, target_path, body=send_body, headers=out_headers)
            resp = conn.getresponse()
        except (socket.error, http.client.HTTPException, OSError) as exc:
            try:
                conn.close()
            except Exception:
                pass
            log(f"upstream {up['name']} transport error: {type(exc).__name__}: {exc}")
            return None
        retry_statuses = up.get("retry_statuses", DEFAULT_RETRY_STATUSES)
        if resp.status in retry_statuses:
            resp.read(256)
            try:
                conn.close()
            except Exception:
                pass
            log(f"upstream {up['name']} returned {resp.status} (retry)")
            return None
        log(f"upstream {up['name']} serving status {resp.status}")
        return conn, resp

    def handle(self, handler: "Handler", method: str) -> None:
        length = int(handler.headers.get("Content-Length") or 0)
        body = handler.rfile.read(length) if length else b""
        path = handler.path
        incoming = {k: v for k, v in handler.headers.items()}

        attempts = []
        for up in self.upstreams:
            result = self._try_upstream(up, method, path, incoming, body)
            if result is None:
                attempts.append(up["name"])
                continue
            conn, resp = result
            handler.send_response(resp.status)
            handler.send_header("X-Jev-Upstream", up["name"])
            for key, value in resp.getheaders():
                if key.lower() not in HOP_BY_HOP:
                    handler.send_header(key, value)
            handler.send_header("Connection", "close")
            handler.end_headers()
            try:
                while True:
                    chunk = resp.read(65536)
                    if not chunk:
                        break
                    handler.wfile.write(chunk)
                    handler.wfile.flush()
            except (socket.error, OSError) as exc:
                log(f"stream from {up['name']} interrupted: {exc}")
            finally:
                try:
                    conn.close()
                except Exception:
                    pass
            return

        body_out = json.dumps(
            {
                "error": {
                    "message": f"jev-router: all upstreams failed ({', '.join(attempts)})",
                    "type": "upstream_unavailable",
                    "attempts": attempts,
                }
            }
        ).encode("utf-8")
        handler.send_response(502)
        handler.send_header("Content-Type", "application/json")
        handler.send_header("Content-Length", str(len(body_out)))
        handler.send_header("Connection", "close")
        handler.end_headers()
        handler.wfile.write(body_out)

    def health(self) -> dict:
        states = []
        for up in self.upstreams:
            base = urlsplit(up["base_url"])
            reachable = False
            try:
                with socket.create_connection((base.hostname, base.port), timeout=1):
                    reachable = True
            except OSError:
                reachable = False
            states.append({"name": up["name"], "reachable": reachable})
        return {"ok": True, "upstreams": states}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    gateway = None

    def log_message(self, fmt, *args):  # noqa: N802 - quiet; we log ourselves
        return

    def _health(self) -> None:
        out = json.dumps(self.gateway.health()).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(out)

    def do_GET(self):  # noqa: N802
        if self.path == "/healthz":
            self._health()
            return
        self.gateway.handle(self, "GET")

    def do_POST(self):  # noqa: N802
        self.gateway.handle(self, "POST")

    def do_PUT(self):  # noqa: N802
        self.gateway.handle(self, "PUT")

    def do_PATCH(self):  # noqa: N802
        self.gateway.handle(self, "PATCH")

    def do_DELETE(self):  # noqa: N802
        self.gateway.handle(self, "DELETE")


def main() -> int:
    cfg = load_config()
    Handler.gateway = Gateway(cfg)
    listen = cfg.get("listen", "127.0.0.1:3426")
    host, _, port = listen.rpartition(":")
    server = ThreadingHTTPServer((host or "127.0.0.1", int(port)), Handler)
    server.daemon_threads = True
    order = ", ".join(u["name"] for u in cfg["upstreams"])
    log(f"listening on {listen}; upstream order: {order}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
