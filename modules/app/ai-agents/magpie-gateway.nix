{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.magpieGateway;
  # `magpie web` binds its browser UI on --addr and the OpenAI/Responses gateway
  # on the fixed gateway port. On a headless host the two must not share a port,
  # so the UI goes on uiPort and the keyless loopback gateway stays on gatewayPort
  # (what OMP/codex/jev-router talk to). --no-open avoids launching a browser.
  magpieBin = cfg.binary;
in {
  config = lib.mkIf cfg.enable {
    xdg.configFile."systemd/user/default.target.wants/magpie-gateway.service".force = true;

    systemd.user.services.magpie-gateway = {
      Unit = {
        Description = "magpie headless gateway (OpenAI/Responses on :${toString cfg.gatewayPort})";
        After = ["network.target"];
        ConditionPathExists = magpieBin;
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service =
        ai.serviceHardening
        // {
          Type = "simple";
          Environment = [
            "HOME=${ai.homeDir}"
            "PATH=${ai.profileBin}:/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin"
          ];
          ExecStart = "${magpieBin} web --addr 127.0.0.1:${toString cfg.uiPort} --no-open";
          Restart = "on-failure";
          RestartSec = 5;
        };
      Install.WantedBy = ["default.target"];
    };
  };
}
