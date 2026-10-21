{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home.systemPanel;
in {
  options.my.features.home.systemPanel = {
    enable = lib.mkEnableOption "system-panel loopback web panel (user services)";
    service = lib.mkEnableOption "system-panel systemd user service started with default.target";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.system-panel];

    systemd.user.services.system-panel = lib.mkIf cfg.service {
      Unit.Description = "system-panel on 127.0.0.1 (user services)";
      Service = {
        ExecStart = lib.getExe pkgs.system-panel;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
