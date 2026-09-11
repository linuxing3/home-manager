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
  # Linux computer-use runs `python3` + AT-SPI from the Orca daemon PATH.
  # A bare `python3` on the profile cannot import `gi` even if pygobject3 is
  # listed in home.packages, so give Orca a wrapped interpreter and typelibs.
  computerUsePython = pkgs.python3.withPackages (ps: [
    ps.pygobject3
    ps.pycairo
  ]);
  computerUseBinPath = lib.makeBinPath [
    computerUsePython
    pkgs.xdotool
    pkgs.xclip
  ];
  computerUseTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.at-spi2-core
    pkgs.gobject-introspection
    pkgs.glib.out
    pkgs.gtk3
    pkgs.gdk-pixbuf
    pkgs.pango.out
    pkgs.harfbuzz
    pkgs.cairo
  ];
  # `orca-ide` is the Electron GUI. Agents on Linux are told to call it instead
  # of `orca` (GNOME screen reader). Forward CLI verbs to the Node CLI so
  # `orca-ide computer` / `orca-ide skills get` do not spawn a second app.
  orcaIdeCli = pkgs.writeShellApplication {
    name = "orca-ide";
    text = ''
      case "''${1:-}" in
        --help|-h|-v|--version|version|open|serve|status|diagnostics|agent-context|account|skills|host|environment|vm|automations|project|repo|worktree|file|terminal|computer|browser|artifact|comment|orchestration|linear|emulator|doctor)
          exec ${lib.getExe' cfg.package "orca"} "$@"
          ;;
      esac
      exec ${lib.getExe' cfg.package "orca-ide"} "$@"
    '';
  };
  computerUsePythonBin = pkgs.writeShellApplication {
    name = "python3";
    text = ''
      export GI_TYPELIB_PATH=${lib.escapeShellArg computerUseTypelibPath}"''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      exec ${computerUsePython}/bin/python3 "$@"
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
        --pairing-address ${orcaPublicOrigin} --json
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package pkgs.nodejs pkgs.xdotool];
    # The Orca daemon looks up `python3` / `orca-ide` from PATH. Its PATH puts
    # ~/.bin first, so CLI verbs and AT-SPI land here instead of a second
    # Electron instance or a bare CPython without `gi`.
    home.file.".bin/python3".source = "${computerUsePythonBin}/bin/python3";
    home.file.".bin/orca-ide".source = "${orcaIdeCli}/bin/orca-ide";

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
            "GI_TYPELIB_PATH=${computerUseTypelibPath}"
            "PATH=${computerUseBinPath}:${lib.makeBinPath [pkgs.nodejs pkgs.gh]}:${ai.profileBin}:/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin"
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
            # UOS systemd 241 rejects these in user units (218/CAPABILITIES)
            # and never starts the connector, so the public hostname 404s.
            PrivateDevices = false;
            ProtectKernelModules = false;
          };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
