{
  config,
  lib,
  pkgs,
  ...
}: let
  mcp = import ./mcp-lib.nix {inherit config lib pkgs;};
  gdriveMcpAuth = pkgs.writeShellApplication {
    name = "gdrive-mcp-auth";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      mkdir -p ${lib.escapeShellArg mcp.gdriveCredsDir}
      echo "Put your Google OAuth desktop-client JSON at: ${mcp.gdriveCredsDir}/gcp-oauth.keys.json"
      echo "Then this command will open/print the Google auth flow for the Drive MCP server."
      exec ${mcp.gdriveMcp}/bin/gdrive-mcp auth
    '';
  };
  canvaEnvTemplate = pkgs.writeText "canva-mcp-env" ''
    # Put a Canva Connect API access token here.
    # Create a Canva Developer integration at https://www.canva.dev/ and generate/obtain an OAuth access token with the scopes you need.
    CANVA_ACCESS_TOKEN=
    # Optional:
    # CANVA_BASE_URL=https://api.canva.com/rest/v1
  '';
  canvaMcpTokenHelp = pkgs.writeShellApplication {
    name = "canva-mcp-token-help";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      mkdir -p ${lib.escapeShellArg mcp.canvaConfigDir}
      chmod 700 ${lib.escapeShellArg mcp.canvaConfigDir}
      env_file=${lib.escapeShellArg "${mcp.canvaConfigDir}/env"}
      if [[ ! -f "$env_file" ]]; then
        umask 077
        cp ${canvaEnvTemplate} "$env_file"
      fi
      echo "Canva MCP is configured. Add your token to: $env_file"
      echo "Then restart your MCP client and test a Canva tool such as canva_list_me_profile."
    '';
  };
in {
  home.packages = [
    mcp.canvaMcp
    gdriveMcpAuth
    canvaMcpTokenHelp
  ];
}
