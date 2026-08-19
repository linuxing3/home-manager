{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configHome = config.xdg.configHome;
  profileBin = "${homeDir}/.nix-profile/bin";
  files = ./files;
  gdriveCredsDir = "${configHome}/gdrive-mcp";
  gdriveMcpEnv = {
    GDRIVE_CREDS_DIR = gdriveCredsDir;
    GDRIVE_OAUTH_PATH = "${gdriveCredsDir}/gcp-oauth.keys.json";
    GDRIVE_CREDENTIALS_PATH = "${gdriveCredsDir}/.gdrive-server-credentials.json";
  };
  gdriveMcp = pkgs.writeShellApplication {
    name = "gdrive-mcp";
    runtimeInputs = [pkgs.nodejs];
    text = ''
      export GDRIVE_CREDS_DIR=${lib.escapeShellArg gdriveCredsDir}
      export GDRIVE_OAUTH_PATH=${lib.escapeShellArg "${gdriveCredsDir}/gcp-oauth.keys.json"}
      export GDRIVE_CREDENTIALS_PATH=${lib.escapeShellArg "${gdriveCredsDir}/.gdrive-server-credentials.json"}
      exec npx -y @modelcontextprotocol/server-gdrive "$@"
    '';
  };
  gdriveMcpServer = {
    command = "${gdriveMcp}/bin/gdrive-mcp";
    args = [];
    env = gdriveMcpEnv;
  };
  canvaConfigDir = "${configHome}/canva-mcp";
  canvaMcp = pkgs.writeShellApplication {
    name = "canva-mcp";
    runtimeInputs = [pkgs.nodejs];
    text = ''
      env_file=${lib.escapeShellArg "${canvaConfigDir}/env"}
      if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
      fi
      export CANVA_BASE_URL="''${CANVA_BASE_URL:-https://api.canva.com/rest/v1}"
      exec npx -y @mcp_factory/canva-mcp-server "$@"
    '';
  };
  canvaMcpServer = {
    command = "${canvaMcp}/bin/canva-mcp";
    args = [];
    env.CANVA_CONFIG_DIR = canvaConfigDir;
  };

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
        agent=${lib.escapeShellArg "${homeDir}/.local/bin/agent"}
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

  herdrPluginSync = pkgs.writeShellApplication {
    name = "herdr-plugin-sync";
    runtimeInputs = [pkgs.python3];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./herdr-plugin-sync.py} \
        ${files/herdr/plugins.json} ${lib.escapeShellArg "${profileBin}/herdr"}
    '';
  };

  herdrAgentRename = pkgs.writeShellApplication {
    name = "herdr-agent-rename";
    text = ''
      pane_id="''${HERDR_ACTIVE_PANE_ID:-''${HERDR_PANE_ID:-}}"
      if [[ -z "$pane_id" ]]; then
        echo "herdr-agent-rename: no active Herdr pane was provided" >&2
        exit 1
      fi

      read -r -p "Agent name: " agent_name
      if [[ ! "$agent_name" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        echo "Invalid name: use 1-32 lowercase letters, digits, _ or -, starting with a letter." >&2
        read -r -p "Press Enter to close..." _
        exit 2
      fi

      herdr_bin="''${HERDR_BIN_PATH:-${profileBin}/herdr}"
      "$herdr_bin" agent rename "$pane_id" "$agent_name"
      echo
      echo "Agent renamed to $agent_name."
      read -r -p "Press Enter to close..." _
    '';
  };

  jsonDefaults = pkgs.writeText "personal-json-defaults.json" (builtins.toJSON {
    cursor = {
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
    };
    pi = {
      theme = "dark";
      defaultProvider = "openai-codex";
      defaultModel = "gpt-5.6-terra";
    };
    ccSwitch = {
      showInTray = true;
      minimizeToTrayOnClose = true;
      commonConfigConfirmed = true;
      usageConfirmed = true;
      visibleApps = {
        codex = true;
        opencode = true;
        openclaw = true;
      };
      visibleAppsSettings = {
        mode = "manual";
        autoPromptDecided = true;
      };
      language = "zh";
      skillSyncMethod = "auto";
    };
  });

  codexDefaults = pkgs.writeText "codex-defaults.json" (builtins.toJSON {
    model = "gpt-5.6-sol";
    model_provider = "cliproxyapi";
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    model_reasoning_effort = "high";
    plan_mode_reasoning_effort = "high";
    model_providers.cliproxyapi = {
      name = "cliproxyapi";
      base_url = "http://127.0.0.1:8317/v1";
      wire_api = "responses";
      requires_openai_auth = true;
    };
    features = {
      hooks = true;
      memories = true;
    };
    tui.vim_mode_default = true;
    mcp_servers = {
      fff.command = "${homeDir}/.nix-profile/bin/fff-mcp";
      gdrive = gdriveMcpServer;
      canva = canvaMcpServer;
      obscura = {
        command = "obscura";
        args = ["mcp"];
      };
    };
  });

  cliProxyDefaults = pkgs.writeText "cli-proxy-defaults.json" (builtins.toJSON {
    host = "127.0.0.1";
    port = 8317;
    tls = {
      enable = false;
      cert = "";
      key = "";
    };
    auth-dir = "${homeDir}/.cli-proxy-api";
    debug = false;
    pprof = {
      enable = false;
      addr = "127.0.0.1:8316";
    };
    commercial-mode = false;
    logging-to-file = false;
    logs-max-total-size-mb = 0;
    error-logs-max-files = 10;
    usage-statistics-enabled = false;
    passthrough-headers = false;
    request-retry = 3;
    max-retry-credentials = 0;
    max-retry-interval = 30;
    disable-cooling = false;
    save-cooldown-status = false;
    transient-error-cooldown-seconds = 0;
    disable-image-generation = false;
    quota-exceeded = {
      switch-project = true;
      switch-preview-model = true;
      antigravity-credits = true;
    };
    routing = {
      strategy = "round-robin";
      session-affinity = false;
      session-affinity-ttl = "1h";
    };
    ws-auth = true;
    nonstream-keepalive-interval = 0;
  });

  cloudflaredDefaults = pkgs.writeText "cloudflared-defaults.json" (builtins.toJSON {
    main.ingress = [
      {
        hostname = "efwmcsyle.ccwu.cc";
        service = "ssh://127.0.0.1:22";
      }
      {service = "http_status:404";}
    ];
    cursor.ingress = [
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
  home.packages = [
    herdrAgentRename
    herdrPluginSync
    pkgs.xclip
  ];

  programs.atuin.settings = {
    enter_accept = true;
    search_mode = "daemon-fuzzy";
    sync.records = true;
    daemon = {
      enabled = true;
      autostart = true;
    };
    dotfiles.enable = true;
  };

  xdg.configFile = {
    "glow/glow.yml".source = files/glow/glow.yml;
    "television/config.toml".source = files/television/config.toml;
    "zellij/config.kdl".source = files/zellij/config.kdl;
    "smplayer/hdpi.ini".text = ''
      [hdpisupport]
      auto_scale=true
      enabled=false
      pixel_ratio=2
      scale_factor=1
    '';
    "herdr/config.toml".source = files/herdr/config.toml;
  };

  home.file = {
    ".codex/AGENTS.md".source = files/codex/AGENTS.md;
    ".codex/hooks.json".source = files/codex/hooks.json;
    ".codex/herdr-agent-state.sh" = {
      source = files/codex/herdr-agent-state.sh;
      executable = true;
    };
    ".cursor/hooks.json".source = files/cursor/hooks.json;
    ".cursor/herdr-agent-state.sh" = {
      source = files/cursor/herdr-agent-state.sh;
      executable = true;
    };
    ".local/bin/gdrive-mcp-auth" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        mkdir -p ${lib.escapeShellArg gdriveCredsDir}
        echo "Put your Google OAuth desktop-client JSON at: ${gdriveCredsDir}/gcp-oauth.keys.json"
        echo "Then this command will open/print the Google auth flow for the Drive MCP server."
        exec ${gdriveMcp}/bin/gdrive-mcp auth
      '';
    };
    ".local/bin/canva-mcp".source = "${canvaMcp}/bin/canva-mcp";
    ".local/bin/canva-mcp-token-help" = {
      executable = true;
      text = ''
                #!${pkgs.bash}/bin/bash
                set -euo pipefail
                mkdir -p ${lib.escapeShellArg canvaConfigDir}
                chmod 700 ${lib.escapeShellArg canvaConfigDir}
                env_file=${lib.escapeShellArg "${canvaConfigDir}/env"}
                if [[ ! -f "$env_file" ]]; then
                  umask 077
                  cat >"$env_file" <<'EOF'
        # Put a Canva Connect API access token here.
        # Create a Canva Developer integration at https://www.canva.dev/ and generate/obtain an OAuth access token with the scopes you need.
        CANVA_ACCESS_TOKEN=
        # Optional:
        # CANVA_BASE_URL=https://api.canva.com/rest/v1
        EOF
                fi
                echo "Canva MCP is configured. Add your token to: $env_file"
                echo "Then restart your MCP client and test a Canva tool such as canva_list_me_profile."
      '';
    };
    ".cursor/mcp.json".text = builtins.toJSON {
      mcpServers.gdrive = gdriveMcpServer;
      mcpServers.canva = canvaMcpServer;
      mcpServers.aws-mcp = {
        command = "uvx";
        args = [
          "mcp-proxy-for-aws@latest"
          "https://aws-mcp.us-east-1.api.aws/mcp"
          "--metadata"
          "INSTALL_SOURCE=aws-cli"
        ];
      };
    };
    ".codeium/mcp_config.json".text = builtins.toJSON {
      mcpServers.gdrive = gdriveMcpServer;
      mcpServers.canva = canvaMcpServer;
      mcpServers.aws-mcp = {
        command = "uvx";
        args = [
          "mcp-proxy-for-aws@latest"
          "https://aws-mcp.us-east-1.api.aws/mcp"
          "--metadata"
          "INSTALL_SOURCE=aws-cli"
        ];
      };
    };
    ".kiro/settings/mcp.json".text = builtins.toJSON {
      mcpServers.gdrive =
        gdriveMcpServer
        // {
          timeout = 100000;
          transport = "stdio";
        };
      mcpServers.canva =
        canvaMcpServer
        // {
          timeout = 100000;
          transport = "stdio";
        };
      mcpServers.aws-mcp = {
        command = "uvx";
        args = [
          "mcp-proxy-for-aws@latest"
          "https://aws-mcp.us-east-1.api.aws/mcp"
          "--metadata"
          "INSTALL_SOURCE=aws-cli"
        ];
        timeout = 100000;
        transport = "stdio";
      };
    };
    ".local/bin/cursor".source = "${cursorShim}/bin/cursor";
  };

  home.activation.mergePersonalConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu

    preserve_once() {
      source=$1
      if [[ -f "$source" && ! -e "$source.hm-bak" ]]; then
        ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$source" "$source.hm-bak"
      fi
    }

    merge_json() {
      destination=$1
      selector=$2
      ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$destination")"
      if [[ ! -e "$destination" ]]; then
        printf '{}\n' >"$destination"
        ${pkgs.coreutils}/bin/chmod 600 "$destination"
      fi
      preserve_once "$destination"
      ${pkgs.jq}/bin/jq --arg selector "$selector" --slurpfile defaults ${jsonDefaults} '
        . * ($defaults[0][$selector])
      ' "$destination" >"$destination.hm-new"
      ${pkgs.coreutils}/bin/chmod --reference="$destination" "$destination.hm-new"
      ${pkgs.coreutils}/bin/mv "$destination.hm-new" "$destination"
    }

    merge_json ${lib.escapeShellArg "${homeDir}/.cursor/cli-config.json"} cursor
    merge_json ${lib.escapeShellArg "${homeDir}/.pi/agent/settings.json"} pi
    merge_json ${lib.escapeShellArg "${homeDir}/.cc-switch/settings.json"} ccSwitch

    codex_config=${lib.escapeShellArg "${homeDir}/.codex/config.toml"}
    if [[ -f "$codex_config" ]]; then
      preserve_once "$codex_config"
      ${pkgs.yq}/bin/tomlq --toml-output --in-place --slurpfile defaults ${codexDefaults} \
        '. * $defaults[0]' "$codex_config"
      ${pkgs.coreutils}/bin/chmod --reference="$codex_config.hm-bak" "$codex_config"
    fi

    cli_proxy_config=${lib.escapeShellArg "${homeDir}/.cli-proxy-api/config.yaml"}
    if [[ -f "$cli_proxy_config" ]]; then
      preserve_once "$cli_proxy_config"
      ${pkgs.yq}/bin/yq --yaml-output --in-place --slurpfile defaults ${cliProxyDefaults} \
        '. * $defaults[0]' "$cli_proxy_config"
      ${pkgs.coreutils}/bin/chmod --reference="$cli_proxy_config.hm-bak" "$cli_proxy_config"
    fi

    cloudflared_config=${lib.escapeShellArg "${homeDir}/.cloudflared/config.yml"}
    if [[ -f "$cloudflared_config" ]]; then
      preserve_once "$cloudflared_config"
      ${pkgs.yq}/bin/yq --yaml-output --in-place --slurpfile defaults ${cloudflaredDefaults} \
        '. * $defaults[0].main' "$cloudflared_config"
      ${pkgs.coreutils}/bin/chmod --reference="$cloudflared_config.hm-bak" "$cloudflared_config"
    fi

    cursor_tunnel_config=${lib.escapeShellArg "${homeDir}/.cloudflared/cursor-openai.yml"}
    if [[ -f "$cursor_tunnel_config" ]]; then
      preserve_once "$cursor_tunnel_config"
      ${pkgs.yq}/bin/yq --yaml-output --in-place --slurpfile defaults ${cloudflaredDefaults} \
        '. * $defaults[0].cursor' "$cursor_tunnel_config"
      ${pkgs.coreutils}/bin/chmod --reference="$cursor_tunnel_config.hm-bak" "$cursor_tunnel_config"
    fi

    smplayer=${lib.escapeShellArg "${configHome}/smplayer/smplayer.ini"}
    if [[ -f "$smplayer" ]]; then
      preserve_once "$smplayer"
      ${pkgs.python3}/bin/python3 ${./merge-smplayer.py} "$smplayer"
    fi

    gcloud_config=${lib.escapeShellArg "${configHome}/gcloud/configurations/config_default"}
    if [[ -f "$gcloud_config" ]]; then
      preserve_once "$gcloud_config"
      ${pkgs.python3}/bin/python3 ${./merge-gcloud.py} "$gcloud_config"
    fi
  '';
}
