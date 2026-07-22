{
  # files in current directory
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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

      };
    };
}
