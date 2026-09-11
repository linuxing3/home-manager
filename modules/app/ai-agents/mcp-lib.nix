{
  config,
  lib,
  pkgs,
}: let
  configHome = config.xdg.configHome;
  cacheHome = config.xdg.cacheHome;
  gdriveCredsDir = "${configHome}/gdrive-mcp";
  gdriveNpmCache = "${cacheHome}/gdrive-mcp-npm";
  canvaConfigDir = "${configHome}/canva-mcp";
  veoConfigDir = "${configHome}/veo-mcp";
  veoOutputDir = "${config.home.homeDirectory}/Videos/veo";
  veoMcp = pkgs.writeShellApplication {
    name = "veo-mcp";
    runtimeInputs = [pkgs.python3];
    text = ''
      env_file=${lib.escapeShellArg "${veoConfigDir}/env"}
      if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
      fi
      export VEO_OUTPUT_DIR="''${VEO_OUTPUT_DIR:-${lib.escapeShellArg veoOutputDir}}"
      exec ${pkgs.python3}/bin/python3 ${./veo-mcp/server.py} "$@"
    '';
  };
  gdriveMcp = pkgs.writeShellApplication {
    name = "gdrive-mcp";
    runtimeInputs = [pkgs.coreutils pkgs.nodejs];
    text = ''
      mkdir -p ${lib.escapeShellArg gdriveCredsDir} ${lib.escapeShellArg gdriveNpmCache}
      chmod 700 ${lib.escapeShellArg gdriveCredsDir}
      export NPM_CONFIG_CACHE=${lib.escapeShellArg gdriveNpmCache}
      export npm_config_cache=${lib.escapeShellArg gdriveNpmCache}
      export npm_config_update_notifier=false
      export GDRIVE_CREDS_DIR=${lib.escapeShellArg gdriveCredsDir}
      export GDRIVE_OAUTH_PATH=${lib.escapeShellArg "${gdriveCredsDir}/gcp-oauth.keys.json"}
      export GDRIVE_CREDENTIALS_PATH=${lib.escapeShellArg "${gdriveCredsDir}/.gdrive-server-credentials.json"}
      exec npx -y @modelcontextprotocol/server-gdrive "$@"
    '';
  };
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
in rec {
  inherit gdriveCredsDir gdriveNpmCache canvaConfigDir veoConfigDir veoOutputDir gdriveMcp canvaMcp veoMcp;

  # Stdio wrapper for Codex/Codeium. Avoids root-owned ~/.npm via a user cache.
  gdrive = {
    command = "${gdriveMcp}/bin/gdrive-mcp";
    args = [];
    env = {
      GDRIVE_CREDS_DIR = gdriveCredsDir;
      GDRIVE_OAUTH_PATH = "${gdriveCredsDir}/gcp-oauth.keys.json";
      GDRIVE_CREDENTIALS_PATH = "${gdriveCredsDir}/.gdrive-server-credentials.json";
      NPM_CONFIG_CACHE = gdriveNpmCache;
      npm_config_cache = gdriveNpmCache;
    };
  };

  # Official Google Drive remote MCP. Cursor desktop must complete Google login once.
  gdriveRemote = {
    type = "http";
    url = "https://drivemcp.googleapis.com/mcp/v1";
  };

  canva = {
    command = "${canvaMcp}/bin/canva-mcp";
    args = [];
    env.CANVA_CONFIG_DIR = canvaConfigDir;
  };

  aws = {
    command = "uvx";
    args = [
      "mcp-proxy-for-aws@latest"
      "https://aws-mcp.us-east-1.api.aws/mcp"
      "--metadata"
      "INSTALL_SOURCE=aws-cli"
    ];
  };

  veo = {
    command = "${veoMcp}/bin/veo-mcp";
    args = [];
    env = {
      VEO_OUTPUT_DIR = veoOutputDir;
    };
  };

  # Remote OAuth MCP. Cursor desktop must complete Higgsfield login once.
  higgsfield = {
    type = "http";
    url = "https://mcp.higgsfield.ai/mcp";
  };

  # Official Notion hosted MCP. OAuth on localhost:8787 (Collie is 8788).
  # Skill: .codex/skills/configure-notion-mcp. Docs: docs/notion-mcp.md.
  notion = {
    type = "http";
    url = "https://mcp.notion.com/mcp";
  };
}
