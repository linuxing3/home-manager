{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.webcodex;
  publicHost = "webcodex.efwmcstyle.ccwu.cc";
  publicOrigin = "https://${publicHost}";
  webcodexPort = 8080;
  tunnelName = "webcodex";
  tunnelId = "4dee35af-b655-4837-ba87-4da96d664282";
  credFile = "${ai.homeDir}/.cloudflared/${tunnelId}.json";
  configFile = "${ai.homeDir}/.cloudflared/webcodex.yml";
  envFile = "${ai.configHome}/webcodex/webcodex.env";
  dataDir = "${ai.homeDir}/.local/share/webcodex";
  tunnelDefaults = pkgs.writeText "webcodex-tunnel-defaults.json" (builtins.toJSON {
    tunnel = tunnelId;
    credentials-file = credFile;
    ingress = [
      {
        hostname = publicHost;
        service = "http://127.0.0.1:${toString webcodexPort}";
        originRequest = {
          connectTimeout = "30s";
          keepAliveTimeout = "90s";
          noHappyEyeballs = true;
        };
      }
      {service = "http_status:404";}
    ];
  });
  restoreTunnelCreds = pkgs.writeShellApplication {
    name = "webcodex-restore-tunnel-creds";
    runtimeInputs = [pkgs.cloudflared pkgs.coreutils];
    text = ''
      cred=${lib.escapeShellArg credFile}
      cert=${lib.escapeShellArg "${ai.homeDir}/.cloudflared/cert.pem"}
      mkdir -p "$(dirname "$cred")"
      if [[ -f "$cred" ]]; then
        exit 0
      fi
      if [[ ! -r "$cert" ]]; then
        echo "webcodex: missing $cert; cannot restore ${tunnelName} credentials" >&2
        exit 0
      fi
      cloudflared tunnel --origincert "$cert" token --cred-file "$cred" ${tunnelName}
      chmod 400 "$cred"
    '';
  };
  ensurePublicUrl = pkgs.writeShellApplication {
    name = "webcodex-ensure-public-url";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.gnused];
    text = ''
      env_file=${lib.escapeShellArg envFile}
      mkdir -p "$(dirname "$env_file")" "${lib.escapeShellArg dataDir}"
      if [[ ! -f "$env_file" ]]; then
        ${lib.getExe cfg.package} server init \
          --listen 127.0.0.1:${toString webcodexPort} \
          --data-dir ${lib.escapeShellArg dataDir} \
          --env-file "$env_file" \
          --public-url ${lib.escapeShellArg publicOrigin}
      fi
      if grep -q '^WEBCODEX_PUBLIC_URL=' "$env_file"; then
        sed -i 's|^WEBCODEX_PUBLIC_URL=.*|WEBCODEX_PUBLIC_URL=${publicOrigin}|' "$env_file"
      else
        printf '\nWEBCODEX_PUBLIC_URL=%s\n' ${lib.escapeShellArg publicOrigin} >>"$env_file"
      fi
      chmod 600 "$env_file"
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    home.sessionPath = ["$HOME/.local/bin"];

    xdg.configFile = {
      "systemd/user/default.target.wants/webcodex-server.service".force = true;
      "systemd/user/default.target.wants/cloudflared-webcodex.service".force = true;
      "systemd/user/default.target.wants/webcodex-openai-tunnel.service".force = true;
    };

    home.activation.mergeWebcodexTunnelConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${ai.activationPreamble}
      run ${restoreTunnelCreds}/bin/webcodex-restore-tunnel-creds
      run ${ensurePublicUrl}/bin/webcodex-ensure-public-url
      ${ai.ensureAndMergeYamlFile configFile tunnelDefaults ". * $defaults[0]"}
    '';

    systemd.user.services = {
      webcodex-server = {
        Unit = {
          Description = "WebCodex Server (loopback + CF public URL)";
          After = ["agenix.service" "network-online.target"];
          Wants = ["agenix.service" "network-online.target"];
        };
        Service =
          ai.serviceHardening
          // {
            Type = "simple";
            WorkingDirectory = dataDir;
            ExecStart = "${lib.getExe' cfg.package "webcodex"} server run --env-file ${envFile}";
            Restart = "on-failure";
            RestartSec = 3;
            PrivateDevices = false;
            ProtectKernelModules = false;
          };
        Install.WantedBy = ["default.target"];
      };

      cloudflared-webcodex = {
        Unit = {
          Description = "Cloudflare Tunnel for WebCodex (${publicHost})";
          After = [
            "network-online.target"
            "webcodex-server.service"
          ];
          Wants = [
            "network-online.target"
            "webcodex-server.service"
          ];
          ConditionPathExists = configFile;
        };
        Service =
          ai.serviceHardening
          // {
            Type = "simple";
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate --metrics 127.0.0.1:20243 tunnel --config ${configFile} run ${tunnelName}";
            Restart = "on-failure";
            RestartSec = 5;
            PrivateDevices = false;
            ProtectKernelModules = false;
          };
        Install.WantedBy = ["default.target"];
      };

      # ChatGPT Connection: Tunnel + No authentication.
      # Requires ~/.config/webcodex/openai-tunnel.env with CONTROL_PLANE_*.
      webcodex-openai-tunnel = {
        Unit = {
          Description = "WebCodex OpenAI Secure MCP Tunnel";
          After = [
            "network-online.target"
            "webcodex-server.service"
          ];
          Wants = [
            "network-online.target"
            "webcodex-server.service"
          ];
          ConditionPathExists = "${ai.configHome}/webcodex/openai-tunnel.env";
        };
        Service =
          ai.serviceHardening
          // {
            Type = "simple";
            EnvironmentFile = "${ai.configHome}/webcodex/openai-tunnel.env";
            # `server tunnel` requires --stop-on-stdin-eof; keep stdin open.
            StandardInput = "file:/dev/zero";
            ExecStart = "${lib.getExe' cfg.package "webcodex"} server tunnel --provider openai --env-file ${ai.configHome}/webcodex/openai-tunnel.env --json --stop-on-stdin-eof";
            Restart = "on-failure";
            RestartSec = 5;
            PrivateDevices = false;
            ProtectKernelModules = false;
          };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
