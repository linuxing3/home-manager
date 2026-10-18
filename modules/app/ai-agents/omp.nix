{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.ai.omp;
  ai = import ./lib.nix {inherit config lib pkgs;};
  mcp = import ./mcp-lib.nix {inherit config lib pkgs;};
  globalAgents = pkgs.writeText "ai-agent-AGENTS.md" ''
    ${builtins.readFile ./files/environment-rules.md}

    ${builtins.readFile ./files/notion-bootstrap.md}
  '';
  ompMcpConfig = builtins.toJSON {
    "$schema" = "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
    mcpServers = {
      google-drive = {
        command = "npx";
        args = ["-y" "@piotr-agier/google-drive-mcp"];
        env = {
          GOOGLE_DRIVE_OAUTH_CREDENTIALS = "${config.xdg.configHome}/google-drive-mcp/gcp-oauth.keys.json";
          GOOGLE_DRIVE_MCP_TOKEN_PATH = "${config.xdg.configHome}/google-drive-mcp/tokens.json";
        };
      };
      notion = mcp.notion;
    };
  };
in {
  imports = [inputs.omp.homeManagerModules.default];

  config = lib.mkIf cfg.enable {
    home.file = {
      ".omp/agent/AGENTS.md".source = globalAgents;
      ".omp/agent/mcp.json".text = ompMcpConfig;
    };

    programs.omp = {
      enable = true;
      inherit (cfg) package;
      # HM copies this file over ~/.omp/agent/config.yml on every switch.
      # Without a pinned setupVersion / setupWizard=false, that wipe resets
      # onboarding to 0 and re-runs provider/model/theme scenes on next launch.
      settings = {
        setupVersion = 2; # packages/tui/src/setup/setup-version.ts CURRENT_SETUP_VERSION
        startup = {
          quiet = true;
          setupWizard = false;
        };
        symbolPreset = "unicode";
        composer.shape = "band";
        theme.dark = "titanium";
        # Route the default role through magpie, which OMP reaches via jev-router
        # (magpie primary, cursor-to-openai fallback). If magpie dies, jev-router
        # fails over so OMP keeps working.
        modelRoles.default = "magpie/codex/gpt-6-sol";
        defaultThinkingLevel = "auto";
        providers.webSearchOrder = [];
      };
    };

    # OMP's models.yml is user-seeded (magpie writes it). Keep its model catalog
    # but point the magpie provider at jev-router so every magpie/* request gets
    # the failover path instead of talking to magpie's gateway directly.
    home.activation.pointOmpMagpieAtJevRouter = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${ai.activationPreamble}
      models=${lib.escapeShellArg "${ai.homeDir}/.omp/agent/models.yml"}
      if [[ -f "$models" ]]; then
        preserve_once "$models"
        ${pkgs.yq}/bin/yq --yaml-output --in-place \
          '(.providers.magpie.baseUrl) = "http://127.0.0.1:${toString config.my.ai.jevRouter.port}/v1"' \
          "$models"
      fi
    '';
  };
}
