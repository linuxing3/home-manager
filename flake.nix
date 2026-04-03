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

  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      stylix,
      nixvim,
      cachix-deploy-flake,
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
        (import ./overlays)
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
      args = {
        inherit userSettings;
        inherit systemSettings;
        inherit inputs;
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
