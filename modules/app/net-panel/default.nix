{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home.netPanel;
in {
  options.my.features.home.netPanel = {
    enable = lib.mkEnableOption "net-panel loopback web panel (Vivo share/hotspot, HK WireGuard, 1080/18080 proxies)";
    service = lib.mkEnableOption "net-panel systemd user service started with default.target";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.net-panel];

    systemd.user.services.net-panel = lib.mkIf cfg.service {
      Unit.Description = "net-panel on 127.0.0.1 (Vivo / HK WireGuard / proxies)";
      Service = {
        ExecStart = lib.getExe pkgs.net-panel;
        Restart = "on-failure";
        RestartSec = 5;
        # isvoro-wg-up/down and gnirehtet-share live in the HM profile.
        Environment = ["PATH=${config.home.profileDirectory}/bin"];
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
