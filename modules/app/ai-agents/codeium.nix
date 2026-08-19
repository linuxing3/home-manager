{
  config,
  lib,
  pkgs,
  ...
}: let
  mcp = import ./mcp-lib.nix {inherit config lib pkgs;};
in {
  home.file.".codeium/mcp_config.json".text = builtins.toJSON {
    mcpServers = {
      inherit (mcp) gdrive canva;
      aws-mcp = mcp.aws;
    };
  };
}
