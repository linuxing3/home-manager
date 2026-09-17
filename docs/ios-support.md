# iPhone and iPad support on NixOS

The shared NixOS configuration enables Apple USB multiplexing and user tools in `nixos/configuration.nix`:

- `services.usbmuxd.enable = true`
- `libimobiledevice`
- `ifuse`

Reference: <https://nixos.wiki/wiki/IOS>.

## What the stack does

`usbmuxd` multiplexes services over the iOS USB connection. The NixOS module creates the restricted `usbmux` account, applies an Apple USB vendor `05ac` udev permission rule, and starts the daemon at multi-user boot. `libimobiledevice` provides pairing and device-service commands. `ifuse` mounts iOS-exposed media or app document storage through FUSE.

This does not unlock the complete iOS filesystem. The phone must be unlocked and must trust the computer.

## Enable and verify

The live host boots from NVMe and uses `.#nvme-p6-phytium`:

```sh
nix build --no-link .#nixosConfigurations.nvme-p6-phytium.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#nvme-p6-phytium
systemctl is-enabled usbmuxd.service
systemctl is-active usbmuxd.service
command -v idevicepair ifuse
```

Do not switch `.#sda-phytium` while the running root is `nvme0n1p6`.

## Pair and mount

```sh
idevicepair pair
idevicepair validate
mkdir -p ~/iPhone
ifuse ~/iPhone
```

Unmount with `fusermount -u ~/iPhone`.

If pairing fails, use a data-capable cable, unlock the device, clear and accept the trust prompt, check `idevice_id -l`, and inspect `journalctl -u usbmuxd`. Remove pairing records only as a deliberate final recovery step.

Operational skill: `.codex/skills/configure-ios-support/SKILL.md`.
