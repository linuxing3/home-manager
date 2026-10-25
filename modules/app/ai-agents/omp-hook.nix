{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  # Notion PM Tasks automation -> omp-hook-relay Worker (sites/omp-hook-relay)
  # -> cloudflared tunnel -> this listener -> claims the row in Notion (v0.3.5 lock)
  # -> `orca agent launch --agent omp` in ~/agent-data/omp-jobs (or Herdr pane).
  port = 8791;
  publicHost = "omp-hook.efwmcapp.com";
  tunnelId = "68c903cf-748b-41b0-a5c2-b3bd0af10afa";
  keyFile = "${ai.configHome}/omp-hook/secret";
  credFile = "${ai.homeDir}/.cloudflared/${tunnelId}.json";
  secretName = "api-keys-new.age";

  tunnelConfig = pkgs.writeText "omp-hook-tunnel.yml" (builtins.toJSON {
    tunnel = tunnelId;
    credentials-file = credFile;
    ingress = [
      {
        hostname = publicHost;
        service = "http://127.0.0.1:${toString port}";
        originRequest.connectTimeout = "10s";
      }
      {service = "http_status:404";}
    ];
  });

  # Backend: "orca" (default, needs the Orca desktop runtime) or "herdr".
  backend = "orca";
  jobsDir = "${ai.homeDir}/agent-data/omp-jobs";

  # Secrets: OMP_HOOK_KEY and NOTION_API_KEY are read from the agenix env file
  # ${secretName}; the legacy files under ~/.config/omp-hook are only a fallback.
  environment =
    [
      "OMP_HOOK_PORT=${toString port}"
      "OMP_HOOK_BACKEND=${backend}"
      "OMP_HOOK_KEY_FILE=${keyFile}"
      "OMP_HOOK_NOTION_FILE=${ai.configHome}/omp-hook/notion-secret"
      "OMP_HOOK_AGENIX_FILE=%t/agenix/${secretName}"
      "OMP_HOOK_JOBS_DIR=${jobsDir}"
      "OMP_HOOK_LOG=${ai.homeDir}/agent-data/logs/omp-hook.log"
      "OMP_HOOK_BOOTSTRAP=${./files/notion-bootstrap.md}"
      "ORCA_BIN=${lib.getExe' config.my.ai.orca.package "orca"}"
    ]
    ++ lib.optionals config.my.ai.herdr.enable [
      "HERDR_BIN=${config.my.ai.herdr.package}/bin/herdr"
      "HERDR_SOCKET_PATH=${ai.configHome}/herdr/herdr.sock"
    ];

  ompHook = pkgs.writeShellApplication {
    name = "omp-hook";
    text = ''exec ${pkgs.python3}/bin/python3 ${./omp-hook.py} "$@"'';
  };


  hardening =
    ai.serviceHardening
    // {
      # UOS systemd 241 rejects these in user units (218/CAPABILITIES).
      PrivateDevices = false;
      ProtectKernelModules = false;
      UMask = "0077";
    };
in {
  config = lib.mkIf (config.my.ai.omp.enable && (config.my.ai.orca.enable || config.my.ai.herdr.enable)) {
    home.packages = [ompHook];

    xdg.configFile = {
      "systemd/user/default.target.wants/omp-hook.service".force = true;
      "systemd/user/default.target.wants/cloudflared-omp-hook.service".force = true;
      "systemd/user/timers.target.wants/omp-hook-scan.timer".force = true;
    };

    systemd.user.services = {
      omp-hook = {
        Unit = {
          Description = "OMP hook listener (Notion PM Tasks -> OMP via ${backend})";
          # Starts once either the agenix key or the legacy key file exists.
          After = ["agenix.service"];
          Wants = ["agenix.service"];
        };
        Service =
          hardening
          // {
            Type = "simple";
            ExecStart = "${lib.getExe ompHook} serve";
            Environment = environment;
            Restart = "on-failure";
            RestartSec = 5;
          };
        Install.WantedBy = ["default.target"];
      };

      omp-hook-scan = {
        Unit = {
          Description = "OMP hook fallback scan of PM Tasks";
          After = ["agenix.service"];
          Wants = ["agenix.service"];
        };
        Service =
          hardening
          // {
            Type = "oneshot";
            ExecStart = "${lib.getExe ompHook} scan";
            Environment = environment;
          };
      };

      cloudflared-omp-hook = {
        Unit = {
          Description = "Cloudflare Tunnel for OMP hook (${publicHost})";
          After = [
            "network-online.target"
            "omp-hook.service"
          ];
          Wants = [
            "network-online.target"
            "omp-hook.service"
          ];
          ConditionPathExists = credFile;
        };
        Service =
          hardening
          // {
            Type = "simple";
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel --config ${tunnelConfig} run ${tunnelId}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        Install.WantedBy = ["default.target"];
      };
    };

    systemd.user.timers.omp-hook-scan = {
      Unit.Description = "Scan PM Tasks for claimable [本机·OMP] tickets every 10 minutes";
      Timer = {
        OnBootSec = "3min";
        OnUnitActiveSec = "10min";
        Persistent = false;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
