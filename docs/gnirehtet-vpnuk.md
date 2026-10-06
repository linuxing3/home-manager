# Android reverse tethering, iPhone sharing, and VPNUK

This NixOS host can reverse-tether an Android phone over USB (`gnirehtet`) and share that path with an iPhone on the Android Wi-Fi hotspot via HTTP or SOCKS proxies. Host Internet may be full-tunnel VPNUK WireGuard or direct Brazilian Ethernet.

## Observed identities

- Wired LAN: NetworkManager connection `lan` on `enp11s0` (example `10.10.30.11/24`, gateway `10.10.30.1`).
- VPNUK: NetworkManager connection `vpnuk-uk-dedicated` on a WireGuard interface named dynamically (example `Device_1`, address `10.48.48.144/21`, MTU `1419`).
- Do not assume `wg0`. `wg` may be absent; identify with `ip -details link show <iface>`.
- Policy routing when VPNUK is up: `ip rule` entries `suppress_prefixlength 0` and `fwmark 0xcb94 lookup 52116`; default in table `52116` is `dev Device_1`.
- Android launcher: `gnirehtet-connect` in `profiles/work/packages.nix` (wrapper sets `ADB` and `GNIREHTET_APK`, then `gnirehtet run`).
- Android hotspot example: SSID `feifei`, gateway `10.21.163.227/24` on `wlan2`, iPhone lease `10.21.163.67`.
- Host HTTP proxy: `tinyproxy` on `127.0.0.1:18080`, published with `adb reverse tcp:18080 tcp:18080`.
- Host SOCKS5 proxy: `microsocks -i 127.0.0.1 -p 1080`, published with `adb reverse tcp:1080 tcp:1080`.
- Android reverse listeners bind `*:18080` and `*:1080` (not only `127.0.0.1`), so hotspot clients can reach them.

## Paths

Android apps (gnirehtet):

```text
Android app -> VPNService tun0 (10.0.0.2)
  -> gnirehtet client -> ADB USB -> gnirehtet relay on NixOS
  -> host routing (VPNUK Device_1 or LAN enp11s0) -> Internet
```

iPhone on Android hotspot (proxies, no root):

```text
iPhone -> Wi-Fi feifei -> 10.21.163.227:18080 or :1080
  -> adb reverse -> tinyproxy or microsocks on NixOS 127.0.0.1
  -> host routing (VPNUK or LAN) -> Internet
```

Gnirehtet is not an Ethernet bridge. Hotspot clients are not automatically forwarded into `tun0`. Android tethering `Current upstream interface(s): null` while gnirehtet is up is expected: hotspot NAT does not use the VPN TUN.

## Activate VPNUK + Android + iPhone proxies

```sh
gnirehtet-share-vpnuk
```

`gnirehtet-share-vpnuk` brings up `vpnuk-uk-dedicated`, checks `ip route get 1.1.1.1` uses that WireGuard iface, then runs `gnirehtet-share` (ADB, tinyproxy `:18080`, microsocks `:1080`, reverse maps, gnirehtet). Ctrl-C stops share/proxies, not VPNUK. Current routing without changing VPN: `gnirehtet-share`. Android-only: `gnirehtet-connect`.

Phone state must be `device`. Do not cycle VPNUK if it is already active. Public route must be the WireGuard iface (`Device_1`, not `wg0`). Accept Android VPN permission. Relay logs: `Relay server started` and sources `10.0.0.2`.

Verify:

```sh
host_ip=$(curl -4fsS --max-time 15 https://ifconfig.co)
phone_ip=$(adb shell curl -4fsS --max-time 15 https://ifconfig.co | tr -d '\r')
test "$host_ip" = "$phone_ip"
```

Do not use ping as the primary test.

## iPhone on Android hotspot

Hotspot clients are not in gnirehtet. `gnirehtet-share` publishes HTTP `:18080` and SOCKS `:1080`.

HTTP:

```sh
# tinyproxy listen 127.0.0.1:18080, Allow 127.0.0.1, ConnectPort 443
adb reverse tcp:18080 tcp:18080
```

iPhone Wi-Fi `feifei`: Configure Proxy Manual, server `10.21.163.227`, port `18080`, auth off.

SOCKS5 (IMAP, apps that ignore HTTP proxy):

```sh
# microsocks -i 127.0.0.1 -p 1080
adb reverse tcp:1080 tcp:1080
```

iPhone: Wi-Fi proxy **Off**. Surge iOS: `NixOS-SOCKS5 = socks5, 10.21.163.227, 1080`, `FINAL,NixOS-SOCKS5`, tap **Start** (iOS VPN extension). There is no Surge iOS “Enhanced Mode”; that name is Mac-only.

Verify HTTP or SOCKS from the Android shell (proves the hotspot bind):

```sh
adb shell curl -4fsS --max-time 15 -x http://10.21.163.227:18080 https://ifconfig.co
adb shell curl -4fsS --max-time 15 --socks5-hostname 10.21.163.227:1080 https://ifconfig.co
```

Match `curl -4fsS --max-time 15 https://ifconfig.co` on the host. Android reverse listeners are `*:18080` and `*:1080`.

## Brazil / direct LAN

```sh
nmcli connection down vpnuk-uk-dedicated
ip route get 1.1.1.1   # via 10.10.30.1 dev enp11s0
curl -4fsS --max-time 15 https://ifconfig.co/country-iso   # BR
```

`Device_1` disappears when VPNUK is down. Host DNS on LAN: `8.8.8.8`, `1.1.1.1`.

## Stop phone networking

Stop `gnirehtet-connect` (Ctrl-C or kill the relay). Stop tinyproxy/microsocks. Then:

```sh
adb reverse --remove-all
adb shell am force-stop com.genymobile.gnirehtet
```

Do not kill host `lan` / `enp11s0` unless asked. After gnirehtet stops, Android may fall back to Wi-Fi or mobile data.

## Google Play on Android

Play APK fetches use a **NOT_VPN** network. They will not use gnirehtet. With only USB reverse-tether, installs sit on **等待中…**. Vivo’s own store (`com.bbk.appstore`) hijacks `market://`; open the listing **in Google Play**. Enable mobile data or Wi-Fi for Play downloads, or sideload with `adb install` / `install-multiple`. Sideloaded packages have `installerPackageName=null` until Play has installed or claimed them.

## Stop VPNUK (Brazil LAN)

```sh
nmcli connection down vpnuk-uk-dedicated
ip route get 1.1.1.1   # via 10.10.30.1 dev enp11s0
```

## Troubleshooting

- `unauthorized`: unlock phone, accept USB debugging.
- Hotspot clients have no Internet without HTTP/SOCKS proxies; Android tethering upstream is `null` under gnirehtet.
- iPhone Mail/X ignore Wi-Fi HTTP proxy; use Surge SOCKS5 and tap **Start** (no iOS “Enhanced Mode”).
- iPhone Wi-Fi HTTP proxy: `10.21.163.227:18080`. SOCKS5: `10.21.163.227:1080`, Wi-Fi proxy Off.
- ICMP is not a gnirehtet test.
- Broadcast `Permission denied` on the relay is not a unicast failure.
- IPv4 IP match does not prove IPv6 containment (`::/0 unreachable` on `tun0`).

Operational skill: `.codex/skills/activate-gnirehtet-vpnuk/SKILL.md`.
