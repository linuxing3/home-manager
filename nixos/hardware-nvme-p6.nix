# NixOS root on nvme0n1p6 (was UOS _dde_data). UOS EFI/Boot/Roota/KT_PART
# stay on nvme0n1p1–p2 and p4–p5. Shared swap is nvme0n1p3 (UOS SWAP).
# /boot and /share stay on sda. Never Disko-format nvme0n1.
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
    options = ["subvol=/@nix" "compress=zstd:1" "noatime"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvol=/@home" "compress=zstd" "noatime"];
  };

  fileSystems."/tmp" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvol=/@tmp" "compress=zstd:1" "noatime" "nodev" "nosuid"];
  };

  fileSystems."/btrfs-root" = {
    device = "/dev/disk/by-uuid/c39b75c4-277a-4c0f-9ce1-39c14c06e1bb";
    fsType = "btrfs";
    options = ["subvolid=5" "compress=zstd" "noatime"];
  };

  # Physical UOS SWAP on nvme0n1p3. The old 16G file remains at
  # /btrfs-root/@swap/swapfile until deleted.
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/7dc5be43-fb98-48e2-a893-4d84a216d0e3";
      options = ["discard"];
    }
  ];

  boot.tmp.useTmpfs = false;
  boot.tmp.cleanOnBoot = true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/bce6c448-b807-44ff-92e2-e75a159c7075";
    fsType = "ext4";
    options = ["noatime"];
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/C303-76DA";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  fileSystems."/share" = {
    device = "/dev/disk/by-uuid/a992bbc6-8d8d-425b-b2a0-7db28df86524";
    fsType = "ext4";
    options = ["noatime"];
  };
}
