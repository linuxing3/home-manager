{ pkgs, ... }: {
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

    exec ${pkgs.oxwm}/bin/oxwm
  '';
}
