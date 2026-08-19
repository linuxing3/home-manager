{
  lib,
  pkgs,
  inputs,
  ...
}: let
  herdrManifest = builtins.fromJSON (builtins.readFile ./herdr/files/plugins.json);
  llmAgents = inputs.llm-agents.packages.${pkgs.system};
in {
  options.my.ai = {
    herdr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Herdr from llm-agents.nix, its config, and optional GitHub plugins.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = llmAgents.herdr;
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

    pi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Pi from llm-agents.nix, the UOS loader shim, and pi-switch.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = llmAgents.pi;
        description = "Pi package from llm-agents.nix.";
      };
    };

    collie = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Collie from llm-agents.nix and run the Herdr bridge as a user service.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = llmAgents.collie;
        description = "Collie package from llm-agents.nix.";
      };
    };

    cursorAgent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Cursor Agent (`cursor-agent`) from llm-agents.nix.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = llmAgents.cursor-agent;
        description = "Cursor Agent package from llm-agents.nix.";
      };
    };

    dsh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install the DeepSeek Harness CLI (`dsh`) from the GitHub source checkout.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.dsh;
        description = "DeepSeek Harness package.";
      };
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
