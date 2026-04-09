{
  config,
  lib,
  pkgs,
  userSettings,
  ...
}: let
  stylixCommon = import ../style/stylix-common.nix {
    inherit config lib pkgs userSettings;
  };
in
  stylixCommon {
    fontSizes = {
      terminal = 16;
      applications = 14;
      popups = 14;
      desktop = 14;
    };
  }
