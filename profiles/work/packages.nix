{
  pkgs,
  lib,
  ...
}: let
  gnirehtetCompatWrapper = pkgs.writeShellApplication {
    name = "gnirehtet";
    runtimeInputs = with pkgs; [coreutils gnugrep gnused];
    text = ''
      nix_gnirehtet=${lib.escapeShellArg "${pkgs.gnirehtet}/bin/gnirehtet"}
      wrapped=$(grep -o '"/nix/store/[^"]*/bin/\.gnirehtet-wrapped"' "$nix_gnirehtet" | head -1 | tr -d '"')
      apk=$(grep '^export GNIREHTET_APK=' "$nix_gnirehtet" | sed "s/export GNIREHTET_APK='//; s/'$//")
      export ADB=${lib.escapeShellArg "${pkgs.android-tools}/bin/adb"}
      export GNIREHTET_APK="$apk"
      exec -a "$0" "$wrapped" "$@"
    '';
  };
  gnirehtetConnect = pkgs.writeShellApplication {
    name = "gnirehtet-connect";
    runtimeInputs = [pkgs.android-tools];
    text = ''
      adb start-server >/dev/null
      adb devices -l
      exec ${gnirehtetCompatWrapper}/bin/gnirehtet run "$@"
    '';
  };
  gnirehtetShare = pkgs.writeShellApplication {
    name = "gnirehtet-share";
    runtimeInputs = with pkgs; [android-tools tinyproxy microsocks coreutils psmisc];
    text = ''
      adb start-server >/dev/null
      adb devices -l
      fuser -k 18080/tcp 1080/tcp 31416/tcp >/dev/null 2>&1 || true
      sleep 0.3
      runtime="''${XDG_RUNTIME_DIR:-/tmp}"
      conf="$runtime/gnirehtet-share-tinyproxy.conf"
      printf '%s\n' \
        'Port 18080' \
        'Listen 127.0.0.1' \
        'Timeout 600' \
        'MaxClients 32' \
        'LogLevel Info' \
        'Allow 127.0.0.1' \
        'ConnectPort 443' \
        'ConnectPort 563' >"$conf"
      tinyproxy -d -c "$conf" &
      http_pid=$!
      microsocks -i 127.0.0.1 -p 1080 &
      socks_pid=$!
      cleanup() {
        kill "$http_pid" "$socks_pid" 2>/dev/null || true
        wait "$http_pid" "$socks_pid" 2>/dev/null || true
        adb reverse --remove tcp:18080 >/dev/null 2>&1 || true
        adb reverse --remove tcp:1080 >/dev/null 2>&1 || true
      }
      trap cleanup EXIT INT TERM
      adb reverse tcp:18080 tcp:18080
      adb reverse tcp:1080 tcp:1080
      printf '%s\n' \
        'Vivo: gnirehtet USB reverse tether' \
        'iPhone on hotspot feifei:' \
        '  HTTP  10.21.163.227:18080  (Wi-Fi Manual proxy)' \
        '  SOCKS 10.21.163.227:1080   (Surge; Wi-Fi proxy Off)' \
        'Turn on Android 个人热点 if wlan2 is down. Ctrl-C stops share.'
      ${gnirehtetCompatWrapper}/bin/gnirehtet run "$@"
    '';
  };
  gnirehtetShareVpnuk = pkgs.writeShellApplication {
    name = "gnirehtet-share-vpnuk";
    runtimeInputs = with pkgs; [networkmanager iproute2 coreutils gnugrep gawk];
    text = ''
      nmcli connection up vpnuk-uk-dedicated
      wgdev=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active \
        | awk -F: '$1=="vpnuk-uk-dedicated" && $2=="wireguard" {print $3; exit}')
      if [ -z "$wgdev" ]; then
        echo 'vpnuk-uk-dedicated is not an active WireGuard connection' >&2
        exit 1
      fi
      route=$(ip route get 1.1.1.1)
      printf '%s\n' "$route"
      if ! printf '%s\n' "$route" | grep -qF " dev $wgdev"; then
        echo "public route does not use $wgdev" >&2
        exit 1
      fi
      exec ${gnirehtetShare}/bin/gnirehtet-share "$@"
    '';
  };
  # Isvoro HKT wg0 (HK home full-tunnel). Source of truth also ~/bin/isvoro-wg-*.sh.
  # Private key read at runtime from ~/.config/wireguard/isvoro-client.key — never bake into store.
  isvoroWgUp = pkgs.writeShellApplication {
    name = "isvoro-wg-up";
    runtimeInputs = with pkgs; [wireguard-tools iproute2 gawk coreutils curl];
    text = ''
      set -euo pipefail
      KEY=/home/Designers/.config/wireguard/isvoro-client.key
      EP_IP=103.138.72.79
      IFACE=$(ip -o -4 route show default | awk '{print $5; exit}')
      GW=$(ip -o -4 route show default | awk '{print $3; exit}')
      if [[ -z "''${IFACE:-}" || -z "''${GW:-}" ]]; then
        echo "No default route; abort." >&2
        exit 1
      fi
      if [[ ! -f "$KEY" ]]; then
        echo "Missing private key file: $KEY" >&2
        exit 1
      fi
      priv=$(tr -d '\n' < "$KEY")
      sudo mkdir -p /etc/wireguard
      umask 077
      conf=$(mktemp)
      cat >"$conf" <<CFG
[Interface]
Address = 10.66.66.2/24
PrivateKey = ''${priv}
PreUp = ip route replace ''${EP_IP}/32 via ''${GW} dev ''${IFACE}
PostDown = ip route del ''${EP_IP}/32 via ''${GW} dev ''${IFACE} || true

[Peer]
PublicKey = AMdDWzvPiksyFFVLAGNoNZ9TSmCBGwQL1QFJDp925FM=
Endpoint = ''${EP_IP}:10010
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CFG
      sudo install -m 600 "$conf" /etc/wireguard/wg0.conf
      rm -f "$conf"
      sudo wg-quick down wg0 2>/dev/null || true
      sudo wg-quick up wg0
      echo "--- wg ---"
      sudo wg show
      echo "--- exit ---"
      curl -s --noproxy '*' --max-time 12 https://ifconfig.me; echo
      curl -s --noproxy '*' --max-time 12 https://ipinfo.io/json; echo
    '';
  };
  isvoroWgDown = pkgs.writeShellApplication {
    name = "isvoro-wg-down";
    runtimeInputs = with pkgs; [wireguard-tools coreutils curl];
    text = ''
      set -euo pipefail
      sudo wg-quick down wg0 || true
      echo "wg0 down. Try: curl -I https://1.1.1.1"
    '';
  };

  crabboxPackage = pkgs.buildGoModule {
    pname = "crabbox";
    version = "0.22.1-e73b02f";
    src = pkgs.fetchFromGitHub {
      owner = "openclaw";
      repo = "crabbox";
      rev = "e73b02f6455f0e41c35c5a1b4f0dab3e65911005";
      hash = "sha256-JErrI5TU3BlVsYyH1NELkO14ct5J5AjdKP2B1aghFFw=";
    };
    vendorHash = "sha256-963ZX9X5extYKc9KaKkiX/mI5u4F5uoZPcHPWXAO/Hk=";
    subPackages = ["cmd/crabbox"];
    env.CGO_ENABLED = 0;
    ldflags = [
      "-s"
      "-w"
      "-X github.com/openclaw/crabbox/internal/cli.version=0.22.1-e73b02f"
    ];
  };
  # Vivo watchdog: when the phone is on USB keep gnirehtet-share up & healthy,
  # stop it on unplug. Manual "vivo off": touch ~/.local/state/vivo-off.
  vivoWatchdog = pkgs.writeShellApplication {
    name = "vivo-watchdog";
    runtimeInputs = with pkgs; [android-tools coreutils systemd gnused gawk libnotify];
    text = ''
      state="$HOME/.local/state"
      LOG="$state/vivo-watchdog.log"
      mkdir -p "$state"
      [ -e "$state/vivo-off" ] && exit 0
      if [ "$(adb get-state 2>/dev/null || true)" != "device" ]; then
        if systemctl --user is-active -q gnirehtet-share; then
          sleep 5
          if [ "$(adb get-state 2>/dev/null || true)" != "device" ]; then
            echo "$(date '+%F %T') USB unplugged, stopping share" >> "$LOG"
            systemctl --user stop gnirehtet-share
          fi
        fi
        exit 0
      fi
      if ! systemctl --user is-active -q gnirehtet-share; then
        echo "$(date '+%F %T') USB connected, starting share" >> "$LOG"
        systemctl --user start gnirehtet-share
        exit 0
      fi
      # Report Vivo hotspot IP (AP iface: wlan* /24 that is not the client wifi)
      client=$(adb shell 'ip route show default' 2>/dev/null | sed -n 's/^default.* dev \(wlan[0-9]*\).*/\1/p' | head -n1 || true)
      hip=$(adb shell 'ip -4 -o addr show' 2>/dev/null | tr -d '\r' | awk -v c="$client" '$2 ~ /^(wlan|ap|swlan)/ && $2 != c && $4 ~ /\/24$/ {split($4,a,"/"); print a[1]; exit}' || true)
      if [ -n "$hip" ] && [ "$hip" != "$(cat "$state/vivo-hotspot-ip" 2>/dev/null || true)" ]; then
        echo "$hip" > "$state/vivo-hotspot-ip"
        msg="HOTSPOT IP $hip (iPhone proxy http $hip:18080 / socks $hip:1080)"
        echo "$(date '+%F %T') $msg" >> "$LOG"
        notify-send "Vivo hotspot" "$msg" 2>/dev/null || true
      fi
      probe() { adb shell 'curl -s -m 8 -o /dev/null -w "%{http_code}" https://www.google.com' 2>/dev/null || true; }
      [ "$(probe)" = "200" ] && exit 0
      sleep 5
      code=$(probe)
      [ "$code" = "200" ] && exit 0
      echo "$(date '+%F %T') tunnel down (code=$code), restarting" >> "$LOG"
      systemctl --user restart gnirehtet-share
    '';
  };
in {
  home.packages = with pkgs; [
    yazi
    nnn
    dwm
    st-xyz
    tabbed
    helix
    git
    gh
    lazygit
    zellij
    just
    comma
    cachix
    crabboxPackage
    awscli2
    android-tools
    gnirehtet
    (lib.hiPrio gnirehtetCompatWrapper)
    gnirehtetConnect
    gnirehtetShare
    gnirehtetShareVpnuk
    isvoroWgUp
    isvoroWgDown
    cloudflared
    cloudflare-warp
    tailscale
    wrangler
    cf-cli
    sing-box
    mihomo
    homedge-sync
    homedge-clash
    homedge-singbox
    bun
    chromium
    python3
    television
    quickshell
    zathura
    imv
    sxiv
    nsxiv
    vlc
    mpv
    viu
    appimage-run
    stdenv.cc.cc.lib
    gst_all_1.gstreamer
    gst_all_1.gstreamer.out
    gst_all_1.gst-plugins-base

    # Omarchy GUIs & Work Apps (#1 & #2)
    omawrite
    localsend
    omacalc
    nautilus
    pinta
    obsidian
    aether
    omacut
  ];
  # gnirehtet-share has no WantedBy on purpose: vivo-watchdog starts it when
  # the Vivo is on USB and stops it on unplug.
  systemd.user.services.gnirehtet-share = {
    Unit = {
      Description = "Supervise home-config gnirehtet-share (Vivo USB reverse tether + iPhone HTTP :18080 / SOCKS :1080)";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${gnirehtetShare}/bin/gnirehtet-share";
      ExecStopPost = "-${pkgs.android-tools}/bin/adb shell am force-stop com.genymobile.gnirehtet";
      Restart = "always";
      RestartSec = 5;
      KillMode = "control-group";
      LogRateLimitIntervalSec = 30;
      LogRateLimitBurst = 200;
    };
  };
  systemd.user.services.vivo-watchdog = {
    Unit.Description = "Vivo USB share watchdog";
    Service = {
      Type = "oneshot";
      ExecStart = "${vivoWatchdog}/bin/vivo-watchdog";
    };
  };
  systemd.user.timers.vivo-watchdog = {
    Unit.Description = "Run Vivo watchdog every 30s";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "30s";
      AccuracySec = "10s";
    };
    Install.WantedBy = ["timers.target"];
  };
}
