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
    llm-agents.url = "github:numtide/llm-agents.nix";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # Deepin vendor tree (Phytium HDA + Glenfly Arise). Prefer 6.6.y over
    # EOL/UOS-K5.10-LTS — same drivers, newer ABI for NixOS userspace.
    deepin-kernel = {
      url = "github:deepin-community/kernel/linux-6.6.y";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    stylix,
    flake-parts,
    flake-utils,
    ...
  }: let
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
      (import ./overlays {inherit inputs;})
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
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./flake/devshells.nix
        ./flake/packages.nix
        ./flake/nixos.nix
        inputs.devenv.flakeModule
      ];

      systems = supportedSystems;

      perSystem = {system, ...}: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
            allowUnfreePredicate = _: true;
          };
          overlays = projectOverlays;
        };
      };

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
