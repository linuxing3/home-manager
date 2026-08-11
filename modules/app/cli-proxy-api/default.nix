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
      UMask = "0077";
    };

    Install.WantedBy = ["default.target"];
  };
}
