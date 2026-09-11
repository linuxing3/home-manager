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
        mcp.gdriveRemote
        // {
          timeout = 100000;
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
      veo =
        mcp.veo
        // {
          timeout = 100000;
          transport = "stdio";
        };
      higgsfield =
        mcp.higgsfield
        // {
          timeout = 100000;
        };
    };
  };
}
