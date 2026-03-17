{ pkgs, ... }:

{
  i18n.inputMethod.enable = true;
  i18n.inputMethod.type = "fcitx5";
  i18n.inputMethod.fcitx5.settings.inputMethod = {
    GroupOrder."0" = "Default";
    "Groups/0" = {
        Name = "Default";
       "Default Layout" = "us";
        DefaultIM = "rime";
    };
    "Groups/0/Items/0".Name = "keyboard-us";
    "Groups/0/Items/1".Name = "rime";
  };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
  };

  i18n.inputMethod.fcitx5.waylandFrontend = false;

  i18n.inputMethod.fcitx5.addons = with pkgs; [
    rime-data
    librime
    fcitx5-rime
    fcitx5-chinese-addons
    fcitx5-nord
    fcitx5-material-color
  ];
}
