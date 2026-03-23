{
  system = "aarch64-linux"; # system arch
  hostname = "nixos"; # hostname
  profile = "work"; # select a profile defined from my profiles directory
  timezone = "America/Sao_Paulo"; # select timezone
  locale = "en_US.UTF-8"; # select locale
  bootMode = "msdos"; # uefi or bios
  bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
  grubDevice = "nodev"; # device identifier for grub; only used for legacy (bios) boot mode
  gpuType = "intel"; # amd, intel or nvidia; only makes some slight mods for amd at the moment
}
