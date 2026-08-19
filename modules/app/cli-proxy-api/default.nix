{
  config,
  lib,
  ...
}: let
  cfg = config.my.ai.cliProxyApi;
  cliProxyApiDir = "${config.home.homeDirectory}/.cli-proxy-api";
  cliProxyApiConfig = "${cliProxyApiDir}/config.yaml";
in {
  config = lib.mkIf cfg.enable {
    systemd.user.services.cli-proxy-api = {
      Unit = {
        Description = "CLIProxyAPI server";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
        ConditionPathExists = cliProxyApiConfig;
      };

      Service = {
        Type = "simple";
        WorkingDirectory = cliProxyApiDir;
        ExecStart = "${lib.getExe cfg.package} -config ${cliProxyApiConfig}";
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
  };
}
