---
name: configure-ios-support
description: Use when enabling or repairing iPhone or iPad support on this NixOS host, including usbmuxd, libimobiledevice pairing, ifuse mounts, Apple USB permissions, trust prompts, USB tethering, or idevicepair failures.
---

# Configure iOS support

Host: Phytium D2000, live flake target `.#nvme-p6-phytium`, user `Designers`. Persist shared iOS support in `nixos/configuration.nix`; do not switch `sda-phytium` while root is on `nvme0n1p6`.

## Declarative configuration

Enable:

```nix
services.usbmuxd.enable = true;
environment.systemPackages = with pkgs; [
  libimobiledevice
  ifuse
];
```

The NixOS `usbmuxd` module creates the `usbmux` system account, installs an Apple vendor (`05ac`) udev rule, triggers it during service startup, and runs `usbmuxd -U usbmux -v`. It also enables plug-and-play USB multiplexing used by pairing, file transfer, and potentially tethering.

## Build and activate

```sh
nix build --no-link .#nixosConfigurations.nvme-p6-phytium.config.system.build.toplevel
new=$(nix eval --raw '.#nixosConfigurations.nvme-p6-phytium.config.system.build.toplevel')
sudo "$new/bin/switch-to-configuration" dry-activate
sudo nixos-rebuild switch --flake .#nvme-p6-phytium
```

Review dry activation before switching. Do not reboot just to enable this service.

## Pair and mount

Connect the unlocked device, accept “Trust This Computer” on iOS, then:

```sh
idevicepair pair
idevicepair validate
mkdir -p ~/iPhone
ifuse ~/iPhone
```

Unmount with:

```sh
fusermount -u ~/iPhone
```

`ifuse` exposes the media/document interfaces iOS permits; it is not unrestricted access to the device filesystem.

## Verification

```sh
systemctl is-enabled usbmuxd.service
systemctl is-active usbmuxd.service
journalctl -u usbmuxd.service -n 20 --no-pager
command -v idevicepair ifuse
idevice_id -l
```

If no device appears, verify the cable supports data, unlock and re-trust the device, inspect USB detection and the `05ac` udev rule, then restart `usbmuxd`. Do not erase pairing records unless re-pairing is explicitly required.

See `docs/ios-support.md` for the operational runbook.
