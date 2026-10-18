# net-panel

Loopback-only web panel (Go + `go:embed`) for this NixOS host: Vivo USB
reverse tether, Vivo hotspot, Isvoro HK WireGuard (`wg0`) and the 1080/18080
proxies for phones, plus an animated SVG of the live routing path.

## Run

```sh
net-panel                       # http://127.0.0.1:7878
net-panel -listen 127.0.0.1:9000
net-panel -config /path/config.json
net-panel -print-config         # effective config (defaults + file)
```

Home Manager: `my.features.home.netPanel.enable = true;` installs the binary.
`my.features.home.netPanel.service = true;` additionally runs it as the user
unit `net-panel.service` (off by default). The server refuses any non-loopback
listen address and any request whose `Host` is not loopback; POSTs need the
`X-Net-Panel: 1` header, so other sites cannot drive it from a browser.

## What each switch does

All state shown is read live every 4 s (`ip route get 1.1.1.1`, `ip rule`,
`ss -ltnp`, `systemctl --user is-active`, `adb`, `/sys/class/net`).

| Switch | On | Off |
| --- | --- | --- |
| VIVO USB share | remove `~/.local/state/vivo-off`, `systemctl --user start gnirehtet-share` | create `vivo-off` (stops `vivo-watchdog` restarting it), stop `gnirehtet-share` |
| VIVO hotspot | `adb shell cmd wifi start-softap <ssid> <security> <pass>` | `adb shell cmd wifi stop-softap` |
| HK WireGuard | `isvoro-wg-up` | `isvoro-wg-down` |
| SOCKS5 / HTTP | transient user unit `net-panel-socks` (microsocks) / `net-panel-http` (tinyproxy) + `adb reverse tcp:P tcp:P` | stop the unit, or `fuser -k P/tcp` if another process (e.g. `gnirehtet-share`) owns the port; remove the `adb reverse` |

The existing Home Manager scripts and units are called unchanged.
`isvoro-wg-up/down` use `sudo` (passwordless on this host); without
passwordless sudo the panel reports the failure instead of prompting.
`wg show` is queried only for `endpoints`, `latest-handshakes`, `transfer`;
output lines mentioning private/preshared keys are dropped before display.

Hotspot: needs Android 11+ where `cmd wifi start-softap` is allowed for the
adb shell. If the command is missing or refused, the panel opens the phone's
tethering settings page instead. The passphrase is read from
`hotspot.pass_file` (mode 600, not in git) and sent to the phone over stdin,
never in argv, logs or the UI.

## Config

Default path `~/.config/net-panel/config.json` (`$XDG_CONFIG_HOME` honoured),
written by the "保存配置" button (mode 600). Missing keys take defaults.

```json
{
  "listen": "127.0.0.1:7878",
  "lan": {"iface": "enp11s0", "gateway": "10.10.30.1"},
  "vivo": {"service": "gnirehtet-share", "off_flag": "~/.local/state/vivo-off",
           "adb_serial": "", "phone_tun_ip": "10.0.0.2", "relay_port": 31416},
  "hotspot": {"ssid": "feifei", "security": "wpa2",
              "pass_file": "~/.config/net-panel/hotspot.pass", "gateway_ip": "10.21.163.227"},
  "wireguard": {"iface": "wg0", "up_cmd": "isvoro-wg-up", "down_cmd": "isvoro-wg-down",
                "endpoint": "103.138.72.79:10010", "address": "10.66.66.2/24"},
  "proxy": {"socks": {"listen": "127.0.0.1", "port": 1080},
            "http": {"listen": "127.0.0.1", "port": 18080}, "adb_reverse": true}
}
```

`security` is one of `open|wpa2|wpa3|wpa3_transition`. `adb_serial` empty =
the only attached device. `listen` changes apply after restarting net-panel;
everything else applies on the next action/refresh.

## Which apps use 1080 vs 18080

Phones reach both through `adb reverse`, i.e. at the Vivo hotspot gateway
(`hotspot.gateway_ip`, default `10.21.163.227`) on the same port.

- **SOCKS5 :1080** (microsocks): any TCP app. iPhone Surge / Shadowrocket
  (`socks5, 10.21.163.227, 1080`, `FINAL` to it, Wi-Fi proxy Off), Mail
  IMAP/SMTP, X, Telegram; `curl --socks5-hostname`, git, ssh `ProxyCommand`.
- **HTTP :18080** (tinyproxy, CONNECT 443/563 only): iPhone Wi-Fi
  "Configure Proxy → Manual" for Safari, App Store and apps that honour the
  system proxy; `http_proxy`/`https_proxy` for npm, pip, apt. Apps that ignore
  the system proxy (Mail, X) need SOCKS5.

While HK WireGuard is up it is a full tunnel, so proxied phone traffic exits in
Hong Kong too.
