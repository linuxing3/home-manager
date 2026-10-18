{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  herdrManifest = builtins.fromJSON (builtins.readFile ./herdr/files/plugins.json);
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
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
        default = pkgs.herdr;
        description = "Herdr package. Default is overlays/packages/herdr.nix (GitHub static release), not llm-agents source+zig build.";
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
        description = "Install Pi from llm-agents.nix and the UOS loader shim.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pi;
        description = "Pi package. Default is overlays/packages/pi.nix (GitHub release + patchelf), not llm-agents npm/bun source compile.";
      };
    };

    omp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install oh-my-pi (omp) via its Home Manager module; package defaults to the GitHub release binary overlay.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.omp;
        description = "OMP package. Default is overlays/packages/omp.nix (GitHub release + patchelf), not the slow flake source build.";
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
        default = pkgs.collie;
        description = "Collie package. Default is overlays/packages/collie.nix (GitHub release + patchelf), not llm-agents bun2nix source build.";
      };
    };

    orca = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Orca from llm-agents.nix and run `orca serve` behind orca.efwmcstyle.ccwu.cc.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = llmAgents.orca;
        description = "Orca package from llm-agents.nix.";
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

    webcodex = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install WebCodex CLI (Server + Runner) from GitHub release binaries.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.webcodex;
        description = "WebCodex package (patched GitHub release).";
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

    magpieGateway = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run the user-installed magpie binary headless so its OpenAI/Responses gateway stays up on gatewayPort.";
      };
      binary = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/bin/magpie";
        description = "Path to the magpie binary (user-managed, not a Nix package).";
      };
      gatewayPort = lib.mkOption {
        type = lib.types.port;
        default = 3425;
        description = "Fixed port where magpie serves its keyless loopback OpenAI/Responses gateway.";
      };
      uiPort = lib.mkOption {
        type = lib.types.port;
        default = 3999;
        description = "Port for magpie's browser UI, kept distinct from gatewayPort so both can bind headless.";
      };
    };

    jevRouter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run jev-router, an OpenAI/Responses failover gateway that prefers magpie and falls back to cursor-to-openai.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3426;
        description = "Loopback port OMP and codex-cli point at.";
      };
      magpiePort = lib.mkOption {
        type = lib.types.port;
        default = 3425;
        description = "Primary upstream: magpie's gateway port.";
      };
      cursorPort = lib.mkOption {
        type = lib.types.port;
        default = 3010;
        description = "Fallback upstream: cursor-to-openai port.";
      };
      cursorFallbackModel = lib.mkOption {
        type = lib.types.str;
        default = "claude-4.5-sonnet";
        description = "Model name sent to cursor-to-openai on fallback (magpie model ids are rewritten to this).";
      };
      connectTimeout = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Per-upstream TCP connect timeout in seconds before failing over.";
      };
      readTimeout = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "Per-upstream read timeout in seconds for a streamed response.";
      };
    };
  };
}
