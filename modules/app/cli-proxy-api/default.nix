{config, ...}: let
  cliProxyApiDir = "${config.home.homeDirectory}/.cli-proxy-api";
  cliProxyApiConfig = "${cliProxyApiDir}/config.yaml";
in {
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
      ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/cli-proxy-api -config ${cliProxyApiConfig}";
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
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
