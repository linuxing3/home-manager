{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ../lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.jevRouter;

  # jev-router is a loopback in front of magpie. HTTP statuses, including
  # quota 429 and 5xx, are returned to OMP. There is no second upstream.
  routerConfig = pkgs.writeText "jev-router-config.json" (builtins.toJSON {
    listen = "127.0.0.1:${toString cfg.port}";
    connect_timeout = cfg.connectTimeout;
    read_timeout = cfg.readTimeout;
    upstreams = [
      {
        name = "magpie";
        base_url = "http://127.0.0.1:${toString cfg.magpiePort}";
        auth = {type = "none";};
        retry_statuses = [];
      }
    ];
  });

  runner = pkgs.writeShellApplication {
    name = "jev-router-run";
    runtimeInputs = [pkgs.python3];
    text = ''
      export JEV_ROUTER_CONFIG=${routerConfig}
      exec ${pkgs.python3}/bin/python3 ${./gateway.py}
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    xdg.configFile."systemd/user/default.target.wants/jev-router.service".force = true;

    systemd.user.services.jev-router = {
      Unit = {
        Description = "jev-router OpenAI/Responses gateway (magpie)";
        After = ["magpie-gateway.service"];
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service =
        ai.serviceHardening
        // {
          Type = "simple";
          ExecStart = "${runner}/bin/jev-router-run";
          Restart = "on-failure";
          RestartSec = 5;
        };
      Install.WantedBy = ["default.target"];
    };
  };
}
