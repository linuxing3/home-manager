# Live WDC WD10EARZ partitions. GPT PARTLABEL is empty; Disko by-partlabel
# links do not exist. Mount by filesystem UUID so NixOS can boot.
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8af40e6d-a21e-4339-8939-2f2510340951";
    fsType = "btrfs";
    options = ["subvol=/@nixos" "compress=zstd" "noatime"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/8af40e6d-a21e-4339-8939-2f2510340951";
    fsType = "btrfs";
    options = ["subvol=/@nix" "compress=zstd" "noatime"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/8af40e6d-a21e-4339-8939-2f2510340951";
    fsType = "btrfs";
    options = ["subvol=/@home" "compress=zstd" "noatime"];
  };

  fileSystems."/btrfs-root" = {
    device = "/dev/disk/by-uuid/8af40e6d-a21e-4339-8939-2f2510340951";
    fsType = "btrfs";
    options = ["subvolid=5" "compress=zstd" "noatime"];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/8af40e6d-a21e-4339-8939-2f2510340951";
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
