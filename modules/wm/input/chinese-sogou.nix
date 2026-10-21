{
  lib,
  pkgs,
  ...
}: {
  # Sogou Pinyin is not a nixpkgs package. Use fcitx5 + Rime.
  # oxwm autostart already runs `fcitx5 -d --replace`. The HM user unit
  # claims the same D-Bus name and exits. Keep the package and IM variables,
  # but do not start fcitx5-daemon with graphical-session.target.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  systemd.user.services.fcitx5-daemon.Install.WantedBy = lib.mkForce [];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    QT4_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "ibus";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
  };

  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=rime

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  # 朙月拼音没有默认模糊音。正在用的方案是 luna_pinyin_simp。
  xdg.dataFile."fcitx5/rime/luna_pinyin_simp.custom.yaml" = {
    force = true;
    text = ''
      # Home Manager: zh/z ch/c sh/s, n/l, an/ang en/eng in/ing.
      patch:
        speller/algebra:
          - abbrev/^([a-z]).+$/$1/
          - abbrev/^([zcs]h).+$/$1/
          - derive/^([nl])ve$/$1ue/
          - derive/^([jqxy])u/$1v/
          - derive/un$/uen/
          - derive/ui$/uei/
          - derive/iu$/iou/
          - derive/([aeiou])ng$/$1gn/
          - derive/([dtngkhrzcs])o(u|ng)$/$1o/
          - derive/ong$/on/
          - derive/ao$/oa/
          - derive/([iu])a(o|ng?)$/a$1$2/
          - derive/^([zcs])h/$1/
          - derive/^([zcs])([^h])/$1h$2/
          - derive/^n/l/
          - derive/^l/n/
          - derive/ang$/an/
          - derive/an$/ang/
          - derive/eng$/en/
          - derive/en$/eng/
          - derive/ing$/in/
          - derive/in$/ing/
    '';
  };
}
