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
  xsession.windowManager.xmonad.enable = true;
  xsession.windowManager.xmonad.enableContribAndExtras = true;
  xsession.initExtra = ''
    ibus-daemon -drx
  '';

  home.sessionVariables = {
    XMODIFIERS = "@im=ibus";
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    SDL_IM_MODULE = "ibus";
    INPUT_METHOD = "ibus";
  };

  home.packages = with pkgs; [
    xmobar
    ibus
  ];
}
