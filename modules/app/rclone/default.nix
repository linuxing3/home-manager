{
  config,
  pkgs,
  lib,
  ...
}: let
  remoteName = "onedrive-xingwenju0928";
  syncDir = "/share/data/workspace/onedrive";
  rcloneConfigDir = "${config.xdg.configHome}/rclone";
  rcloneConfigPath = "${rcloneConfigDir}/rclone.conf";
  bisyncDir = "${config.xdg.cacheHome}/rclone/bisync/onedrive-xingwenju0928";
  bisyncInitialized = "${bisyncDir}/initialized";

  # UOS provides a setuid FUSE 2 helper. Reuse it because the FUSE 3 helper in
  # the Nix store cannot carry the setuid bit required for user mounts.
  fusermount3Compat = pkgs.writeShellScriptBin "fusermount3" ''
    exec /usr/bin/fusermount "$@"
  '';

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

  onedriveSync = pkgs.writeShellApplication {
    name = "onedrive-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.rclone
    ];
    text = ''
      mkdir -p '${syncDir}' '${bisyncDir}'
      chmod 700 '${bisyncDir}'
      chmod 600 '${bisyncDir}'/* 2>/dev/null || true

      if ! rclone about ${remoteName}: \
        --contimeout 10s \
        --timeout 30s \
        >/dev/null 2>&1; then
        echo "onedrive-sync: remote is not ready; run onedrive-connect" >&2
        exit 0
      fi

      bisync_args=(
        --workdir '${bisyncDir}'
        --create-empty-src-dirs
        --fast-list
        --compare "size,modtime"
        --conflict-resolve newer
        --conflict-loser num
        --recover
        --resilient
        --max-lock 2h
        --max-delete 50
        --exclude '/AGENTS.md'
        --exclude '/个人保管库/'
        --exclude '/个人保管库/**'
        --exclude '/Personal Vault/'
        --exclude '/Personal Vault/**'
      )

      if [ ! -e '${bisyncInitialized}' ]; then
        if rclone bisync ${remoteName}: '${syncDir}' \
          "''${bisync_args[@]}" \
          --resync \
          --resync-mode newer \
          "$@"; then
          touch '${bisyncInitialized}'
          exit 0
        fi
        exit 1
      fi

      exec rclone bisync ${remoteName}: '${syncDir}' \
        "''${bisync_args[@]}" \
        "$@"
    '';
  };

  onedriveCopy = pkgs.writeShellScriptBin "onedrive-copy" ''
    set -euo pipefail
    mkdir -p '${syncDir}'
    exec rclone copy ${remoteName}: '${syncDir}' \
      --create-empty-src-dirs \
      --fast-list \
      --exclude '/个人保管库/' \
      --exclude '/个人保管库/**' \
      --exclude '/Personal Vault/' \
      --exclude '/Personal Vault/**' \
      "$@"
  '';
in {
  home.packages = [
    fusermount3Compat
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
      Description = "Bidirectionally sync OneDrive and ${syncDir} via rclone";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${onedriveSync}/bin/onedrive-sync";
      UMask = "0077";
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
