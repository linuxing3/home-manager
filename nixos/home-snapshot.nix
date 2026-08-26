# Read-only snapshots of btrfs @home on boot and again on reboot/shutdown.
# Stored as top-level @snapshots/home-YYYYMMDD-HHMMSS, not inside @home.
{pkgs, ...}: let
  snapshotHome = pkgs.writeShellApplication {
    name = "snapshot-home-subvol";
    runtimeInputs = [pkgs.btrfs-progs pkgs.coreutils];
    text = ''
      set -eu
      root=/btrfs-root
      home_vol="$root/@home"
      snap_root="$root/@snapshots"
      keep=12

      [ -d "$root" ] || exit 0
      if ! btrfs subvolume show "$home_vol" >/dev/null 2>&1; then
        echo "snapshot-home-subvol: $home_vol is not a subvolume" >&2
        exit 1
      fi

      if ! btrfs subvolume show "$snap_root" >/dev/null 2>&1; then
        btrfs subvolume create "$snap_root"
      fi

      name="home-$(date -u +%Y%m%d-%H%M%S)"
      dest="$snap_root/$name"
      if [ -e "$dest" ]; then
        echo "snapshot-home-subvol: $dest already exists" >&2
        exit 0
      fi
      btrfs subvolume snapshot -r "$home_vol" "$dest"
      sync

      # GNU head -n -K drops the last K lines (newest); delete the rest.
      mapfile -t snaps < <(find "$snap_root" -mindepth 1 -maxdepth 1 -type d -name 'home-*' | sort)
      extra=$(( ''${#snaps[@]} - keep ))
      if [ "$extra" -gt 0 ]; then
        for old in "''${snaps[@]:0:$extra}"; do
          btrfs subvolume delete "$old"
        done
      fi
    '';
  };
in {
  systemd.tmpfiles.rules = [
    "d /btrfs-root 0700 root root -"
  ];

  systemd.services.snapshot-home-subvol = {
    description = "Read-only snapshot of btrfs @home";
    after = ["local-fs.target"];
    requires = ["local-fs.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${snapshotHome}/bin/snapshot-home-subvol";
      ExecStop = "${snapshotHome}/bin/snapshot-home-subvol";
    };
  };

  environment.systemPackages = [pkgs.btrfs-progs snapshotHome];
}
