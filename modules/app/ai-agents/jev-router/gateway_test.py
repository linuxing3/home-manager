#!/usr/bin/env python3
"""jev-router returns quota and 5xx unchanged.

A dead magpie is a 502. There is no second upstream.
"""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

GATEWAY = Path(__file__).with_name("gateway.py")


class Upstream(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_POST(self):  # noqa: N802
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length) or b"{}")
        self.server.seen.append(body.get("model"))
        payload = json.dumps(
            {"error": {"message": self.server.message}, "model": body.get("model")}
        ).encode()
        self.send_response(self.server.status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, fmt, *args):  # noqa: N802
        return


def serve(status: int, message: str) -> ThreadingHTTPServer:
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), Upstream)
    httpd.status = status
    httpd.message = message
    httpd.seen = []
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def post(port: int, model: str) -> tuple[int, dict]:
    raw = json.dumps({"model": model, "messages": []}).encode()
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/v1/chat/completions",
        data=raw,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return response.status, json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        return exc.code, json.loads(exc.read().decode())


def start_router(config: dict) -> tuple[subprocess.Popen, int]:
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        listen = probe.getsockname()[1]
    config = dict(config, listen=f"127.0.0.1:{listen}")
    handle = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    json.dump(config, handle)
    handle.close()
    env = os.environ.copy()
    env["JEV_ROUTER_CONFIG"] = handle.name
    proc = subprocess.Popen(
        [sys.executable, str(GATEWAY)],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    deadline = time.time() + 5
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", listen), timeout=0.2):
                return proc, listen
        except OSError:
            if proc.poll() is not None:
                raise RuntimeError(proc.stdout.read() if proc.stdout else "router exited")
            time.sleep(0.05)
    raise RuntimeError("router did not listen")


def stop(proc: subprocess.Popen) -> None:
    proc.terminate()
    try:
        proc.wait(timeout=3)
    except subprocess.TimeoutExpired:
        proc.kill()


def main() -> int:
    magpie = serve(429, "usage limit exceeded")
    magpie_port = magpie.server_address[1]
    config = {
        "connect_timeout": 1,
        "read_timeout": 5,
        "upstreams": [
            {
                "name": "magpie",
                "base_url": f"http://127.0.0.1:{magpie_port}",
                "auth": {"type": "none"},
                "retry_statuses": [],
            },
        ],
    }
    proc, listen = start_router(config)
    try:
        status, body = post(listen, "magpie/grok/grok-4.7")
        assert status == 429, (status, body)
        assert body["model"] == "magpie/grok/grok-4.7"
        assert body["error"]["message"] == "usage limit exceeded"
        assert magpie.seen == ["magpie/grok/grok-4.7"]

        magpie.status = 500
        magpie.message = "internal server error"
        status, body = post(listen, "magpie/grok/grok-4.7")
        assert status == 500, (status, body)
        assert body["model"] == "magpie/grok/grok-4.7"
    finally:
        stop(proc)
        magpie.shutdown()
        magpie.server_close()

    dead = serve(500, "unused")
    dead.shutdown()
    dead.server_close()
    config["upstreams"][0]["base_url"] = f"http://127.0.0.1:{dead.server_address[1]}"
    proc, listen = start_router(config)
    try:
        status, body = post(listen, "magpie/grok/grok-4.7")
        assert status == 502, (status, body)
        assert body["error"]["attempts"] == ["magpie"]
    finally:
        stop(proc)
    print("jev-router quota passthrough ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
