{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.ai.omp;
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
        modelRoles.default = "cursor/default";
        defaultThinkingLevel = "auto";
        providers.webSearchOrder = [];
      };
    };
  };
}
