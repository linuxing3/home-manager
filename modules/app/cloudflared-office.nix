{
  config,
  lib,
  pkgs,
  ...
}: let
  secretName = "api-keys-new.age";
  # agenix.path is "${XDG_RUNTIME_DIR}/agenix/<name>". systemd 241 does
  # not expand that in ConditionPathExists; writeShellApplication nounset
  # also rejects splicing that string. Use %t and a quoted shell variable.
  runtimeSecret = "%t/agenix/${secretName}";
  start = pkgs.writeShellApplication {
    name = "cloudflared-office";
    runtimeInputs = [pkgs.cloudflared pkgs.coreutils];
    text = ''
      keys_env="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agenix/${secretName}"
      if [[ ! -r "$keys_env" ]]; then
        echo "cloudflared-office: ${secretName} is not materialized" >&2
        exit 1
      fi
      set -a
      # shellcheck disable=SC1090
      . "$keys_env"
      set +a
      if [[ -z "''${CLOUDFLARED_TUNNEL_TOKEN:-}" ]]; then
        echo "cloudflared-office: CLOUDFLARED_TUNNEL_TOKEN is missing from ${secretName}" >&2
        exit 1
      fi
      # systemd 241 does not expand ''${VAR} in ExecStart. Source the shared
      # Agenix env, then pass only the tunnel token into cloudflared.
      exec ${pkgs.coreutils}/bin/env -i \
        PATH="$PATH" \
        HOME="''${HOME:-}" \
        XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-}" \
        CLOUDFLARED_TUNNEL_TOKEN="$CLOUDFLARED_TUNNEL_TOKEN" \
        ${lib.getExe pkgs.cloudflared} --no-autoupdate tunnel run --token "$CLOUDFLARED_TUNNEL_TOKEN"
    '';
  };
in {
  xdg.configFile."systemd/user/default.target.wants/cloudflared-office.service".force = true;

  systemd.user.services.cloudflared-office = {
    Unit = {
      Description = "Cloudflare Tunnel (office via api-keys-new)";
      After = [
        "network-online.target"
        "agenix.service"
      ];
      Wants = [
        "network-online.target"
        "agenix.service"
      ];
      ConditionPathExists = runtimeSecret;
    };
    Service = {
      Type = "simple";
      ExecStart = lib.getExe start;
      Restart = "on-failure";
      RestartSec = 5;
      # UOS systemd 241 rejects PrivateDevices and ProtectKernelModules in user units.
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectControlGroups = true;
      ProtectKernelTunables = true;
      ProtectSystem = "full";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictSUIDSGID = true;
      UMask = "0077";
    };
    Install.WantedBy = ["default.target"];
  };
}
