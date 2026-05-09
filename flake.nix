{
  # files in current directory
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cachix-deploy-flake = {
      url = "github:cachix/cachix-deploy-flake";
      inputs.home-manager.follows = "home-manager";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
    doxx.url = "github:bgreenwell/doxx";
    xleak.url = "github:bgreenwell/xleak";
    helix-steel-system = {
      url = "github:mattwparas/helix/steel-event-system";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
    };
    qmd = {
      url = "github:tobi/qmd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent.url = "github:NousResearch/hermes-agent?ref=v2026.5.7";
    oxwm.url = "github:tonybanters/oxwm";
    worktrunk.url = "github:max-sixty/worktrunk";
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    wezterm.url = "github:wezterm/wezterm?dir=nix";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      stylix,
      nixvim,
      helix-steel-system,
      nix-index-database,
      flake-parts,
      flake-utils,
      ...
    }:
    let
      # ---- SYSTEM SETTINGS ---- #
      systemSettings = import ./nix/system-settings.nix;
      # ----- USER SETTINGS ----- #
      userSettings = import ./nix/user-settings.nix {
        inherit nixpkgs systemSettings;
      };

      supportedSystems = builtins.filter (s: s == systemSettings.system) flake-utils.lib.defaultSystems;
      homeModules = [
        (./. + "/profiles" + ("/" + systemSettings.profile) + "/home.nix")
        stylix.homeModules.stylix
        nixvim.homeModules.nixvim
        nix-index-database.homeModules.default
      ];
      systemModules = [
        (./. + "/profiles" + ("/" + systemSettings.profile) + "/configuration.nix")
        stylix.nixosModules.stylix
      ];
      projectOverlays = [
        helix-steel-system.overlays.default
        (import ./overlays { inherit inputs; })
      ];
      pkgs = import nixpkgs {
        system = systemSettings.system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowUnfreePredicate = _: true;
        };
        overlays = projectOverlays;
      };
      patchedInputs = inputs // {
        hermes-agent = inputs.hermes-agent // {
          packages = inputs.hermes-agent.packages // {
            "${systemSettings.system}" = inputs.hermes-agent.packages.${systemSettings.system} // {
              default = pkgs.hermes-agent;
            };
          };
        };
      };
      args = {
        inherit userSettings;
        inherit systemSettings;
        inputs = patchedInputs;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/devshells.nix
        ./flake/packages.nix
      ];

      systems = supportedSystems;

      _module.args = {
        inherit userSettings systemSettings;
        inherit homeModules;
      };

      flake = {
        homeConfigurations = {
          "${userSettings.username}" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = homeModules;
            extraSpecialArgs = args;
          };
        };

        nixosConfigurations = {
          system = nixpkgs.lib.nixosSystem {
            inherit pkgs;
            system = systemSettings.system;
            modules = systemModules;
            specialArgs = args;
          };
        };
      };
    };
}
