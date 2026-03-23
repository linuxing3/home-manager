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
    doxx.url = "github:bgreenwell/doxx";
    xleak.url = "github:bgreenwell/xleak";
    helix-steel-system = {
      url = "github:mattwparas/helix/steel-event-system";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      stylix,
      agenix,
      doxx,
      xleak,
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
        nix-index-database.homeModules.default
      ];
      systemModules = [
        (./. + "/profiles" + ("/" + systemSettings.profile) + "/configuration.nix")
        stylix.nixosModules.stylix
        # agenix.nixosModules.default
        # ./security/security.nix
      ];
      args = {
        inherit userSettings;
        inherit systemSettings;
        inherit inputs;
      };
      projectOverlays = [
        helix-steel-system.overlays.default
        (final: prev: {
          helix-steel-system = final.helix.overrideAttrs (old: {
            cargoBuildFeatures = ((old.cargoBuildFeatures or [ ]) ++ [ "git" "steel" ]);
          });
        })
        (import ./overlays)
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/devshells.nix
      ];

      systems = supportedSystems;

      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true;
              allowUnfreePredicate = _: true;
            };
            overlays = projectOverlays;
          };
          hmSwitch = pkgs.writeShellApplication {
            name = "home-manager-switch";
            runtimeInputs = [ pkgs.home-manager ];
            text = ''
              backup_ext="''${HM_BACKUP_EXT:-hm-bak}"
              exec home-manager \
                -b "$backup_ext" \
                switch \
                --flake ${self}#${userSettings.username} \
                --no-update-lock-file \
                --no-write-lock-file \
                "$@"
            '';
          };
        in
        {
          packages = {
            default = hmSwitch;
            home-manager-switch = hmSwitch;
            bootstrap = hmSwitch;
          };

          apps = {
            default = {
              type = "app";
              program = "${hmSwitch}/bin/home-manager-switch";
            };
            home-manager-switch = {
              type = "app";
              program = "${hmSwitch}/bin/home-manager-switch";
            };
            bootstrap = {
              type = "app";
              program = "${hmSwitch}/bin/home-manager-switch";
            };
          };

        };

      flake =
        let
          pkgs = import nixpkgs {
            system = systemSettings.system;
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true;
              allowUnfreePredicate = _: true;
            };
            overlays = projectOverlays;
          };
        in
        {
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
