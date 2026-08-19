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
    android-tools
    gnirehtet
    cloudflared
    cloudflare-warp
    tailscale
    wrangler
    bun
    chromium
    python3
    television
    zathura
    imv
    sxiv
    nsxiv
    vlc
    mpv
    viu
  ];

  home.file = {
    ".local/bin/gnirehtet".source = "${gnirehtetCompatWrapper}/bin/gnirehtet";
    ".local/bin/gnirehtet-connect" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        ${pkgs.android-tools}/bin/adb start-server >/dev/null
        ${pkgs.android-tools}/bin/adb devices -l
        exec ${gnirehtetCompatWrapper}/bin/gnirehtet run "$@"
      '';
    };
  };
}
