# GPT layout for /dev/sda. Never pass this to `disko --mode destroy,format`.
# Live data: sda3 watermelon = /share. Future NixOS root is sda4 @nixos.
{device ? "/dev/sda"}: {
  disko.devices.disk.sda = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        efi = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = ["-n" "EFI"];
            mountpoint = "/boot/efi";
            mountOptions = ["umask=0077"];
          };
        };
        boot = {
          size = "4G";
          type = "8300";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = ["-L" "boot"];
            mountpoint = "/boot";
          };
        };
        watermelon = {
          size = "500G";
          type = "8300";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = ["-L" "watermelon"];
            mountpoint = "/share";
          };
        };
        banana = {
          size = "100%";
          type = "8300";
          content = {
            type = "btrfs";
            extraArgs = ["-L" "banana"];
            subvolumes = {
              "/@nixos" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@home" = {
                mountpoint = "/home";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@swap" = {
                mountpoint = "/swap";
                mountOptions = ["compress=no" "noatime"];
              };
            };
          };
        };
      };
    };
  };
}
