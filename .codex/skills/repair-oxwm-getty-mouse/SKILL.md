---
name: repair-oxwm-getty-mouse
description: Use when NixOS-beside-UOS oxwm has no getty autologin, startx never runs on tty1, getty@tty1 dies 203/EXEC on /usr/bin/agetty, the pointer is invisible or frozen, xinput lists no USB Optical Mouse, or a mouse in a USB2 port never enumerates.
---

# Repair NixOS oxwm getty/startx and mouse

Host: Phytium D2000 + Glenfly, flake `.#nvme-p6-phytium` (live root `nvme0n1p6`). Persist in `nixos/desktop.nix`, `nixos/hardware-host.nix`, `nixos/keyd.nix`, `nixos/phytium-kernel.nix`. Do not `nixos-rebuild switch --flake …#sda-phytium` on this host.

UOS LightDM autologin is **REQUIRED SUB-SKILL:** `uos-desktop-bootstrap` section 3b. Do not copy UOS `getty@.service.d/autologin-startx.conf` onto NixOS.

USB HP Color LaserJet Pro M252n on EHCI is **REQUIRED SUB-SKILL:** `configure-hp-m252n`. Do not move it to USB3 or load `uhci_hcd` to configure printing.

## Getty autologin → startx

Boot log `Unable to locate executable '/usr/bin/agetty'` is nixpkgs#429775. Any `systemd.services."getty@tty1"` instance unit or `overrideStrategy = "asDropin"` replaces NixOS's wrapper; `ExecStart` falls back to missing `/usr/bin/agetty`.

Use only `services.getty.autologinUser`. Do not set `enable`, `wantedBy`, or `ExecStart` on `getty@tty1`. Disabling `getty@tty2`–`tty6` can leave `getty@tty1` disabled.

NixOS `/etc/profile` does not source `/etc/profile.d`. Put startx in `environment.loginShellInit`. Match this login only:

```sh
case "${XDG_VTNR:-}:$(tty 2>/dev/null || true)" in
  1:*|*:/dev/tty1) exec startx ;;
esac
```

Never read `/sys/class/tty/tty0/active` (HDMI foreground). A tty2 login would steal startx.

Verify: `systemctl show getty@tty1 -p DropInPaths -p ExecStart` lists `getty@.service.d/overrides.conf` and a nix-store `getty` wrapper with `--autologin Designers`. `getty.target` `Wants=` includes `getty@tty1.service`. Reboot: getty → no password → startx on **vt1**.

## Mouse / pointer in oxwm

Diagnose before changing USB or kernel modules:

```sh
cat /sys/class/tty/tty0/active
pgrep -af '/bin/X |oxwm'
DISPLAY=:0 xinput list --short; DISPLAY=:1 xinput list --short
for d in /sys/bus/usb/devices/[0-9]*; do
  [ -f "$d/idVendor" ] || continue
  echo "$(basename $d) $(cat $d/idVendor):$(cat $d/idProduct) $(cat $d/product 2>/dev/null)"
done
```

| Symptom | Cause | Do |
| --- | --- | --- |
| oxwm visible, mouse/keyboard dead; Xorg `Suspending AIGLX` / `got pause`; XI `[floating slave]` | HDMI VT ≠ X VT (`tty2` vs `vt1`) | `sudo chvt 1`; persist `Option "DontVTSwitch" "on"` |
| No cursor on HDMI; `VGA-1` primary | Glenfly dummy VGA | `video=VGA-1:d`; `Option "SWcursor" "on"` on **Device-modesetting[0]** (`services.xserver.deviceSection`), not only the unused Glenfly Device |
| `xinput` has no `USB Optical Mouse`; sysfs has no `05af:413a` | Mouse on Zhaoxin UHCI 0d:10.x | Plug into **xHCI** 0d:12.0 (USB3, or the KeyVault hub). Desk mouse is `05af:413a` |
| `modprobe uhci_hcd` hangs | UHCI HCPE on 6.6.152 | Keep `uhci_hcd` blacklisted. Do not load it to “test” |
| “I plugged it” but no new HID | Keyboard was moved, or port is still UHCI | Require a new `usb *: new low-speed` + `USB Optical Mouse` in dmesg/`xinput` |
| Buttons inverted after “fix” | libinput `LeftHanded` plus xmodmap/xinput remap | NixOS: libinput only. Skip extra button maps when `/etc/NIXOS` exists |
| keyd eats the pointer | `[ids] *` grabbed a mis-IDed mouse | `ids = ["*" "-05af:413a"]` (`k:*` is not a wildcard; it matches nothing) |
| Caps/Escape dead, `DEVICE: ignoring` every keyboard | `ids = ["k:*"]` treated as a literal id | `*` plus mouse exclude in `nixos/keyd.nix` |

Working check: `USB Optical Mouse` is a **slave pointer** (not floating), `Device Enabled` is 1, and `/sys/class/tty/tty0/active` is `tty1`.

## Rebuild

```sh
sudo nixos-rebuild switch --flake /home/Designers/home-config#nvme-p6-phytium
```

`firewall.service` may fail (`ip6tables` rpfilter / missing module). That is not getty or mouse. Confirm `/run/current-system` advanced and the files under `/etc/X11` and `/etc/profile` match the flake.
