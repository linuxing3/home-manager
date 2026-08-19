{
  config,
  lib,
  pkgs,
  ...
}: let
  tokenEnv = config.age.secrets."cloudflared-office-token.age".path;
in {
  xdg.configFile."systemd/user/default.target.wants/cloudflared-office.service".force = true;

  systemd.user.services.cloudflared-office = {
    Unit = {
      Description = "Cloudflare Tunnel (office token)";
      After = [
        "network-online.target"
        "agenix.service"
      ];
      Wants = [
        "network-online.target"
        "agenix.service"
      ];
      ConditionPathExists = tokenEnv;
    };
    Service = {
      Type = "simple";
      EnvironmentFile = tokenEnv;
      ExecStart = "${lib.getExe pkgs.cloudflared} --no-autoupdate tunnel run --token \${CLOUDFLARED_TUNNEL_TOKEN}";
      Restart = "on-failure";
      RestartSec = 5;
      # UOS systemd 241 rejects PrivateDevices and ProtectKernelModules in user units.
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectControlGroups = true;
      ProtectKernelTunables = true;
      ProtectSystem = "full";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictSUIDSGID = true;
      UMask = "0077";
    };
    Install.WantedBy = ["default.target"];
  };
}
