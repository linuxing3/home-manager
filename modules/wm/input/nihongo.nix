{
  pkgs,
  ...
}:
{
  i18n.inputMethod.enable = true;
  i18n.inputMethod.type = "fcitx5";
  i18n.inputMethod.fcitx5 = {
    addons = with pkgs; [
      qt6Packages.fcitx5-configtool
      qt6Packages.fcitx5-chinese-addons
      fcitx5-rime
      fcitx5-rose-pine
      fcitx5-gtk
      catppuccin-fcitx5
    ];
  };

}
