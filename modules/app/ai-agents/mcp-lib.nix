{
  config,
  lib,
  pkgs,
}: let
  configHome = config.xdg.configHome;
  gdriveCredsDir = "${configHome}/gdrive-mcp";
  canvaConfigDir = "${configHome}/canva-mcp";
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
  inherit gdriveCredsDir canvaConfigDir gdriveMcp canvaMcp;

  gdrive = {
    command = "${gdriveMcp}/bin/gdrive-mcp";
    args = [];
    env = {
      GDRIVE_CREDS_DIR = gdriveCredsDir;
      GDRIVE_OAUTH_PATH = "${gdriveCredsDir}/gcp-oauth.keys.json";
      GDRIVE_CREDENTIALS_PATH = "${gdriveCredsDir}/.gdrive-server-credentials.json";
    };
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
}
