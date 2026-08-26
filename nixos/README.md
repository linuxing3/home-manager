# NixOS host configuration

This directory is the **NixOS** layer (hardware, boot, kernel, display, IME
immodules, printing). It is not a flake.

Evaluate and switch from the **repository root**:

```sh
sudo nixos-rebuild switch --flake /home/Designers/home-config#nvme-p6-phytium
```

Home Manager stays a separate command: `home-manager switch --flake .#Designers`.

Do not `nixos-rebuild switch` `#sda-phytium` while the live root is NVMe
(`nvme0n1p6`). That writes a GRUB generation whose fstab is sda4.

Disk layout notes live in `disko-config.nix` (documentary; `enableConfig` stays
false). Never Disko-format sda data partitions or UOS on nvme0n1p1–p5.
