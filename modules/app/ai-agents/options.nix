{
  lib,
  pkgs,
  inputs,
  ...
}: let
  herdrManifest = builtins.fromJSON (builtins.readFile ./herdr/files/plugins.json);
in {
  options.my.ai = {
    herdr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Herdr, its config, and optional GitHub plugins.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.llm-agents.packages.${pkgs.system}.herdr;
        description = "Herdr package from llm-agents.nix.";
      };
      plugins = lib.mkOption {
        type = lib.types.listOf (
          lib.types.either lib.types.str (lib.types.attrsOf lib.types.str)
        );
        default = herdrManifest.github;
        description = "GitHub sources for `herdr plugin install`. Use `{ source = \"owner/repo\"; ref = \"branch\"; }` for a non-default branch.";
      };
      localPlugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = herdrManifest.local or [];
        description = "Local plugin names kept as inventory only.";
      };
      installPlugins = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install `my.ai.herdr.plugins` during Home Manager activation.";
      };
    };

    collie.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the Collie Herdr bridge as a user service.";
    };

    cliProxyApi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install CLIProxyAPI and run it as a user service.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.cli-proxy-api;
        description = "CLIProxyAPI package.";
      };
    };
  };
}
