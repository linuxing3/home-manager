# Require KeyVault USB A at NixOS boot. Banana (sda4) stays plaintext.
# UOS on nvme0n1 still boots without this USB.
#
# Use systemd-cryptsetup + ask-password on tty0. A custom /dev/console
# oneshot with TTYReset never showed a prompt after GRUB gfxpayload=keep
# on this Glenfly/Phytium box.
{
  lib,
  pkgs,
  ...
}: let
  # SanDisk Ultra KeyVault A (not the 7.5G Generic Flash Disk B).
  keyvaultLuksUuid = "abc4c91c-bd54-483a-8916-2ac41400e5dc";
in {
  boot.initrd.availableKernelModules = [
    "usb_storage"
    "uas"
    "xhci_pci"
    "xhci_plat_hcd"
    "sd_mod"
    "dm_mod"
    "dm_crypt"
    "xts"
    "aes"
    "aes_generic"
    "sha256"
    "sha512"
  ];

  boot.initrd.luks.devices.keyvault = {
    device = "/dev/disk/by-uuid/${keyvaultLuksUuid}";
    crypttabExtraOpts = ["timeout=0"];
  };

  boot.initrd.systemd.services.keyvault-layout-check = {
    description = "Verify unlocked USB is a KeyVault";
    wantedBy = ["initrd.target"];
    after = ["systemd-cryptsetup@keyvault.service"];
    before = ["sysroot-keyvault.mount"];
    requires = ["systemd-cryptsetup@keyvault.service"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      mkdir -p /keyvault-check
      if ! mount -o ro,nodev,nosuid,noexec /dev/mapper/keyvault /keyvault-check; then
        echo "KeyVault opened but could not be mounted."
        exit 1
      fi
      if [ ! -d /keyvault-check/uos-system-recovery ]; then
        echo "USB is not a KeyVault (missing uos-system-recovery)."
        umount /keyvault-check || true
        exit 1
      fi
      umount /keyvault-check
      rmdir /keyvault-check 2>/dev/null || true
    '';
  };

  fileSystems."/keyvault" = {
    device = "/dev/mapper/keyvault";
    fsType = "ext4";
    options = ["ro" "nodev" "nosuid" "noexec"];
    neededForBoot = true;
  };

  environment.systemPackages = [pkgs.cryptsetup];
}
