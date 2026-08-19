{
  config,
  lib,
  pkgs,
  ...
}: let
  mcp = import ./mcp-lib.nix {inherit config lib pkgs;};
in {
  home.file.".kiro/settings/mcp.json".text = builtins.toJSON {
    mcpServers = {
      gdrive =
        mcp.gdrive
        // {
          timeout = 100000;
          transport = "stdio";
        };
      canva =
        mcp.canva
        // {
          timeout = 100000;
          transport = "stdio";
        };
      aws-mcp =
        mcp.aws
        // {
          timeout = 100000;
          transport = "stdio";
        };
    };
  };
}
