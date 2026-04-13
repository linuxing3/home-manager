{
  config,
  pkgs,
  ...
}:
let
  fcitx5Package = config.i18n.inputMethod.package;
in
{

  imports = [
    ../input/nihongo.nix
  ];
  home.packages = with pkgs; [
    oxwm
    dmenu
    feh
  ];

  home.file.".xinitrc".text = ''
    if [ -r "$HOME/.Xresources" ]; then
      ${pkgs.xorg.xrdb}/bin/xrdb "$HOME/.Xresources" &
    fi

    if [ -r "$HOME/.Xmodmap" ]; then
      ${pkgs.xorg.xmodmap}/bin/xmodmap "$HOME/.Xmodmap" &
    fi

    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XMODIFIERS GTK_IM_MODULE QT_IM_MODULE SDL_IM_MODULE INPUT_METHOD QT_PLUGIN_PATH GLFW_IM_MODULE || true
    ${fcitx5Package}/bin/fcitx5 -d --replace
    ${fcitx5Package}/bin/fcitx5-remote -r

    exec ${pkgs.oxwm}/bin/oxwm
  '';
}
