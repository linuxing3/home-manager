# NixOS root on nvme0n1p6 (was UOS _dde_data). UOS Roota/Boot/EFI/SWAP stay
# on nvme0n1p1–p5. /boot and /share stay on sda. Never Disko-format nvme0n1.
#
# UUID is the live btrfs created 2026-08-24 (label nixos-nvme).
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvol=/@nixos" "compress=zstd" "noatime"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvol=/@nix" "compress=zstd" "noatime"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvol=/@home" "compress=zstd" "noatime"];
  };

  fileSystems."/btrfs-root" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvolid=5" "compress=zstd" "noatime"];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvol=/@swap" "compress=no" "noatime"];
  };

  swapDevices = [
    {device = "/swap/swapfile";}
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/bce6c448-b807-44ff-92e2-e75a159c7075";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/C303-76DA";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  fileSystems."/share" = {
    device = "/dev/disk/by-uuid/a992bbc6-8d8d-425b-b2a0-7db28df86524";
    fsType = "ext4";
  };
}
