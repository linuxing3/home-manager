{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ibus
    ibus-engines.libpinyin
    ibus-engines.pinyin
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
    GLFW_IM_MODULE = "ibus";
    SDL_IM_MODULE = "ibus";
    INPUT_METHOD = "ibus";
    IBUS_COMPONENT_PATH = "${pkgs.ibus-engines.pinyin}/share/ibus/component:${pkgs.ibus-engines.libpinyin}/share/ibus/component";
  };

  systemd.user.services.ibus-daemon = {
    Unit = {
      Description = "IBus input method daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.ibus}/bin/ibus-daemon -rx";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

}
