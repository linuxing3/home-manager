{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.orca;
  orcaPublicHost = "orca.efwmcstyle.ccwu.cc";
  orcaPublicOrigin = "https://${orcaPublicHost}";
  orcaPort = 6768;
  tunnelName = "orca-remote";
  tunnelId = "db92ee1a-b602-434a-9e62-f634a172b223";
  credFile = "${ai.homeDir}/.cloudflared/${tunnelId}.json";
  configFile = "${ai.homeDir}/.cloudflared/orca-remote.yml";
  orcaTunnelDefaults = pkgs.writeText "orca-tunnel-defaults.json" (builtins.toJSON {
    tunnel = tunnelId;
    credentials-file = credFile;
    ingress = [
      {
        hostname = orcaPublicHost;
        service = "http://127.0.0.1:${toString orcaPort}";
        originRequest = {
          connectTimeout = "30s";
          keepAliveTimeout = "90s";
          disableChunkedEncoding = true;
        };
      }
      {service = "http_status:404";}
    ];
  });
  restoreOrcaTunnelCreds = pkgs.writeShellApplication {
    name = "orca-restore-tunnel-creds";
    runtimeInputs = [pkgs.cloudflared pkgs.coreutils];
    text = ''
      cred=${lib.escapeShellArg credFile}
      cert=${lib.escapeShellArg "${ai.homeDir}/.cloudflared/cert.pem"}
      mkdir -p "$(dirname "$cred")"
      if [[ -f "$cred" ]]; then
        exit 0
      fi
      if [[ ! -r "$cert" ]]; then
        echo "orca: missing $cert; cannot restore ${tunnelName} credentials" >&2
        exit 0
      fi
      cloudflared tunnel --origincert "$cert" token --cred-file "$cred" ${tunnelName}
      chmod 400 "$cred"
    '';
  };
  # Interactive shells authenticate `gh` via GH_TOKEN from api-keys-new.age
  # (agenix-env / agent-env). systemd user units do not inherit that, and
  # there is no hosts.yml, so Orca's GitHub check reports unauthenticated.
  secretName = "api-keys-new.age";
  orcaServe = pkgs.writeShellApplication {
    name = "orca-serve";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep];
    text = ''
      keys_env="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agenix/${secretName}"
      extract_key() {
        local key="$1"
        if [[ ! -r "$keys_env" ]]; then
          return 0
        fi
        ${pkgs.gnugrep}/bin/grep -E "^''${key}=" "$keys_env" \
          | ${pkgs.coreutils}/bin/head -n1 \
          | ${pkgs.coreutils}/bin/cut -d= -f2- \
          || true
      }
      GH_TOKEN="$(extract_key GH_TOKEN)"
      GITHUB_TOKEN="$(extract_key GITHUB_TOKEN)"
      GITHUB_PERSONAL_ACCESS_TOKEN="$(extract_key GITHUB_PERSONAL_ACCESS_TOKEN)"
      if [[ ! -r "$keys_env" ]]; then
        echo "orca: ${secretName} is not materialized; GitHub CLI will stay unauthenticated" >&2
      elif [[ -z "''${GH_TOKEN}''${GITHUB_TOKEN}" ]]; then
        echo "orca: GH_TOKEN/GITHUB_TOKEN missing from ${secretName}" >&2
      fi
      extra_env=()
      if [[ -n "''${GH_TOKEN}" ]]; then
        extra_env+=(GH_TOKEN="''${GH_TOKEN}")
      fi
      if [[ -n "''${GITHUB_TOKEN}" ]]; then
        extra_env+=(GITHUB_TOKEN="''${GITHUB_TOKEN}")
      fi
      if [[ -n "''${GITHUB_PERSONAL_ACCESS_TOKEN}" ]]; then
        extra_env+=(GITHUB_PERSONAL_ACCESS_TOKEN="''${GITHUB_PERSONAL_ACCESS_TOKEN}")
      fi
      exec ${pkgs.coreutils}/bin/env "''${extra_env[@]}" \
        ${cfg.package}/bin/orca serve --port ${toString orcaPort} \
        --pairing-address ${orcaPublicOrigin}/runtime --json
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package pkgs.nodejs];

    xdg.configFile = {
      "systemd/user/default.target.wants/orca.service".force = true;
      "systemd/user/default.target.wants/cloudflared-orca.service".force = true;
    };

    home.activation.mergeOrcaTunnelConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${ai.activationPreamble}
      run ${restoreOrcaTunnelCreds}/bin/orca-restore-tunnel-creds
      ${ai.ensureAndMergeYamlFile configFile orcaTunnelDefaults ". * $defaults[0]"}
    '';

    systemd.user.services = {
      orca = {
        Unit = {
          Description = "Orca runtime server";
          # Do not After=default.target: cloudflared-orca After=orca plus
          # both WantedBy=default.target makes an ordering cycle, and
          # systemd drops the tunnel unit at login.
          After = ["agenix.service"];
          Wants = ["agenix.service"];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 5;
        };
        Service = {
          Type = "simple";
          WorkingDirectory = ai.homeDir;
          Environment = [
            "LIBGL_ALWAYS_SOFTWARE=1"
            "NPM_CONFIG_CACHE=${ai.homeDir}/.cache/npm-orca"
            "PATH=${lib.makeBinPath [pkgs.nodejs pkgs.gh]}:${ai.profileBin}:/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin"
          ];
          ExecStart = lib.getExe orcaServe;
          KillMode = "mixed";
          Restart = "on-failure";
          RestartPreventExitStatus = 3;
          RestartSec = 5;
          # Electron needs user namespaces and /dev; collie-style hardening
          # (NoNewPrivileges, PrivateDevices) prevents Chromium from starting.
          NoNewPrivileges = false;
          PrivateDevices = false;
          PrivateTmp = true;
          ProtectControlGroups = true;
          ProtectKernelModules = false;
          ProtectKernelTunables = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
            "AF_NETLINK"
          ];
          RestrictSUIDSGID = true;
          UMask = "0077";
        };
        Install.WantedBy = ["default.target"];
      };

      cloudflared-orca = {
        Unit = {
          Description = "Cloudflare Tunnel for Orca (${orcaPublicHost})";
          After = [
            "network-online.target"
            "orca.service"
          ];
          Wants = [
            "network-online.target"
            "orca.service"
          ];
          ConditionPathExists = configFile;
        };
        Service =
          ai.serviceHardening
          // {
            Type = "simple";
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate --metrics 127.0.0.1:20242 tunnel --config ${configFile} run ${tunnelName}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
