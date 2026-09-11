{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.pi;
  piSwitchEnvDir = "${ai.configHome}/pi-switch";
  piSwitchEnvFile = "${piSwitchEnvDir}/env";
  loadDeepseekKey = ''
    env_file=${lib.escapeShellArg piSwitchEnvFile}
    if [[ -z "''${DEEPSEEK_API_KEY:-}" && -f "$env_file" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$env_file"
      set +a
    fi
  '';
  piCompatWrapper = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fd
      pkgs.ripgrep
    ];
    text = ''
      ${loadDeepseekKey}
      package_pi=${lib.escapeShellArg "${cfg.package}/bin/pi"}
      package_dir=${lib.escapeShellArg "${cfg.package}/libexec/pi"}
      standalone_pi="$package_dir/pi"
      system_loader=/lib/ld-linux-aarch64.so.1

      if [[ ! -x "$package_pi" ]]; then
        echo "pi: the Home Manager package is missing: $package_pi" >&2
        exit 127
      fi

      # llm-agents.nix's Bun standalone mixes the Nix loader with UOS libc on
      # aarch64. On UOS, start it with the host loader. NixOS ships a stub at
      # the same path (stub-ld), so exec the Nix-wrapped binary there instead.
      if [[ ! -e /etc/NIXOS && -x "$system_loader" && -x "$standalone_pi" ]]; then
        export PI_PACKAGE_DIR="$package_dir"
        export PI_SKIP_VERSION_CHECK=1
        export PI_TELEMETRY=0
        exec "$system_loader" "$standalone_pi" "$@"
      fi

      exec "$package_pi" "$@"
    '';
  };
  piSwitchWrapper = pkgs.writeShellApplication {
    name = "pi-switch";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      ${loadDeepseekKey}
      exec ${lib.getExe pkgs.pi-switch} "$@"
    '';
  };
  piDefaults = pkgs.writeText "pi-defaults.json" (builtins.toJSON {
    theme = "dark";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-terra";
  });
  deepseekCompat = {
    supportsDeveloperRole = false;
    thinkingFormat = "deepseek";
    requiresReasoningContentOnAssistantMessages = true;
    supportsLongCacheRetention = true;
  };
  mkDeepseekModel = {
    id,
    name,
    cost,
    input ? ["text"],
  }: {
    inherit
      id
      name
      input
      cost
      ;
    reasoning = true;
    contextWindow = 1000000;
    maxTokens = 384000;
    thinkingLevelMap.xhigh = "max";
    compat = deepseekCompat;
  };
  deepseekModels = [
    (mkDeepseekModel {
      id = "deepseek-v4-flash";
      name = "DeepSeek V4 Flash";
      cost = {
        input = 0.22;
        output = 0.66;
        cacheRead = 0.007;
        cacheWrite = 0;
      };
    })
    (mkDeepseekModel {
      id = "deepseek-v4-pro";
      name = "DeepSeek V4 Pro";
      cost = {
        input = 0.66;
        output = 1.98;
        cacheRead = 0.022;
        cacheWrite = 0;
      };
    })
    (mkDeepseekModel {
      id = "deepseek-v4-flash-vision-exp";
      name = "DeepSeek V4 Flash Vision";
      input = ["text" "image"];
      cost = {
        input = 0.22;
        output = 0.66;
        cacheRead = 0.007;
        cacheWrite = 0;
      };
    })
  ];
  deepseekProfile = {
    api = "openai-completions";
    baseUrl = "https://api.deepseek.com/v1";
    apiKey = "$DEEPSEEK_API_KEY";
    compat = deepseekCompat;
    exposedModels = map (model: model.id) deepseekModels;
    models = deepseekModels;
  };
  piSwitchDefaults = pkgs.writeText "pi-switch-defaults.json" (builtins.toJSON {
    version = 1;
    profiles.deepseek = deepseekProfile;
  });
  piModelsDefaults = pkgs.writeText "pi-models-defaults.json" (builtins.toJSON {
    providers."pi-switch-deepseek" = {
      inherit (deepseekProfile) api baseUrl apiKey compat;
      models = deepseekModels;
    };
  });
  piSwitchEnvTemplate = pkgs.writeText "pi-switch-env" ''
    # Official DeepSeek API key. https://platform.deepseek.com/api_keys
    # Pi and pi-switch read this when DEEPSEEK_API_KEY is not already set.
    DEEPSEEK_API_KEY=
  '';
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        cfg.package
        (lib.hiPrio piCompatWrapper)
        (lib.hiPrio piSwitchWrapper)
        pkgs.pi-switch
      ];
      activation.mergePiSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${ai.activationPreamble}
        ${ai.mergeJsonFile "${ai.homeDir}/.pi/agent/settings.json" piDefaults}
        pi_settings=${lib.escapeShellArg "${ai.homeDir}/.pi/agent/settings.json"}
        ${pkgs.jq}/bin/jq '
          .packages //= []
          | if any(.packages[]?; . == "npm:@heihei0299/pi-switch") then .
            else .packages += ["npm:@heihei0299/pi-switch"]
            end
        ' "$pi_settings" >"$pi_settings.hm-new"
        ${pkgs.coreutils}/bin/chmod --reference="$pi_settings" "$pi_settings.hm-new"
        ${pkgs.coreutils}/bin/mv "$pi_settings.hm-new" "$pi_settings"

        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg piSwitchEnvDir}
        ${pkgs.coreutils}/bin/chmod 700 ${lib.escapeShellArg piSwitchEnvDir}
        pi_switch_env=${lib.escapeShellArg piSwitchEnvFile}
        if [[ ! -f "$pi_switch_env" ]]; then
          ${pkgs.coreutils}/bin/install -m 600 ${piSwitchEnvTemplate} "$pi_switch_env"
        fi

        ${ai.mergeJsonFile "${ai.homeDir}/.pi-switch/config.json" piSwitchDefaults}
        ${ai.mergeJsonFile "${ai.homeDir}/.pi/agent/models.json" piModelsDefaults}
      '';
      activation.installPiSwitch = lib.hm.dag.entryAfter ["installPackages" "linkGeneration"] ''
        pi_bin=${lib.escapeShellArg "${ai.profileBin}/pi"}
        if [[ -x "$pi_bin" ]]; then
          if [[ ! -d ${lib.escapeShellArg "${ai.homeDir}/.pi/agent/npm/node_modules/@heihei0299/pi-switch"} ]]; then
            if ! NPM_CONFIG_CACHE=${lib.escapeShellArg "${ai.homeDir}/.cache/pi-npm"} \
              PATH=${lib.escapeShellArg "${pkgs.nodejs}/bin"}''${PATH:+:$PATH} \
              "$pi_bin" install npm:@heihei0299/pi-switch; then
              echo "pi activation: pi-switch npm install failed; PATH still uses pkgs.pi-switch" >&2
            fi
          fi
        else
          echo "pi activation: skipping pi-switch install; missing $pi_bin" >&2
        fi
      '';
    };
  };
}
