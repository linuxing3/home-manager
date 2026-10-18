{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ../lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.jevRouter;

  # jev-router forwards to magpie first and fails over to cursor-to-openai on
  # connection errors, timeouts, or 429/5xx. Secrets stay in the environment
  # (CURSOR_TOKEN); only env-var names live in this pure config.
  routerConfig = pkgs.writeText "jev-router-config.json" (builtins.toJSON {
    listen = "127.0.0.1:${toString cfg.port}";
    connect_timeout = cfg.connectTimeout;
    read_timeout = cfg.readTimeout;
    upstreams = [
      {
        name = "magpie";
        base_url = "http://127.0.0.1:${toString cfg.magpiePort}";
        auth = {type = "none";};
        retry_statuses = [429 500 502 503 504];
      }
      {
        name = "cursor";
        base_url = "http://127.0.0.1:${toString cfg.cursorPort}";
        auth = {
          type = "bearer";
          env = "CURSOR_TOKEN";
        };
        model_map = {default = cfg.cursorFallbackModel;};
        retry_statuses = [429 500 502 503 504];
      }
    ];
  });

  secretName = "api-keys-new.age";
  runner = pkgs.writeShellApplication {
    name = "jev-router-run";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.python3];
    text = ''
      keys_env="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agenix/${secretName}"
      if [[ -r "$keys_env" ]]; then
        CURSOR_TOKEN="$(${pkgs.gnugrep}/bin/grep -E '^CURSOR_TOKEN=' "$keys_env" \
          | ${pkgs.coreutils}/bin/head -n1 \
          | ${pkgs.coreutils}/bin/cut -d= -f2- || true)"
        export CURSOR_TOKEN
      else
        echo "jev-router: ${secretName} not materialized; cursor fallback will be unauthenticated" >&2
      fi
      export JEV_ROUTER_CONFIG=${routerConfig}
      exec ${pkgs.python3}/bin/python3 ${./gateway.py}
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    xdg.configFile."systemd/user/default.target.wants/jev-router.service".force = true;

    systemd.user.services.jev-router = {
      Unit = {
        Description = "jev-router OpenAI/Responses failover gateway (magpie -> cursor)";
        After = ["agenix.service" "magpie-gateway.service"];
        Wants = ["agenix.service"];
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
