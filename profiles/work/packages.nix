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
}
