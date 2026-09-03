#!/usr/bin/env python3
"""stdio MCP for Gemini Veo 3.1 (overlabor / AI Studio prepaid billing)."""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

PROTOCOL = "2024-11-05"
API = "https://generativelanguage.googleapis.com/v1beta"

# Official paid-tier USD/sec with audio (ai.google.dev/gemini-api/docs/pricing).
COST_PER_SEC = {
    "veo-3.1-generate-preview": {"720p": 0.40, "1080p": 0.40, "4k": 0.60},
    "veo-3.1-fast-generate-preview": {"720p": 0.10, "1080p": 0.12, "4k": 0.30},
    "veo-3.1-lite-generate-preview": {"720p": 0.05, "1080p": 0.08},
}
DEFAULT_MODEL = "veo-3.1-lite-generate-preview"
DURATIONS = (4, 6, 8)


def api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY") or ""
    if not key:
        env_file = Path.home() / ".config/veo-mcp/env"
        if env_file.is_file():
            for line in env_file.read_text().splitlines():
                if line.startswith("GEMINI_API_KEY="):
                    key = line.split("=", 1)[1].strip().strip("'\"")
                    break
    if not key:
        raise RuntimeError(
            "GEMINI_API_KEY missing. Put it in ~/.config/veo-mcp/env"
        )
    return key


def http_json(method: str, path: str, body: dict[str, Any] | None = None) -> tuple[int, Any]:
    key = urllib.parse.quote(api_key(), safe="")
    sep = "&" if "?" in path else "?"
    url = f"{API}{path}{sep}key={key}"
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as err:
        raw = err.read().decode()
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = {"raw": raw[:2000]}
        return err.code, parsed


def list_veo_models() -> list[str]:
    code, data = http_json("GET", "/models")
    if code != 200:
        raise RuntimeError(json.dumps(data, ensure_ascii=False)[:1500])
    names = []
    for model in data.get("models") or []:
        name = str(model.get("name") or "")
        if "veo" in name.lower():
            names.append(name.removeprefix("models/"))
    return names


def estimate(model: str, duration: int, resolution: str) -> dict[str, Any]:
    table = COST_PER_SEC.get(model)
    if table is None:
        raise ValueError(f"unknown model {model}")
    rate = table.get(resolution)
    if rate is None:
        raise ValueError(f"{model} does not support {resolution}")
    if duration not in DURATIONS:
        raise ValueError(f"duration must be one of {DURATIONS}")
    return {
        "model": model,
        "durationSeconds": duration,
        "resolution": resolution,
        "usdPerSecond": rate,
        "usdPerClip": round(rate * duration, 4),
        "clipsPerUsd": int(1 / (rate * duration)) if rate * duration else 0,
    }


def account_status() -> dict[str, Any]:
    models = list_veo_models()
    code, probe = http_json(
        "POST",
        f"/models/{DEFAULT_MODEL}:predictLongRunning",
        {
            "instances": [{"prompt": "availability probe"}],
            "parameters": {"durationSeconds": 1, "aspectRatio": "16:9"},
        },
    )
    err = (probe.get("error") or {}) if isinstance(probe, dict) else {}
    message = str(err.get("message") or "")
    depleted = code == 429 and "prepayment credits are depleted" in message.lower()
    return {
        "accountHint": "overlabor77@gmail.com / project-ae468e19-b396-4a27-923",
        "models": models,
        "generationAvailable": code not in (401, 403) and not depleted,
        "httpStatus": code,
        "providerMessage": message or None,
        "prepayDepleted": depleted,
        "billing": {
            "cloudBillingOpen": True,
            "currency": "BRL",
            "geminiApi": "AI Studio prepaid credits",
            "topUp": "https://aistudio.google.com/ or https://ai.studio/projects",
        },
        "costUsdPerSecondWithAudio": COST_PER_SEC,
        "note": (
            "Gemini API Veo has no free tier. Prepaid credits are required. "
            "Cloud Billing being open is not enough if AI Studio prepay is $0."
        ),
    }


def generate_video(
    prompt: str,
    model: str,
    duration: int,
    aspect: str,
    resolution: str,
    output_dir: str,
) -> dict[str, Any]:
    est = estimate(model, duration, resolution)
    code, data = http_json(
        "POST",
        f"/models/{model}:predictLongRunning",
        {
            "instances": [{"prompt": prompt}],
            "parameters": {
                "durationSeconds": duration,
                "aspectRatio": aspect,
                "resolution": resolution,
            },
        },
    )
    if code >= 400:
        return {"ok": False, "estimate": est, "httpStatus": code, "error": data}
    name = data.get("name") if isinstance(data, dict) else None
    if not name:
        return {"ok": False, "estimate": est, "httpStatus": code, "error": data}
    op_path = name if str(name).startswith("/") else f"/{name}"
    if not op_path.startswith("/operations/") and not op_path.startswith("/v1beta/"):
        op_path = f"/operations/{name.split('/')[-1]}" if "operations/" not in str(name) else f"/{name.lstrip('/')}"
    deadline = time.time() + 600
    op = data
    while time.time() < deadline:
        if op.get("done"):
            break
        time.sleep(8)
        code, op = http_json("GET", op_path)
        if code >= 400:
            return {"ok": False, "estimate": est, "operation": name, "error": op}
    out = Path(output_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    return {
        "ok": bool(op.get("done")),
        "estimate": est,
        "operation": name,
        "result": op,
        "outputDir": str(out),
    }


TOOLS = [
    {
        "name": "veo_account_status",
        "description": "List Veo models and whether overlabor AI Studio prepaid credits can generate video.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "veo_estimate_cost",
        "description": "Estimate USD cost and clips-per-dollar for a Veo 3.1 clip.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "model": {
                    "type": "string",
                    "enum": list(COST_PER_SEC),
                    "default": DEFAULT_MODEL,
                },
                "durationSeconds": {"type": "integer", "enum": list(DURATIONS), "default": 4},
                "resolution": {"type": "string", "enum": ["720p", "1080p", "4k"], "default": "720p"},
            },
        },
    },
    {
        "name": "veo_generate_video",
        "description": "Generate a Veo 3.1 video via predictLongRunning. Costs prepaid credits.",
        "inputSchema": {
            "type": "object",
            "required": ["prompt"],
            "properties": {
                "prompt": {"type": "string"},
                "model": {"type": "string", "enum": list(COST_PER_SEC), "default": DEFAULT_MODEL},
                "durationSeconds": {"type": "integer", "enum": list(DURATIONS), "default": 4},
                "aspectRatio": {"type": "string", "enum": ["16:9", "9:16"], "default": "16:9"},
                "resolution": {"type": "string", "enum": ["720p", "1080p", "4k"], "default": "720p"},
                "outputDir": {"type": "string"},
            },
        },
    },
]


def call_tool(name: str, args: dict[str, Any]) -> str:
    if name == "veo_account_status":
        return json.dumps(account_status(), ensure_ascii=False, indent=2)
    if name == "veo_estimate_cost":
        return json.dumps(
            estimate(
                args.get("model") or DEFAULT_MODEL,
                int(args.get("durationSeconds") or 4),
                args.get("resolution") or "720p",
            ),
            indent=2,
        )
    if name == "veo_generate_video":
        home = Path.home()
        return json.dumps(
            generate_video(
                prompt=args["prompt"],
                model=args.get("model") or DEFAULT_MODEL,
                duration=int(args.get("durationSeconds") or 4),
                aspect=args.get("aspectRatio") or "16:9",
                resolution=args.get("resolution") or "720p",
                output_dir=args.get("outputDir") or str(home / "Videos" / "veo"),
            ),
            ensure_ascii=False,
            indent=2,
        )
    raise ValueError(f"unknown tool {name}")


def write_msg(msg: dict[str, Any]) -> None:
    body = json.dumps(msg).encode()
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
    sys.stdout.buffer.flush()


def read_msg() -> dict[str, Any] | None:
    headers: dict[str, str] = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        if line in (b"\r\n", b"\n"):
            break
        key, value = line.decode().split(":", 1)
        headers[key.strip().lower()] = value.strip()
    length = int(headers.get("content-length") or 0)
    if length <= 0:
        return None
    body = sys.stdin.buffer.read(length)
    return json.loads(body)


def handle(req: dict[str, Any]) -> dict[str, Any] | None:
    method = req.get("method")
    req_id = req.get("id")
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": PROTOCOL,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "veo-mcp", "version": "0.1.0"},
            },
        }
    if method in ("notifications/initialized", "notifications/cancelled"):
        return None
    if method == "ping":
        return {"jsonrpc": "2.0", "id": req_id, "result": {}}
    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": req_id, "result": {"tools": TOOLS}}
    if method == "tools/call":
        params = req.get("params") or {}
        name = params.get("name")
        args = params.get("arguments") or {}
        try:
            text = call_tool(name, args)
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"content": [{"type": "text", "text": text}]},
            }
        except Exception as err:
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "isError": True,
                    "content": [{"type": "text", "text": str(err)}],
                },
            }
    if req_id is None:
        return None
    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {"code": -32601, "message": f"Unknown method {method}"},
    }


def main() -> None:
    while True:
        req = read_msg()
        if req is None:
            return
        reply = handle(req)
        if reply is not None:
            write_msg(reply)


if __name__ == "__main__":
    main()
