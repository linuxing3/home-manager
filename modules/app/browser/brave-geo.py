#!/usr/bin/env python3
"""Fuzzel/dmenu launcher: isolated Brave profiles on Homedge country exits."""
from __future__ import annotations

import json
import os
import pathlib
import shutil
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

HOME = pathlib.Path.home()
CACHE = HOME / ".cache/brave-geo"
PROFILE_ROOT = HOME / ".local/share/brave-geo"
LISTENERS = HOME / ".config/homedge/listeners.json"
CLASH_DIR = HOME / ".config/mihomo"
API = "http://127.0.0.1:9090"
CACHE_TTL = 45 * 60

TZ_BY_CC = {
    "KR": "Asia/Seoul",
    "JP": "Asia/Tokyo",
    "CN": "Asia/Shanghai",
    "HK": "Asia/Hong_Kong",
    "TW": "Asia/Taipei",
    "SG": "Asia/Singapore",
    "MY": "Asia/Kuala_Lumpur",
    "TH": "Asia/Bangkok",
    "VN": "Asia/Ho_Chi_Minh",
    "IN": "Asia/Kolkata",
    "AU": "Australia/Sydney",
    "US": "America/New_York",
    "CA": "America/Toronto",
    "MX": "America/Mexico_City",
    "BR": "America/Sao_Paulo",
    "GB": "Europe/London",
    "IE": "Europe/Dublin",
    "DE": "Europe/Berlin",
    "FR": "Europe/Paris",
    "NL": "Europe/Amsterdam",
    "SE": "Europe/Stockholm",
    "PL": "Europe/Warsaw",
    "IT": "Europe/Rome",
    "ES": "Europe/Madrid",
    "AE": "Asia/Dubai",
}

LANG_BY_CC = {
    "KR": ("ko_KR.UTF-8", "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7"),
    "JP": ("ja_JP.UTF-8", "ja-JP,ja;q=0.9,en-US;q=0.8,en;q=0.7"),
    "CN": ("zh_CN.UTF-8", "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"),
    "TW": ("zh_TW.UTF-8", "zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7"),
    "HK": ("zh_HK.UTF-8", "zh-HK,zh;q=0.9,en-US;q=0.8,en;q=0.7"),
    "BR": ("pt_BR.UTF-8", "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7"),
    "DE": ("de_DE.UTF-8", "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7"),
    "FR": ("fr_FR.UTF-8", "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7"),
    "ES": ("es_ES.UTF-8", "es-ES,es;q=0.9,en-US;q=0.8,en;q=0.7"),
    "GB": ("en_GB.UTF-8", "en-GB,en;q=0.9"),
    "US": ("en_US.UTF-8", "en-US,en;q=0.9"),
}


def which(name: str) -> str | None:
    return shutil.which(name)


def http_json(url: str, timeout: float = 6, proxy: str | None = None) -> dict:
    handlers = []
    if proxy:
        handlers.append(urllib.request.ProxyHandler({"http": proxy, "https": proxy}))
    opener = urllib.request.build_opener(*handlers)
    req = urllib.request.Request(url, headers={"User-Agent": "brave-geo/1"})
    with opener.open(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def clash_up() -> bool:
    try:
        http_json(API + "/version", timeout=2)
        return True
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return False


def port_open(port: int) -> bool:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.3)
    try:
        return sock.connect_ex(("127.0.0.1", port)) == 0
    finally:
        sock.close()


def reload_clash() -> None:
    req = urllib.request.Request(
        API + "/configs",
        data=json.dumps({"path": str(CLASH_DIR / "config.yaml")}).encode(),
        method="PUT",
        headers={"Content-Type": "application/json"},
    )
    try:
        urllib.request.urlopen(req, timeout=8).read()
    except (urllib.error.URLError, TimeoutError, OSError):
        pass


def ensure_clash() -> None:
    inject = os.environ.get("BRAVE_GEO_INJECT")
    config = CLASH_DIR / "config.yaml"
    if inject and config.is_file():
        subprocess.run([sys.executable, inject, str(config)], check=False)
    listeners = load_listeners()
    if clash_up():
        if listeners and any(not port_open(int(item["port"])) for item in listeners):
            reload_clash()
        return
    sync = which("homedge-sync")
    if sync:
        subprocess.run([sync], check=False)
        if inject and config.is_file():
            subprocess.run([sys.executable, inject, str(config)], check=False)
    mihomo = which("mihomo")
    if not mihomo:
        print("brave-geo: mihomo is not on PATH", file=sys.stderr)
        sys.exit(1)
    log = pathlib.Path("/tmp/brave-geo-mihomo.log")
    with log.open("ab", buffering=0) as fh:
        subprocess.Popen(
            [mihomo, "-d", str(CLASH_DIR)],
            stdout=fh,
            stderr=fh,
            start_new_session=True,
        )
    for _ in range(25):
        if clash_up():
            return
        time.sleep(0.2)
    print("brave-geo: Clash API did not come up on 127.0.0.1:9090", file=sys.stderr)
    sys.exit(1)


def load_listeners() -> list:
    if not LISTENERS.is_file():
        return []
    return json.loads(LISTENERS.read_text(encoding="utf-8"))


def load_cache() -> dict:
    path = CACHE / "exits.json"
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def save_cache(data: dict) -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    (CACHE / "exits.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def probe(port: int) -> dict:
    data = http_json("https://ifconfig.co/json", timeout=6, proxy=f"http://127.0.0.1:{port}")
    iso = (data.get("country_iso") or data.get("country_code") or "").upper()
    return {
        "ip": data.get("ip"),
        "country": data.get("country"),
        "country_iso": iso,
        "city": data.get("city"),
        "ts": time.time(),
    }


def refresh_exits(listeners: list, force: bool = False) -> dict:
    cache = {} if force else load_cache()
    now = time.time()
    todo = []
    for item in listeners:
        name = item["name"]
        hit = cache.get(name) or {}
        if (
            not force
            and hit.get("country_iso")
            and hit.get("country_iso") != "??"
            and now - float(hit.get("ts") or 0) < CACHE_TTL
        ):
            continue
        todo.append(item)
    if not todo:
        return cache

    def one(item: dict) -> tuple[str, dict]:
        name = item["name"]
        try:
            return name, probe(int(item["port"]))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as err:
            return name, {
                "ip": None,
                "country": "untested",
                "country_iso": "??",
                "city": "",
                "error": str(err),
                "ts": time.time(),
            }

    with ThreadPoolExecutor(max_workers=min(8, len(todo))) as pool:
        futs = [pool.submit(one, item) for item in todo]
        for fut in as_completed(futs):
            name, info = fut.result()
            cache[name] = info
    save_cache(cache)
    return cache


def pick(lines: list) -> str:
    payload = "\n".join(lines) + "\n"
    fuzzel = which("fuzzel")
    dmenu = which("dmenu")
    cmd = None
    if os.environ.get("WAYLAND_DISPLAY") and fuzzel:
        cmd = ["fuzzel", "--dmenu", "--prompt=Brave geo> ", "--width=56", "--lines=16", "--anchor=center"]
    elif dmenu:
        cmd = ["dmenu", "-i", "-l", "16", "-p", "Brave geo:"]
    elif fuzzel:
        cmd = ["fuzzel", "--dmenu", "--prompt=Brave geo> ", "--width=56", "--lines=16"]
    else:
        print("brave-geo: need fuzzel or dmenu", file=sys.stderr)
        sys.exit(1)
    proc = subprocess.run(cmd, input=payload, text=True, capture_output=True, check=False)
    if proc.returncode != 0:
        err = (proc.stderr or "").strip()
        if dmenu and cmd and cmd[0] == "fuzzel":
            proc = subprocess.run(
                ["dmenu", "-i", "-l", "16", "-p", "Brave geo:"],
                input=payload,
                text=True,
                capture_output=True,
                check=False,
            )
        elif err:
            print(err, file=sys.stderr)
        if proc.returncode != 0:
            sys.exit(0)
    return (proc.stdout or "").strip()


def slug(iso: str, name: str) -> str:
    raw = f"{iso}-{name}".lower()
    out = []
    for ch in raw:
        out.append(ch if ch.isalnum() else "-")
    text = "".join(out).strip("-")
    while "--" in text:
        text = text.replace("--", "-")
    return text[:48] or "direct"


def seed_profile(root: pathlib.Path) -> None:
    default = root / "Default"
    default.mkdir(parents=True, exist_ok=True)
    prefs = default / "Preferences"
    if prefs.exists():
        return
    payload = {
        "browser": {"has_seen_welcome_page": True, "check_default_browser": False},
        "enable_do_not_track": True,
        "webrtc": {"ip_handling_policy": "disable_non_proxied_udp"},
        "profile": {
            "default_content_setting_values": {
                "geolocation": 2,
                "media_stream_camera": 2,
                "media_stream_mic": 2,
            },
            "exit_type": "Normal",
        },
        "signin": {"allowed": False},
        "safebrowsing": {"enabled": False},
    }
    prefs.write_text(json.dumps(payload), encoding="utf-8")
    (root / "First Run").touch()


def launch(iso: str, name: str, port: int | None) -> None:
    brave = which("brave")
    if not brave:
        print("brave-geo: brave is not on PATH", file=sys.stderr)
        sys.exit(1)
    ident = slug(iso, name)
    root = PROFILE_ROOT / ident
    seed_profile(root)
    lang, accept = LANG_BY_CC.get(iso, ("en_US.UTF-8", "en-US,en;q=0.9"))
    env = os.environ.copy()
    for key in ("http_proxy", "https_proxy", "all_proxy", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"):
        env.pop(key, None)
    env["TZ"] = TZ_BY_CC.get(iso, "UTC")
    env["LANG"] = lang
    env["LC_ALL"] = lang
    env["LANGUAGE"] = lang.split(".")[0]
    cmd = [
        brave,
        f"--user-data-dir={root}",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-sync",
        "--disable-background-networking",
        "--disable-quic",
        "--force-webrtc-ip-handling-policy=disable_non_proxied_udp",
        "--disable-features=WebRtcHideLocalIpsWithMdns,AutofillServerCommunication,OptimizationHints",
        f"--lang={lang.split('.')[0].replace('_', '-')}",
        f"--accept-lang={accept}",
        f"--class=brave-geo-{ident}",
        "--new-window",
        "https://ifconfig.co",
    ]
    if port is not None:
        cmd[2:2] = [
            f"--proxy-server=http://127.0.0.1:{port}",
            "--proxy-bypass-list=<-loopback>",
        ]
    else:
        cmd[2:2] = ["--no-proxy-server"]
    log = pathlib.Path("/tmp") / f"brave-geo-{ident}.log"
    with log.open("ab", buffering=0) as fh:
        subprocess.Popen(cmd, env=env, stdout=fh, stderr=fh, start_new_session=True)


def menu_lines(listeners: list, cache: dict) -> list:
    lines = ["UK  Direct     VPNUK (no Clash proxy)     id=direct"]
    for item in listeners:
        info = cache.get(item["name"]) or {}
        iso = info.get("country_iso") or "??"
        city = info.get("city") or ""
        country = info.get("country") or ""
        place = (city or country or item["name"])[:18]
        lines.append(
            f"{iso:<3} {place:<18} {item['name']:<16} :{item['port']}  id={item['name']}"
        )
    lines.append("    Refresh exit countries                         id=refresh")
    return lines


def parse_choice(choice: str, listeners: list):
    if "id=direct" in choice or choice.lower().startswith("uk  direct"):
        return ("GB", "direct", None)
    if "id=refresh" in choice or "Refresh exit" in choice:
        return "refresh"
    for item in listeners:
        if f"id={item['name']}" in choice or f":{item['port']}" in choice:
            return (item["name"], item["name"], int(item["port"]))
    return "refresh"


def main() -> int:
    ensure_clash()
    listeners = load_listeners()
    if not listeners:
        print("brave-geo: no Clash URL-test groups (run homedge-sync)", file=sys.stderr)
        return 1
    cache = refresh_exits(listeners, force=False)
    while True:
        choice = pick(menu_lines(listeners, cache))
        if not choice:
            return 0
        parsed = parse_choice(choice, listeners)
        if parsed == "refresh":
            cache = refresh_exits(listeners, force=True)
            continue
        _key, name, port = parsed
        if port is None:
            launch("GB", "direct", None)
            return 0
        info = cache.get(name) or {}
        iso = info.get("country_iso") or "XX"
        if iso == "??":
            iso = "XX"
        launch(iso, name, port)
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
