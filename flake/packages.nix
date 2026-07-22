{
  inputs,
  userSettings,
  systemSettings,
  homeModules,
  ...
}: {
  perSystem = {pkgs, ...}: let
    deployPkgs = import inputs.nixpkgs {
      inherit (pkgs) system;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        allowUnfreePredicate = _: true;
      };
      overlays = [
        (import ../overlays)
      ];
    };
    cachixDeployLib = inputs.cachix-deploy-flake.lib deployPkgs;
    hmSwitch = pkgs.writeShellApplication {
      name = "home-manager-switch";
      runtimeInputs = [pkgs.home-manager];
      text = ''
        backup_ext="''${HM_BACKUP_EXT:-hm-bak}"
        exec home-manager \
          -b "$backup_ext" \
          switch \
          --flake ${inputs.self}#${userSettings.username} \
          --no-update-lock-file \
          --no-write-lock-file \
          "$@"
      '';
    };
    deploySpec = cachixDeployLib.spec {
      agents = {
        "${systemSettings.hostname}" =
          cachixDeployLib.homeManager {
            extraSpecialArgs = {
              inherit inputs userSettings systemSettings;
            };
          } (
            {...}: {
              imports = homeModules;
            }
          );
      };
    };
  in {
    packages = {
      default = hmSwitch;
      home-manager-switch = hmSwitch;
      bootstrap = hmSwitch;
      cachix-deploy = deploySpec;
      deploy = deploySpec;
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
}
