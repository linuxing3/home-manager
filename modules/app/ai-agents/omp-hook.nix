{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  # Notion PM Tasks automation -> omp-hook-relay Worker (sites/omp-hook-relay)
  # -> cloudflared tunnel -> this listener -> `herdr agent prompt` to the OMP pane.
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

  environment = [
    "OMP_HOOK_PORT=${toString port}"
    "OMP_HOOK_KEY_FILE=${keyFile}"
    "HERDR_BIN=${config.my.ai.herdr.package}/bin/herdr"
    "HERDR_SOCKET_PATH=${ai.configHome}/herdr/herdr.sock"
  ];

  ompHook = pkgs.writeShellApplication {
    name = "omp-hook";
    text = ''exec ${pkgs.python3}/bin/python3 ${./omp-hook.py} "$@"'';
  };

  ompHookScan = pkgs.writeShellApplication {
    name = "omp-hook-scan";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep];
    text = ''
      keys_env="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agenix/${secretName}"
      if [[ -r "$keys_env" ]]; then
        NOTION_API_KEY="$(grep -E '^NOTION_API_KEY=' "$keys_env" | head -n1 | cut -d= -f2- || true)"
        export NOTION_API_KEY
      fi
      exec ${lib.getExe ompHook} scan
    '';
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
  config = lib.mkIf (config.my.ai.omp.enable && config.my.ai.herdr.enable) {
    home.packages = [ompHook];

    xdg.configFile = {
      "systemd/user/default.target.wants/omp-hook.service".force = true;
      "systemd/user/default.target.wants/cloudflared-omp-hook.service".force = true;
      "systemd/user/timers.target.wants/omp-hook-scan.timer".force = true;
    };

    systemd.user.services = {
      omp-hook = {
        Unit = {
          Description = "OMP hook listener (Notion PM Tasks -> Herdr OMP pane)";
          ConditionPathExists = keyFile;
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
            ExecStart = lib.getExe ompHookScan;
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
      Unit.Description = "Scan PM Tasks for unclaimed [本机·OMP] tickets every 10 minutes";
      Timer = {
        OnBootSec = "3min";
        OnUnitActiveSec = "10min";
        Persistent = false;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
