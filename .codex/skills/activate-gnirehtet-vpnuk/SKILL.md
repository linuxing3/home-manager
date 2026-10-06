---
name: activate-gnirehtet-vpnuk
description: Activates, stops, and verifies NixOS VPNUK WireGuard, Android gnirehtet USB reverse tether, and iPhone sharing via the Android Wi-Fi hotspot using HTTP (tinyproxy :18080) or SOCKS5 (microsocks :1080) over adb reverse. Use when the user asks to share host Internet with Vivo/Android or iPhone, enable or disable vpnuk-uk-dedicated, reset networking to Brazil LAN, or repair Play Store downloads that will not use gnirehtet.
---

# Activate gnirehtet, iPhone proxies, and VPNUK

Home Manager: `gnirehtet-share-vpnuk` (VPNUK + USB + HTTP `:18080` + SOCKS `:1080`), `gnirehtet-share` (USB + proxies, no VPN change), `gnirehtet-connect` (USB only) in `profiles/work/packages.nix`. Do not add another wrapper.

## Identities

- LAN: `lan` on `enp11s0`.
- VPNUK: `nmcli connection up vpnuk-uk-dedicated`. WireGuard iface is dynamic (`Device_1`), not `wg0`. `wg` may be missing; use `ip -details link`.
- When up: `ip rule` `suppress_prefixlength 0` and `fwmark 0xcb94 lookup 52116`; `ip route get 1.1.1.1` must use that iface.
- Hotspot example: SSID `feifei`, Android `10.21.163.227/24` on `wlan2`, iPhone `10.21.163.67`.
- HTTP: tinyproxy `127.0.0.1:18080` + `adb reverse tcp:18080 tcp:18080` (Android listens `*:18080`).
- SOCKS5: `microsocks -i 127.0.0.1 -p 1080` + `adb reverse tcp:1080 tcp:1080`.

## Activate Android through VPNUK

```sh
gnirehtet-share-vpnuk
```

Supervise until `Relay server started`. Without bringing VPNUK up: `gnirehtet-share`. Android-only: `gnirehtet-connect`. Phone `10.0.0.2`. Match host vs `adb shell curl -4fsS --max-time 15 https://ifconfig.co`. Do not treat ping failure as a tether failure. Enable 个人热点 if `wlan2` is missing.


## iPhone on `feifei`

Hotspot clients are **not** in gnirehtet. Tethering upstream is `null` while gnirehtet owns VPNService.

- HTTP (Safari): tinyproxy `:18080`, iPhone proxy Manual `10.21.163.227:18080`.
- SOCKS5 (Mail IMAP, X, arbitrary TCP): microsocks `:1080`. iPhone Wi-Fi proxy **Off**. Surge iOS: `NixOS-SOCKS5 = socks5, 10.21.163.227, 1080`, `FINAL,NixOS-SOCKS5`, tap **Start**. No iOS “Enhanced Mode”.

Verify with `adb shell curl` to `10.21.163.227:18080` or `:1080`, not only `127.0.0.1`.

## Stop / Brazil

```sh
# stop gnirehtet-connect, tinyproxy, microsocks
adb reverse --remove-all
adb shell am force-stop com.genymobile.gnirehtet
nmcli connection down vpnuk-uk-dedicated
ip route get 1.1.1.1   # enp11s0
```

Do not take down `lan`/`enp11s0` unless asked.

## Play Store

Play APK fetch is **NOT_VPN**. It will not use gnirehtet. Vivo `com.bbk.appstore` hijacks `market://`; pass package `com.android.vending` or open Play explicitly. Sideload: `installerPackageName=null` until Play claims the package. `svc data enable` only when the user wants Play downloads; disable afterward if they wanted phones on the host tunnel only.

Do not treat ping failure as tether failure. IPv4 match ≠ IPv6 containment.

See `docs/gnirehtet-vpnuk.md`.
