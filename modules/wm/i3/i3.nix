{
  config,
  lib,
  inputs,
  pkgs,
  userSettings,
  systemSettings,
  ...
}:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.i3 = lib.mkEnableOption "Enable i3 module";

  config = lib.mkIf cfg.i3 {
    xsession.windowManager.i3.enable = true;
  };
}
