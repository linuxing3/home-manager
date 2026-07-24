{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  profileBin = "${homeDir}/.nix-profile/bin";
  fffBin = "${profileBin}/fff-mcp";
in {
  home.packages = [
    pkgs.fff-mcp
    pkgs.rtk
  ];

  xdg.configFile."rtk/config.toml".text = ''
    [telemetry]
    enabled = false
  '';

  home.activation.configureAgentTools = lib.hm.dag.entryAfter ["installPackages"] ''
    export HOME=${lib.escapeShellArg homeDir}
    export RTK_TELEMETRY_DISABLED=1

    rtk_bin=${lib.escapeShellArg "${pkgs.rtk}/bin/rtk"}
    codex_bin=${lib.escapeShellArg "${profileBin}/codex"}
    hermes_bin=${lib.escapeShellArg "${profileBin}/hermes"}
    fff_bin=${lib.escapeShellArg fffBin}

    for executable in "$rtk_bin" "$codex_bin" "$hermes_bin" "$fff_bin"; do
      if [[ ! -x "$executable" ]]; then
        echo "agent-tools activation: required executable is missing: $executable" >&2
        exit 1
      fi
    done

    "$rtk_bin" init -g --codex
    "$rtk_bin" init --agent hermes

    if ! "$codex_bin" mcp get fff --json 2>/dev/null |
      ${pkgs.jq}/bin/jq -e --arg command "$fff_bin" '.transport.command == $command' >/dev/null; then
      "$codex_bin" mcp remove fff >/dev/null 2>&1 || true
      "$codex_bin" mcp add fff -- "$fff_bin"
    fi

    if ! "$hermes_bin" config get mcp_servers.fff.command 2>/dev/null |
      ${pkgs.gnugrep}/bin/grep -Fxq "$fff_bin"; then
      "$hermes_bin" mcp remove fff >/dev/null 2>&1 || true
      "$hermes_bin" mcp add fff --command "$fff_bin"
    fi
  '';
}
