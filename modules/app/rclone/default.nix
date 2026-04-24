{
  config,
  pkgs,
  lib,
  ...
}: let
  remoteName = "onedrive";
  syncDir = "/share/data/workspace/onedrive";
  rcloneConfigDir = "${config.xdg.configHome}/rclone";
  rcloneConfigPath = "${rcloneConfigDir}/rclone.conf";

  onedriveConnect = pkgs.writeShellScriptBin "onedrive-connect" ''
        set -euo pipefail

        mkdir -p '${syncDir}' '${rcloneConfigDir}'

        if [ ! -f '${rcloneConfigPath}' ] || ! grep -q '^\[${remoteName}\]$' '${rcloneConfigPath}'; then
          cat >'${rcloneConfigPath}' <<'EOF'
    [${remoteName}]
    type = onedrive
    EOF
          chmod 600 '${rcloneConfigPath}'
        fi

        exec rclone config reconnect ${remoteName}:
  '';

  onedriveSync = pkgs.writeShellScriptBin "onedrive-sync" ''
    set -euo pipefail
    mkdir -p '${syncDir}'
    exec rclone sync ${remoteName}: '${syncDir}' \
      --create-empty-src-dirs \
      --fast-list \
      --exclude '/个人保管库/**' \
      --exclude '/Personal Vault/**' \
      "$@"
  '';

  onedriveCopy = pkgs.writeShellScriptBin "onedrive-copy" ''
    set -euo pipefail
    mkdir -p '${syncDir}'
    exec rclone copy ${remoteName}: '${syncDir}' \
      --create-empty-src-dirs \
      --fast-list \
      --exclude '/个人保管库/**' \
      --exclude '/Personal Vault/**' \
      "$@"
  '';
in {
  home.packages = [
    pkgs.rclone
    onedriveConnect
    onedriveSync
    onedriveCopy
  ];

  home.activation.rcloneOneDriveBootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p '${rcloneConfigDir}' '${syncDir}'

        if [ ! -f '${rcloneConfigPath}' ]; then
          cat >'${rcloneConfigPath}' <<'EOF'
    [${remoteName}]
    type = onedrive
    EOF
          chmod 600 '${rcloneConfigPath}'
        elif ! grep -q '^\[${remoteName}\]$' '${rcloneConfigPath}'; then
          printf '\n[%s]\ntype = onedrive\n' '${remoteName}' >>'${rcloneConfigPath}'
          chmod 600 '${rcloneConfigPath}'
        fi
  '';

  systemd.user.services.onedrive-sync = {
    Unit = {
      Description = "Sync OneDrive to ${syncDir} via rclone";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.zsh}/bin/zsh -ilc 'onedrive-sync'";
    };
  };

  systemd.user.timers.onedrive-sync = {
    Unit = {
      Description = "Run OneDrive sync periodically";
    };

    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "30m";
      Unit = "onedrive-sync.service";
    };

    Install = {
      WantedBy = ["timers.target"];
    };
  };
}
