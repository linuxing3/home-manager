# Isvoro HKT wg0 · Hong Kong home WireGuard

Full-tunnel WireGuard from NixOS (Designers) to Isvoro HKT A1 home NAT. Proven 2026-10-11 with `~/bin/isvoro-wg-up.sh` → public IP `112.120.252.134` (Hong Kong, HKT Limited).

## Layout

| Piece | Location |
| --- | --- |
| NixOS module | `nixos/wireguard-isvoro.nix` (imported in `flake/nixos.nix`) |
| HM commands | `isvoro-wg-up` / `isvoro-wg-down` in `profiles/work/packages.nix` |
| User scripts (proven) | `~/bin/isvoro-wg-up.sh`, `~/bin/isvoro-wg-down.sh` |
| Skill | `.codex/skills/activate-isvoro-wg0/SKILL.md` |
| Private key | `~/.config/wireguard/isvoro-client.key` (never commit) |

## Addressing

- Client: `10.66.66.2/24` on `wg0`
- Endpoint: `103.138.72.79:10010` (public NAT) → `192.168.17.10:51820` on VPS `hkt-20261006043720`
- SSH: `ssh -p 10009 root@103.138.72.79`
- Peer public key: `AMdDWzvPiksyFFVLAGNoNZ9TSmCBGwQL1QFJDp925FM=`

## Preferred ops

```sh
isvoro-wg-up    # or ~/bin/isvoro-wg-up.sh
isvoro-wg-down  # or ~/bin/isvoro-wg-down.sh
curl -s --noproxy '*' https://ipinfo.io/json   # expect country HK
```

Do not rely on `systemctl restart wireguard-wg0` (active/exited without iface). Scripts pin the endpoint route on the LAN NIC so full-tunnel does not blackhole UDP to the NAT.

## Server-side requirement

If handshake succeeds but almost no bytes received / curl hangs: enable IP forward and NAT on the HK host for `10.66.66.0/24`, then persist rules.
