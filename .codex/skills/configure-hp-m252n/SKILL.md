---
name: configure-hp-m252n
description: Use when configuring or repairing the HP Color LaserJet Pro M252n on NixOS-beside-UOS sda-phytium, CUPS is missing, lpstat or lpadmin are not found, ensure-printers.service fails, cups-driverd cannot get a PPD, usblp holds usb 1-1, or USB print jobs never leave the queue.
---

# Configure HP Color LaserJet Pro M252n

Host: Phytium D2000, flake `.#nvme-p6-phytium`, user `Designers`. Persist in `nixos/printing.nix` (imported by `flake/nixos.nix`). New Nix files must be `git add`ed or the flake cannot see them. Do not switch `sda-phytium` while root is on `nvme0n1p6`.

USB mouse on xHCI is **REQUIRED SUB-SKILL:** `repair-oxwm-getty-mouse`. Do not load `uhci_hcd` to “find” the printer.

## Hardware

| Item | Value |
| --- | --- |
| Model | HP Color LaserJet Pro M252n (print only; no scanner, no duplexer) |
| USB | `03f0:3c2a`, serial `VNC3J02356`, EHCI `usb 1-1` |
| PDLs | POSTSCRIPT, PDF, PCL (`ieee1284_id`) |
| Paper | A4 |

Keep this printer on USB2/EHCI. The desk mouse stays on xHCI/USB3.

## CUPS

`services.printing.enable` already blacklists `usblp` (libusb backend). If `usblp` is still loaded, `sudo rmmod usblp`. Do not add `hplip`/`ipp-usb` unless USB generic PostScript fails.

Queue (source of truth is `lpinfo -v` / `lpinfo -m` after CUPS is up):

```nix
name = "HP_M252n";
deviceUri = "usb://HP/Color%20LaserJet%20Pro%20M252n?serial=VNC3J02356";
model = "drv:///sample.drv/generic.ppd";
ppdOptions.PageSize = "A4";
```

`lp`/`lpadmin` extraGroups apply on the next login; local CUPS print as `Designers` works without a new session.

```sh
sudo nixos-rebuild switch --flake /home/Designers/home-config#nvme-p6-phytium
lpstat -p -d -s
echo test | lp -d HP_M252n
```

`firewall.service` may fail (`ip6tables` rpfilter). That is not CUPS. Confirm `ensure-printers.service` is active and `/run/current-system` advanced.

## Do not

| Trap | Reality |
| --- | --- |
| `drv:///sample.drv/postscript.ppd` | Not in CUPS sample.drv. Use `generic.ppd` (Generic PostScript). Log: `cups-driverd failed to get PPD` / `PPD "…postscript.ppd" not found` |
| URI `usb://Hewlett-Packard/HP%20Color%20LaserJet%20Pro%20M252n?…` | `lpinfo -v` reports `usb://HP/Color%20LaserJet%20Pro%20M252n?serial=VNC3J02356` |
| Guess PPD before CUPS exists | Enable CUPS, then `lpinfo -m` / `lpinfo -v` |
| `modprobe uhci_hcd` because the printer is USB | Printer is on Zhaoxin EHCI `0d:10.7`. UHCI hangs 6.6.152 |
| Add LAN queues from `lpinfo -v` `socket://10.10.30.*` | Other devices (M403dn, M401dn, GXP-MC5-E). USB M252n only unless asked |
| `hplipWithPlugin` on aarch64 | Not needed; native PS works with sample `generic.ppd` |
