{...}: {
  # Sogou for UOS is supplied by the host and uses Fcitx 4. Keep the X11
  # clients launched by oxwm on the same input-method protocol.
  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "ibus";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
  };
}
