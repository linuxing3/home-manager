{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  herdrConfig = "${ai.configHome}/herdr";
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
      exec ${lib.getExe pkgs.bun} run "$bridge"
    '';
  };
  # Office Cloudflare Tunnel hostname (Zero Trust Access in front).
  colliePublicHost = "collie.efwmcstyle.ccwu.cc";
  colliePublicOrigin = "https://${colliePublicHost}";
  stopUnmanagedCollie = pkgs.writeShellApplication {
    name = "collie-stop-unmanaged";
    runtimeInputs = with pkgs; [coreutils procps];
    text = ''
      port_busy() {
        # User units RestrictAddressFamilies to inet/unix, so `ss` (netlink) fails
        # on UOS systemd 241 and would treat a live listener as free.
        ${pkgs.bash}/bin/bash -c 'exec 3<>/dev/tcp/127.0.0.1/8787' 2>/dev/null
      }
      ${pkgs.procps}/bin/pkill -f '/lib/collie/bridge/index.ts' || true
      ${pkgs.procps}/bin/pkill -f 'herdr.collie-[^/]*/bridge/index.ts' || true
      for _ in $(seq 1 20); do
        if ! port_busy; then
          exit 0
        fi
        sleep 0.25
      done
      echo "collie: port 8787 is still in use by an unmanaged process" >&2
      exit 1
    '';
  };
in {
  config = lib.mkIf config.my.ai.collie.enable {
    home.packages = [config.my.ai.collie.package];

    xdg.configFile."systemd/user/default.target.wants/collie.service".force = true;

    systemd.user.services.collie = {
      Unit = {
        Description = "Collie Herdr bridge";
        After = ["default.target"];
        StartLimitIntervalSec = 0;
        ConditionPathExists = "${herdrConfig}/plugins/github";
      };
      Service =
        ai.serviceHardening
        // {
          Type = "simple";
          ExecStartPre = "${stopUnmanagedCollie}/bin/collie-stop-unmanaged";
          ExecStart = "${collieLauncher}/bin/collie-launch";
          Restart = "on-failure";
          RestartSec = 5;
          # UOS systemd 241 cannot apply these in the user manager and exits
          # with 218/CAPABILITIES before starting the bridge.
          PrivateDevices = false;
          ProtectKernelModules = false;
          Environment = [
            "HERDR_SOCKET_PATH=${herdrConfig}/herdr.sock"
            "COLLIE_PORT=8787"
            "HERDR_PLUGIN_CONFIG_DIR=${herdrConfig}/plugins/config/herdr.collie"
            # Variant E: office cloudflared token tunnel is the front door, not tailscale serve.
            "COLLIE_SKIP_SERVE=1"
            "COLLIE_PUBLIC_HOSTS=${colliePublicHost}"
            "COLLIE_ALLOWED_ORIGINS=${colliePublicOrigin}"
            "COLLIE_PUBLIC_URL=${colliePublicOrigin}"
          ];
          EnvironmentFile = "-${herdrConfig}/plugins/config/herdr.collie/.env";
        };
      Install.WantedBy = ["default.target"];
    };
  };
}
