{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ../lib.nix {inherit config lib pkgs;};
  mcp = import ../mcp-lib.nix {inherit config lib pkgs;};
  cursorShim = pkgs.writeShellApplication {
    name = "cursor";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      shim=$(readlink -f -- "$0")
      old_ifs=$IFS
      IFS=:
      for directory in $PATH; do
        [[ -n "$directory" ]] || continue
        candidate="$directory/cursor"
        [[ -x "$candidate" ]] || continue
        [[ $(readlink -f -- "$candidate") != "$shim" ]] || continue
        IFS=$old_ifs
        exec "$candidate" "$@"
      done
      IFS=$old_ifs

      if [[ ''${1:-} == agent ]]; then
        agent=${lib.escapeShellArg "${ai.homeDir}/.local/bin/agent"}
        if [[ ! -x "$agent" ]]; then
          echo "cursor: Cursor Agent is not installed at $agent" >&2
          exit 127
        fi
        exec "$agent" "$@"
      fi

      echo "cursor: no Cursor IDE executable was found in PATH" >&2
      echo "Use 'cursor agent' to start Cursor Agent." >&2
      exit 127
    '';
  };
  cursorDefaults = pkgs.writeText "cursor-defaults.json" (builtins.toJSON {
    permissions.allow = [
      "Shell(ls)"
      "Shell(which)"
      "Shell(cloudflared)"
      "Shell(rtk)"
      "Shell(ss)"
      "Shell(grep)"
      "Shell(true)"
      "Shell(head)"
      "Shell(echo)"
    ];
    version = 1;
    display.zenMode = true;
    notifications = true;
    hints = true;
    modelSlashCommands = true;
    rewind = true;
    approvalMode = "unrestricted";
    sandbox = {
      mode = "disabled";
      networkAccess = "user_config_with_defaults";
    };
    attribution = {
      attributeCommitsToAgent = true;
      attributePRsToAgent = true;
    };
  });
  cursorTunnelDefaults = pkgs.writeText "cursor-tunnel-defaults.json" (builtins.toJSON {
    ingress = [
      {
        hostname = "cursor.efwmcsyle.ccwu.cc";
        service = "http://127.0.0.1:3010";
      }
      {
        hostname = "cursor-origin.efwmcsyle.ccwu.cc";
        service = "http://127.0.0.1:3010";
      }
      {service = "http_status:404";}
    ];
  });
in {
  home.file = {
    ".cursor/hooks.json".source = files/hooks.json;
    ".cursor/herdr-agent-state.sh" = {
      source = files/herdr-agent-state.sh;
      executable = true;
    };
    ".cursor/mcp.json".text = builtins.toJSON {
      mcpServers.gdrive = mcp.gdrive;
      mcpServers.canva = mcp.canva;
      mcpServers.aws-mcp = mcp.aws;
    };
    ".local/bin/cursor".source = "${cursorShim}/bin/cursor";
  };

  home.activation.mergeCursorConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${ai.activationPreamble}
    ${ai.mergeJsonFile "${ai.homeDir}/.cursor/cli-config.json" cursorDefaults}
    ${ai.mergeYamlFile "${ai.homeDir}/.cloudflared/cursor-openai.yml" cursorTunnelDefaults ". * $defaults[0]"}
  '';
}
