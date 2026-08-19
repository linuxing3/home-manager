{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  profileBin = "${homeDir}/.nix-profile/bin";
  fffBin = "${profileBin}/fff-mcp";
  piCompatWrapper = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fd
      pkgs.ripgrep
    ];
    text = ''
      profile_pi=${lib.escapeShellArg "${profileBin}/pi"}
      system_loader=/lib/ld-linux-aarch64.so.1

      if [[ ! -x "$profile_pi" ]]; then
        echo "pi: the Nix profile executable is missing: $profile_pi" >&2
        exit 127
      fi

      resolved_pi=$(readlink -f -- "$profile_pi")
      package_root=$(dirname -- "$(dirname -- "$resolved_pi")")
      package_dir="$package_root/libexec/pi"
      standalone_pi="$package_dir/pi"

      # llm-agents.nix's Bun standalone mixes the Nix loader with UOS libc on
      # aarch64. Starting it with the UOS loader keeps the runtime consistent.
      if [[ -x "$system_loader" && -x "$standalone_pi" ]]; then
        export PI_PACKAGE_DIR="$package_dir"
        export PI_SKIP_VERSION_CHECK=1
        export PI_TELEMETRY=0
        exec "$system_loader" "$standalone_pi" "$@"
      fi

      exec "$profile_pi" "$@"
    '';
  };
in {
  home.packages = [
    pkgs.fff-mcp
    pkgs.rtk
  ];

  home.sessionPath = lib.mkAfter [profileBin];

  home.file.".local/bin/pi".source = "${piCompatWrapper}/bin/pi";

  programs.zsh.initContent = lib.mkAfter ''
    # UOS prepends the Nix profile after .zprofile; restore user-local shims.
    path=("$HOME/.local/bin" "''${path[@]}")
    typeset -U path
    export PATH
  '';

  programs.bash.profileExtra = lib.mkAfter ''
    case ":$PATH:" in
      *:${profileBin}:*) ;;
      *) export PATH=${lib.escapeShellArg profileBin}:$PATH ;;
    esac
  '';

  xdg.configFile."rtk/config.toml".text = ''
    [telemetry]
    enabled = false
    consent_given = false
  '';

  home.activation.configureAgentTools = lib.hm.dag.entryAfter ["installPackages" "linkGeneration"] ''
    export HOME=${lib.escapeShellArg homeDir}
    export RTK_TELEMETRY_DISABLED=1

    rtk_bin=${lib.escapeShellArg "${pkgs.rtk}/bin/rtk"}
    codex_bin=${lib.escapeShellArg "${profileBin}/codex"}
    fff_bin=${lib.escapeShellArg fffBin}

    for executable in "$rtk_bin" "$fff_bin"; do
      if [[ ! -x "$executable" ]]; then
        echo "agent-tools activation: required executable is missing: $executable" >&2
        exit 1
      fi
    done

    if [[ -x "$codex_bin" ]]; then
      "$rtk_bin" init -g --codex

      if ! "$codex_bin" mcp get fff --json 2>/dev/null |
        ${pkgs.jq}/bin/jq -e --arg command "$fff_bin" '.transport.command == $command' >/dev/null; then
        "$codex_bin" mcp remove fff >/dev/null 2>&1 || true
        "$codex_bin" mcp add fff -- "$fff_bin"
      fi
    else
      echo "agent-tools activation: skipping Codex integration; missing $codex_bin" >&2
    fi

  '';
}
