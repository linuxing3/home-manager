{
  writeShellApplication,
  coreutils,
  curl,
  python3,
  mihomo,
  sing-box,
}: let
  sync = writeShellApplication {
    name = "homedge-sync";
    runtimeInputs = [coreutils curl python3];
    text = ''
      set -euo pipefail
      url_file="''${HOMEDGE_URL_FILE:-$HOME/.config/homedge/subscription.url}"
      if [[ ! -r "$url_file" ]]; then
        echo "homedge-sync: missing $url_file (one line, panel URL without /sub)" >&2
        exit 1
      fi
      base=$(tr -d ' \t\r\n' < "$url_file")
      base="''${base%/}"
      mkdir -p "$HOME/.config/homedge" "$HOME/.config/mihomo" "$HOME/.config/sing-box"
      curl -4fsS --max-time 45 -A clash-meta -o "$HOME/.config/homedge/v2ray.sub" "$base/sub"
      curl -4fsS --max-time 45 -A clash-meta -o "$HOME/.config/mihomo/config.yaml" "$base/sub?target=clash"
      curl -4fsS --max-time 45 -A SFA -o "$HOME/.config/sing-box/config.json" "$base/sub?target=singbox"
      python3 ${./homedge-inject-listeners.py} "$HOME/.config/mihomo/config.yaml"
      if [[ "''${HOMEDGE_SINGBOX_TUN:-0}" != 1 ]]; then
        python3 -c '
      import json, os, pathlib
      path = pathlib.Path(os.path.expanduser("~/.config/sing-box/config.json"))
      cfg = json.loads(path.read_text(encoding="utf-8"))
      cfg["inbounds"] = [i for i in cfg.get("inbounds", []) if i.get("type") != "tun"]
      route = cfg.get("route") or {}
      route["rules"] = [r for r in route.get("rules", []) if r.get("inbound") != "tun-in"]
      cfg["route"] = route
      path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
      '
      fi
      echo "synced clash=$HOME/.config/mihomo/config.yaml sing-box=$HOME/.config/sing-box/config.json v2ray=$HOME/.config/homedge/v2ray.sub"
    '';
  };
in {
  homedge-sync = sync;
  homedge-clash = writeShellApplication {
    name = "homedge-clash";
    runtimeInputs = [coreutils mihomo sync];
    text = ''
      set -euo pipefail
      homedge-sync
      exec mihomo -d "$HOME/.config/mihomo" "$@"
    '';
  };
  homedge-singbox = writeShellApplication {
    name = "homedge-singbox";
    runtimeInputs = [coreutils sing-box sync];
    text = ''
      set -euo pipefail
      homedge-sync
      exec sing-box run -c "$HOME/.config/sing-box/config.json" "$@"
    '';
  };
}
