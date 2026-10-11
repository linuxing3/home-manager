---
name: activate-isvoro-wg0
description: Activates, stops, and verifies NixOS Isvoro HKT (Hong Kong home) WireGuard full-tunnel on wg0. Use when the user asks for Hong Kong exit IP, Cloudflare/linux.do HK location, Isvoro/HKT home net, or wg0 up/down. Prefer ~/bin scripts or HM isvoro-wg-up/down; do not rely on systemd wireguard-wg0.
---

# Activate Isvoro HKT wg0 (Hong Kong home exit)

Home Manager: `isvoro-wg-up` / `isvoro-wg-down` in `profiles/work/packages.nix`. NixOS module: `nixos/wireguard-isvoro.nix` (included from `flake/nixos.nix`). Do not add another wrapper.

Proven path (2026-10-11): `~/bin/isvoro-wg-up.sh` / `~/bin/isvoro-wg-down.sh` → exit `112.120.252.134` Hong Kong, HKT Limited (AS4760). After HM switch, prefer PATH commands without `.sh`.

## When to use

- Need a real Hong Kong public IP (not Cloudflare Workers colo=HKG only).
- Cloudflare / linux.do / invite.linuxdo.org challenges that need HK egress.
- Distinguish from mihomo/homedge (proxy) and VPNUK (`vpnuk-uk-dedicated`, dynamic iface, not `wg0`).

## Identities

- Client: NixOS Designers, LAN `enp11s0` (example `10.10.30.11/24`, gateway `10.10.30.1`).
- Tunnel: `wg0`, address `10.66.66.2/24`, AllowedIPs `0.0.0.0/0` (full tunnel).
- Endpoint (NAT VPS): `103.138.72.79:10010` → internal `192.168.17.10:51820` (UDP/TCP). SSH map `10009→22`.
- Server label: `hkt-20261006043720` (Isvoro HKT A1).
- Private key file (never print / commit / paste): `~/.config/wireguard/isvoro-client.key`
- Peer public key (safe): `AMdDWzvPiksyFFVLAGNoNZ9TSmCBGwQL1QFJDp925FM=`

## Up / down

```sh
# Preferred after HM switch
isvoro-wg-up
isvoro-wg-down

# Also proven today (user PATH)
~/bin/isvoro-wg-up.sh
~/bin/isvoro-wg-down.sh
```

Up script: writes `/etc/wireguard/wg0.conf` at runtime from key file, pins `103.138.72.79/32` via LAN gateway (`PreUp`), then `wg-quick up wg0`. Needs sudo.

## Verify

```sh
ip -br addr show wg0
sudo wg show wg0 | grep -E 'endpoint|handshake|transfer'
curl -s --noproxy '*' --max-time 12 https://ipinfo.io/json
# expect country HK, org HKT / Netvigator
```

Healthy: recent `latest handshake`, non-trivial bytes **received**. Handshake with ~0 B received = server missing `ip_forward` + MASQUERADE.

## Caveats

- **Full tunnel**: all NixOS traffic (incl. Vivo share / mihomo egress) goes via HK while up. Stop with down script to restore Brazil LAN.
- **systemd `wireguard-wg0` unreliable**: may show active (exited) while iface missing. Prefer scripts / `wg-quick`, not `systemctl restart wireguard-wg0`.
- **HK server NAT**: if handshake works but curl hangs, on server enable `net.ipv4.ip_forward=1` and MASQUERADE for `10.66.66.0/24` out the WAN iface; persist in PostUp or iptables-save.
- **SSH to HK box**: `ssh -p 10009 root@103.138.72.79` (port map 10009→22).
- **Do not** commit private key, paste key contents into skill/Notion/git, or log `/etc/wireguard/wg0.conf`.

## Related

- Module: `nixos/wireguard-isvoro.nix`
- Docs: `docs/isvoro-wg0.md`
- Proxy (mihomo/homedge): separate skill path; not a substitute for real HKT IP.
