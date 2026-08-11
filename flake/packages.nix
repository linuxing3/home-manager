{
  inputs,
  userSettings,
  ...
}: {
  perSystem = {pkgs, ...}: let
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
  in {
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
}
