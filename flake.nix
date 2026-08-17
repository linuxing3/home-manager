{
  # files in current directory
  # nixConfig = import ./nix/nix-config.nix;
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      stylix,
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
      ];
      projectOverlays = [
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
        inputs.devenv.flakeModule
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

      };
    };
}
