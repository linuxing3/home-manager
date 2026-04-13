{
  pkgs,
  ...
}:
{
  i18n.inputMethod.enable = true;
  i18n.inputMethod.type = "fcitx5";
  i18n.inputMethod.fcitx5 = {
    addons = with pkgs; [
      fcitx5-catppuccin
      fcitx5-rime
      fcitx5-chinese-addons
      fcitx5-rose-pine
      fcitx5-configtool
      fcitx5-gtk
    ];
    settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "pinyin";
      };
      "Groups/0/Items/0".Name = "keyboard-us";
      "Groups/0/Items/1".Name = "pinyin";
      "Groups/0/Items/2".Name = "rime";
    };
  };

}
