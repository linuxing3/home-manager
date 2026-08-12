{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  profileBin = "${homeDir}/.nix-profile/bin";
  herdrConfig = "${config.xdg.configHome}/herdr";

  collieLauncher = pkgs.writeShellApplication {
    name = "collie-launch";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      shopt -s nullglob
      candidates=(${lib.escapeShellArg "${herdrConfig}/plugins/github"}/herdr.collie-*/bridge/index.ts)
      if (( ''${#candidates[@]} != 1 )); then
        echo "collie-launch: expected exactly one installed herdr.collie bridge" >&2
        exit 1
      fi
      bridge=''${candidates[0]}
      cd -- "$(dirname -- "$(dirname -- "$bridge")")"
      exec ${lib.escapeShellArg "${profileBin}/bun"} run "$bridge"
    '';
  };
in {
  xdg.configFile = {
    "systemd/user/default.target.wants/cloudflared-cursor-openai.service".force = true;
    "systemd/user/default.target.wants/collie.service".force = true;
    "systemd/user/default.target.wants/cursor-to-openai.service".force = true;
    "systemd/user/default.target.wants/hermes-dashboard.service".force = true;
    "systemd/user/default.target.wants/hermes-gateway.service".force = true;
  };

  systemd.user.services = {
    cloudflared-cursor-openai = {
      Unit = {
        Description = "Cloudflare Tunnel for Cursor-to-OpenAI";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
        ConditionPathExists = "${homeDir}/.cloudflared/cursor-openai.yml";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel --config ${homeDir}/.cloudflared/cursor-openai.yml run cursor-openai";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
      Install.WantedBy = ["default.target"];
    };

    collie = {
      Unit = {
        Description = "Collie Herdr bridge";
        After = ["default.target"];
        StartLimitIntervalSec = 0;
        ConditionPathExists = "${herdrConfig}/plugins/github";
      };
      Service = {
        Type = "simple";
        ExecStart = "${collieLauncher}/bin/collie-launch";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
        UMask = "0077";
        Environment = [
          "HERDR_SOCKET_PATH=${herdrConfig}/herdr.sock"
          "COLLIE_PORT=8787"
          "HERDR_PLUGIN_CONFIG_DIR=${herdrConfig}/plugins/config/herdr.collie"
        ];
        EnvironmentFile = "-${herdrConfig}/plugins/config/herdr.collie/.env";
      };
      Install.WantedBy = ["default.target"];
    };

    cursor-to-openai = {
      Unit = {
        Description = "Cursor To OpenAI on loopback port 3010";
        After = ["network.target"];
        ConditionPathExists = "/share/data/sources/cursor-to-openai/package.json";
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "/share/data/sources/cursor-to-openai";
        EnvironmentFile = "${config.xdg.configHome}/cursor-to-openai.env";
        Environment = [
          "PORT=3010"
          "PATH=${profileBin}:/usr/bin:/bin"
        ];
        ExecStart = "${profileBin}/npm run start";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
      Install.WantedBy = ["default.target"];
    };

    hermes-dashboard = {
      Unit = {
        Description = "Hermes Agent dashboard on loopback";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
        ConditionPathExists = "${profileBin}/hermes";
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "${homeDir}/.hermes";
        Environment = "PATH=${profileBin}:/usr/local/bin:/usr/bin:/bin";
        ExecStart = "${profileBin}/hermes dashboard --host 127.0.0.1 --port 9119 --no-open --skip-build";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
      Install.WantedBy = ["default.target"];
    };

    hermes-gateway = {
      Unit = {
        Description = "Hermes Agent Gateway";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
        StartLimitIntervalSec = 0;
        ConditionPathExists = "${profileBin}/hermes";
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "${homeDir}/.hermes";
        Environment = [
          "PATH=${profileBin}:${homeDir}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          "HERMES_HOME=${homeDir}/.hermes"
        ];
        EnvironmentFile = "-${homeDir}/.hermes/.env";
        UnsetEnvironment = [
          "http_proxy"
          "https_proxy"
          "all_proxy"
          "auto_proxy"
          "ftp_proxy"
          "no_proxy"
          "HTTP_PROXY"
          "HTTPS_PROXY"
          "ALL_PROXY"
          "FTP_PROXY"
          "NO_PROXY"
          "SOCKS_SERVER"
          "SOCKS5_SERVER"
        ];
        ExecStart = "${profileBin}/hermes gateway run";
        Restart = "always";
        RestartSec = 5;
        RestartForceExitStatus = 75;
        RestartPreventExitStatus = 78;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
        TimeoutStopSec = 60;
        StandardOutput = "journal";
        StandardError = "journal";
        UMask = "0077";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
