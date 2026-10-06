#!/usr/bin/env python3
"""Idempotently attach per-group mixed listeners for brave-geo."""
from __future__ import annotations

import json
import pathlib
import re
import sys

HOME = pathlib.Path.home()
CONFIG = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else HOME / ".config/mihomo/config.yaml"
MAP_PATH = HOME / ".config/homedge/listeners.json"
START = "# brave-geo-listeners"
END = "# end-brave-geo-listeners"
BASE_PORT = 17901
MAX_GROUPS = 16


def strip_block(text: str) -> str:
    if START not in text:
        return text
    pre, rest = text.split(START, 1)
    if END in rest:
        rest = rest.split(END, 1)[1]
        return pre.rstrip() + "\n" + rest.lstrip("\n")
    return pre.rstrip() + "\n"


def group_names(text: str) -> list[str]:
    names: list[str] = []
    blocks = re.split(r"(?m)^\s*- name:\s*", text)
    for block in blocks[1:]:
        first, _, rest = block.partition("\n")
        name = first.strip().strip("\"'")
        head = rest[:400]
        if re.search(r"(?m)^\s*type:\s*url-test\b", head):
            names.append(name)
    if not names:
        names = re.findall(r'(?m)^\s*- name:\s*"?(优选域名-\d+)"?', text)
    seen: set[str] = set()
    out: list[str] = []
    for name in names:
        if name and name not in seen:
            seen.add(name)
            out.append(name)
    return out[:MAX_GROUPS]


def yaml_str(value: str) -> str:
    if re.search(r"[:#{}[\],&*?|<>=!%@`]", value) or value != value.strip():
        return json.dumps(value, ensure_ascii=False)
    return value


def main() -> int:
    if not CONFIG.is_file():
        print(f"homedge-inject-listeners: missing {CONFIG}", file=sys.stderr)
        return 1
    text = strip_block(CONFIG.read_text(encoding="utf-8"))
    groups = group_names(text)
    mapping = [
        {"name": name, "port": BASE_PORT + i, "listen": "127.0.0.1"}
        for i, name in enumerate(groups)
    ]
    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    MAP_PATH.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if not groups:
        CONFIG.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
        return 0
    lines = [START, "listeners:"]
    for i, item in enumerate(mapping):
        lines.extend(
            [
                f"  - name: brave-geo-{i + 1:02d}",
                "    type: mixed",
                f"    listen: {item['listen']}",
                f"    port: {item['port']}",
                f"    proxy: {yaml_str(item['name'])}",
            ]
        )
    lines.append(END)
    CONFIG.write_text(text.rstrip() + "\n" + "\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
