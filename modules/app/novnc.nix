{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configDir = "${config.xdg.configHome}/novnc";
  passwordFile = "${configDir}/vnc.pass";
in {
  home.packages = [pkgs.novnc pkgs.x11vnc];

  systemd.user.services = {
    x11vnc = {
      Unit = {
        Description = "Loopback-only VNC server for the local X11 session";
        After = ["graphical-session.target"];
        Wants = ["graphical-session.target"];
        ConditionPathExists = passwordFile;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth ${homeDir}/.Xauthority -rfbauth ${passwordFile} -localhost -rfbport 5900 -forever -shared -noxrecord -noxfixes -noxdamage";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };

    novnc = {
      Unit = {
        Description = "Loopback-only noVNC web gateway";
        After = ["x11vnc.service"];
        Requires = ["x11vnc.service"];
        ConditionPathExists = passwordFile;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.novnc}/bin/novnc_proxy --listen 127.0.0.1:6080 --vnc 127.0.0.1:5900";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
