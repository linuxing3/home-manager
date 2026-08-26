---
name: install-nixos-beside-uos
description: Use when installing NixOS beside UOS on /dev/sda banana (sda4), running nixos-install or GRUB from UOS, systemd-nspawn testing the /mnt tree, unshare mount /proc EBUSY, nixos-enter chroot not found, or systemd-nspawn Failed to mount API filesystems with Protocol driver not attached (EUNATCH) on kernel 4.19. For post-install oxwm getty autologin, startx, or USB mouse on sda-phytium, use repair-oxwm-getty-mouse. For the HP Color LaserJet Pro M252n / CUPS USB queue, use configure-hp-m252n.
---

# Install NixOS beside UOS

**Live root (2026-08-24+):** NixOS is `nvme0n1p6` (`nixos-nvme`, flake `.#nvme-p6-phytium`). UOS stays on `nvme0n1p1`–`p5`. Banana `sda4` is the old copy. `/boot` and `/share` stay on sda.

Never `nixos-rebuild switch --flake …#sda-phytium` while running from NVMe. That writes a GRUB generation whose fstab is sda4 but whose store exists only on NVMe `@nix`. Generation 22 failed that way: initrd emergency, then `Cannot open access to console, the root account is locked` (`boot.initrd.systemd.emergencyAccess` plus a root hash live in `nixos/configuration.nix`).

Helper for the original sda install: `nixos/install-nixos-beside-uos.sh`. **Never** `mkfs` `sda3`/`sda4`, never Disko `destroy`/`format`, never touch UOS on `nvme0n1p1`–`p5`. Live GPT has **no PARTLABELS**; mounts are UUIDs.

## Disk

| Part | Role | UUID |
| --- | --- | --- |
| sda1 | EFI vfat | `C303-76DA` |
| sda2 | `/boot` ext4 | `bce6c448-b807-44ff-92e2-e75a159c7075` |
| sda3 | watermelon `/share` | `a992bbc6-8d8d-425b-b2a0-7db28df86524` |
| sda4 | banana btrfs `@nixos` `/`, `@nix`, `@home`, `@swap` | `8af40e6d-a21e-4339-8939-2f2510340951` |

## Install

Needs a real terminal and sudo. Sandbox is off because UOS 4.19 cannot run systemd 261 `udevadm verify` (`nixos/udev.nix`).

```sh
sudo nixos/install-nixos-beside-uos.sh mount
sudo nixos/install-nixos-beside-uos.sh swap
```

`swapon` of the 16G btrfs swapfile fails on 4.19; NixOS 6.18 uses it.

Build, then copy. Prefer the already-built closure:

```sh
nix build '.#nixosConfigurations.sda.config.system.build.toplevel' \
  --out-link /tmp/nixos-sda --option sandbox false --option filter-syscalls false
sudo nixos/install-nixos-beside-uos.sh install
```

## Kernel choice (GPU / sound)

| Profile | Kernel | Analog ft-hda | Glenfly GPU |
| --- | --- | --- | --- |
| `sda` (default) | mainline 6.18 | no | modesetting only |
| `sda-phytium` | Deepin `linux-6.6.y` | `snd-hda-phytium` | in-tree `arise` DRM |

UOS `arise_pro` / built-in `ft-hda` are tied to `4.19.0-arm64-desktop` and cannot load on NixOS. Prefer Deepin **6.6.y** over EOL `UOS-K5.10-LTS` (same drivers, newer ABI). Sketch: `nixos/kernel-phytium.nix`, `nixos/phytium-kernel.nix`. First time: `nix flake lock --update-input deepin-kernel` at the repo root (large fetch).

```sh
# Smoke-test vendor kernel packaging only (slow, large IFD):
nix build '.#linux-phytium' -L

# Full vendor-kernel system (still install with the helper after):
nix build '.#nixosConfigurations.sda-phytium.config.system.build.toplevel' \
  --out-link /tmp/nixos-sda --option sandbox false --option filter-syscalls false
```

X stays on `modesetting`; full Glenfly GL still needs userspace beyond the DRM module. Default `sda` profile is unchanged (mainline 6.18).

Type `INSTALL`. The helper uses `--system /tmp/nixos-sda` **or** `--flake`, never both (`nixos-install` rejects that). Then `nixos/nixos-enter-uos.sh` installs GRUB. Resume GRUB only with `... bootloader`.

Firmware default stays UOS NVMe. Pick **sda** EFI `BOOTAA64.EFI`.

Live rebuild:

```sh
sudo nixos-rebuild switch --flake /home/Designers/home-config#nvme-p6-phytium
```

Getty autologin → `startx` → oxwm, Glenfly dummy VGA, and the USB optical mouse (xHCI only; do not load `uhci_hcd`) are **REQUIRED SUB-SKILL:** `repair-oxwm-getty-mouse`. Do not add `systemd.services."getty@tty1"`.

USB HP Color LaserJet Pro M252n (EHCI, CUPS) is **REQUIRED SUB-SKILL:** `configure-hp-m252n` (`nixos/printing.nix`). Do not load `uhci_hcd` to configure it.

NixOS also ships **REQUIRED SUB-SKILL:** `configure-caps-escape` (`nixos/keyd.nix`), Terminus `ter-v32n` console font, and GRUB at `1920x1080` with Stylix Gruvbox dark (`stylix.targets.grub`).

Boot requires the **KeyVault USB** (LUKS passphrase on the console). `/keyvault` is mounted read-only. Banana `sda4` stays plaintext; do not `luksFormat` it. UOS on NVMe still boots without the USB.

On every NixOS boot and reboot, `@home` is snapshotted read-only to `@snapshots/home-YYYYMMDD-HHMMSS` (keep 12). Restore by snapshotting that subvolume back to `@home` from `/btrfs-root`.

## UOS 4.19 vs systemd 261

| Symptom | Cause | Do |
| --- | --- | --- |
| `unshare: mount /proc failed: 设备或资源忙` / EBUSY | `nixos-enter --mount-proc` vs `binfmt_misc` under `/proc` | `nixos-enter-uos.sh` (no `--mount-proc`); helper `bootloader` |
| `exec: chroot: not found` | PATH replaced with NixOS bins **before** host `chroot` | Keep `/usr/sbin/chroot`; prepend NixOS `sw/bin` |
| `mount: command not found` inside enter | Host PATH after chroot | `PATH=/nix/var/nix/profiles/system/sw/bin:...` inside `-c` |
| nspawn `--boot`: `Protocol driver not attached` / `Failed to mount API filesystems` | systemd 261 PID 1 on kernel 4.19 (`EUNATCH`) | Do not `--boot`. Shell only: helper `nspawn` |
| nspawn `--boot`: `execv(.../sbin/init) failed` | NixOS init is the profile, not FHS | Irrelevant; `--boot` still cannot work on 4.19 |
| Build `udevadm verify` EUNATCH | same kernel gap | `nixos/udev.nix`; `sandbox false` |

`systemd-nspawn --boot` cannot smoke-test this install on UOS. Real test is sda EFI. Shell nspawn / `nixos-enter-uos.sh` only inspect files.

## Common mistakes

| Excuse | Reality |
| --- | --- |
| Disko `destroy,format` is easier | Wipes banana and watermelon |
| nspawn `--boot` will work after `/sbin/init` | Init path was never the blocker; 4.19 cannot run systemd 261 |
| Skip `--option sandbox false` | Initrd udev verify dies on 4.19 |
| Format sda1/sda2 every install | Only if empty/wrong; UUIDs must stay as in `hardware-sda.nix` |
