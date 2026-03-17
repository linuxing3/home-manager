{
  inputs,
  config,
  lib,
  pkgs,
  userSettings,
  systemSettings,
  ...
}:
{
  xsession.windowManager.i3.enable = true;
}
