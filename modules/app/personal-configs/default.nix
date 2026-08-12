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

  hermesCronSync = pkgs.writeShellApplication {
    name = "hermes-cron-sync";
    runtimeInputs = [pkgs.python3];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./hermes-cron-sync.py} \
        ${files/hermes/cron-jobs.json} ${lib.escapeShellArg "${profileBin}/hermes"} \
        ${lib.escapeShellArg "${homeDir}/.hermes/cron/jobs.json"}
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

  claudeMarketplaceSync = pkgs.writeShellApplication {
    name = "claude-marketplace-sync";
    runtimeInputs = [pkgs.python3];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./claude-marketplace-sync.py} \
        ${lib.escapeShellArg "${profileBin}/claude"}
    '';
  };

  jsonDefaults = pkgs.writeText "personal-json-defaults.json" (builtins.toJSON {
    claude = {
      skipDangerousModePermissionPrompt = true;
      hooks.SessionStart = [
        {
          matcher = "*";
          hooks = [
            {
              command = "bash '${homeDir}/.claude/hooks/herdr-agent-state.sh' session";
              timeout = 10;
              type = "command";
            }
          ];
        }
      ];
    };
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
        claude = true;
        codex = true;
        opencode = true;
        hermes = true;
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
      obscura = {
        command = "obscura";
        args = ["mcp"];
      };
    };
  });

  hermesDefaults = pkgs.writeText "hermes-defaults.json" (builtins.toJSON {
    model = {
      provider = "custom";
      base_url = "http://127.0.0.1:8317/v1";
      default = "gpt-5.6-sol";
      api_key = "\${HERMES_CUSTOM_127_0_0_1_8317_API_KEY}";
    };
    agent.max_turns = 150;
    web = {
      backend = "ddgs";
      use_gateway = false;
    };
    browser = {
      cloud_provider = "local";
      use_gateway = false;
    };
    display.tool_progress = "all";
    dashboard = {
      theme = "midnight";
      font = "ibm-plex-sans";
    };
    tts.use_gateway = false;
    approvals.mcp_reload_confirm = false;
    session_reset.mode = "none";
    image_gen = {
      provider = "fal";
      use_gateway = false;
      model = "fal-ai/gpt-image-2";
    };
    video_gen = {
      provider = "fal";
      use_gateway = false;
      model = "pixverse-v6";
    };
    mcp_servers = {
      fff = {
        command = "${homeDir}/.nix-profile/bin/fff-mcp";
        enabled = true;
      };
      obscura = {
        command = "obscura";
        args = ["mcp"];
      };
    };
  });

  cliProxyDefaults = pkgs.writeText "cli-proxy-defaults.json" (builtins.toJSON {
    host = "";
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
    disable-claude-cloak-mode = false;
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
    claudeMarketplaceSync
    hermesCronSync
    herdrPluginSync
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
    ".claude/hooks/herdr-agent-state.sh" = {
      source = files/claude/herdr-agent-state.sh;
      executable = true;
    };
    ".cursor/hooks.json".source = files/cursor/hooks.json;
    ".cursor/herdr-agent-state.sh" = {
      source = files/cursor/herdr-agent-state.sh;
      executable = true;
    };
    ".cursor/mcp.json".text = builtins.toJSON {
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
    ".hermes/SOUL.md".source = files/hermes/SOUL.md;
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

    merge_json ${lib.escapeShellArg "${homeDir}/.claude/settings.json"} claude
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

    hermes_config=${lib.escapeShellArg "${homeDir}/.hermes/config.yaml"}
    if [[ -f "$hermes_config" ]]; then
      preserve_once "$hermes_config"
      ${pkgs.yq}/bin/yq --yaml-output --in-place --slurpfile defaults ${hermesDefaults} \
        '. * $defaults[0]' "$hermes_config"
      ${pkgs.coreutils}/bin/chmod --reference="$hermes_config.hm-bak" "$hermes_config"
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
