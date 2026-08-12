# UOS/DDE Service Optimization Suggestions

Status: recommendations only; no service changes are authorized by this document.

Baseline captured on 2026-08-12:

- System state: `degraded` because `dde-filemanager-daemon.service` exited with
  `SIGSEGV`.
- DDE remains usable: the session manager, desktop, window manager, dock,
  launcher, lock screen, clipboard, audio, and user file-manager server are
  running.
- Fcitx 4, the Sogou IME service and watchdog, and the Home Manager
  `gpg-agent.service` are running.
- Boot completes in 14.1 seconds and reaches `graphical.target` in 10.4 seconds.

## Objective

Keep a minimal, dependable DDE desktop without changing the system boot path.
Reduce only non-desktop user-session autostarts, one service at a time, with a
logout/login verification after each change.

## Never stop or disable

- Chinese input: `fcitx`, `fcitx-helper`, `fcitx-gsettingtool`,
  `sogouImeService-uos`, and `sogouImeService-watchdog-uos`.
- GPG: `gpg-agent.service`, `gpg-agent.socket`, `gpg-agent-ssh.socket`,
  `gpg-agent-browser.socket`, `gpg-agent-extra.socket`, and `dirmngr.socket`.
- Login and display: `lightdm`, Xorg, `startdde`, `systemd-logind`, and D-Bus.
- DDE shell: `dde-session-daemon`, `kwin_x11`, `dde-desktop`, `dde-dock`,
  `dde-launcher`, `dde-lock`, `dde-osd`, DDE clipboard services, Deepin service
  managers, authentication, account, and Polkit components.
- Desktop hardware: NetworkManager, `wpa_supplicant`, PulseAudio/ALSA,
  `udisks2`, and `upower`.

Do not assign `Ctrl+Space` to a window-manager shortcut. Fcitx already owns the
native Sogou toggle.

## Minimal phased plan

### 1. Repair the existing DDE fault

Do not disable `dde-filemanager-daemon.service`. When no file operation is in
progress, restart only that service and verify desktop icons, the file manager,
removable drives, and its systemd result. If it segfaults again, investigate the
crash and `/etc/systemd/system.control/dde-filemanager-daemon.service.d/50-CPUQuota.conf`
instead of restarting the whole desktop.

### 2. Remove non-desktop user autostarts

Change these Home Manager services from automatic to manual start, one logical
group at a time:

1. AI/API group: `cli-proxy-api.service`, `cursor-to-openai.service`, and
   `cloudflared-cursor-openai.service`.
2. Herdr/Hermes group: `collie.service`, `hermes-dashboard.service`, and
   `hermes-gateway.service`.
3. Background automation: `onedrive-sync.timer` and `nnn-herdr-sync.path`.
4. Optional cosmetic automation: `st-theme-auto.timer`.

Keep the unit definitions so each service can still be started manually. Do not
remove packages, configuration, credentials, or data.

### 3. Preserve system boot behavior

Initially leave all system services unchanged, including
`NetworkManager-wait-online.service`, QAX, aTrust, Cloudflare, SSH, CUPS,
Winbind, and ModemManager. Leave the enabled-but-inactive `tailscaled.service`
unchanged until the historical Tailscale/Collie endpoint is explicitly retired.

Only consider system-service changes after the reduced user session has passed
several normal login cycles. QAX/aTrust may enforce organizational security,
and wait-online affects services that consume `network-online.target`.

## Verification after every change

Log out and back in; a reboot is not required for user-service changes. Require
all of the following before continuing:

- DDE desktop, window manager, dock, launcher, lock screen, clipboard, audio,
  and file manager work normally.
- `fcitx-remote` returns `1` or `2`; Sogou toggles with `Ctrl+Space`; both Sogou
  processes remain present.
- `gpg-agent.service` is active and the standard and SSH sockets are available.
- NetworkManager, PulseAudio, D-Bus, and the Deepin session manager are active.
- `systemctl --user --failed` is empty.
- No newly changed unit is restart-looping and no new error-level DDE journal
  entries appear.

If any protected component changes state, revert only the most recent change
before testing another candidate.

## Deferred candidates

These are not part of the minimal plan:

- Shortening or disabling NetworkManager wait-online.
- Disabling QAX, aTrust, Deepin Defender, or other vendor security services.
- Disabling CUPS, SSH, Winbind, ModemManager, Cloudflare, or Tailscale.
- Restarting the entire DDE session to recover one component.
- Reboot-based timing experiments.

Each deferred item needs a separate usage and dependency check plus explicit
authorization.

## OxWM compared with DDE

The comparison must distinguish a standalone OxWM session from replacing KWin
after DDE has already started. Only the standalone session can avoid most DDE
startup and memory costs.

### Current measurements

| Metric | DDE session | Standalone OxWM |
| --- | ---: | ---: |
| System boot to `graphical.target` | 10.4 s | Expected to remain similar; not yet measured |
| Login/session leader begins | 10.34 s after boot | Not yet measured |
| Main desktop processes begin | 12.04-12.35 s after boot | Not yet measured |
| Dock/plugin initialization continues until | At least 18.9 s after boot | Not applicable |
| Desktop-specific memory after about 24 hours | 319.6 MiB PSS | Not yet measured |
| Configuration validation | Not applicable | 0.00-0.01 s, about 4.5 MiB peak RSS |

The DDE memory figure includes `startdde`, `dde-session-daemon`, `dde-desktop`,
KWin, dock, file-manager server, OSD, WM D-Bus bridge, lock screen, launcher,
and clipboard processes. It excludes shared Xorg, Fcitx/Sogou, GPG, audio, and
applications. It is a long-running-session measurement, not a clean-login
baseline.

OxWM validation measures only executable and Lua-configuration loading. It is
not a window-manager runtime benchmark. No live OxWM sample is available, and
the host has neither Xvfb nor Xephyr for an isolated test.

Replacing only KWin with OxWM inside DDE is a weak optimization: it could avoid
only KWin's current 28.7 MiB PSS while retaining nearly all other DDE processes
and startup work. A standalone OxWM session is the candidate worth measuring.

### OxWM optimization plan

1. Define an explicit standalone LightDM session instead of relying only on the
   existing `~/.xinitrc`. Keep the normal Deepin session as the default and
   fallback. Do not replace system `graphical.target` or LightDM.
2. Create a small declarative OxWM session launcher that imports `DISPLAY` and
   `XAUTHORITY` into the user systemd/D-Bus environment, then starts OxWM.
3. Preserve the immutable user facilities in the OxWM session:
   `gpg-agent.service` and its sockets, Fcitx 4, the Sogou service, and its
   watchdog. Start an absent IME component once, but never stop, restart, or
   duplicate an already-running one. Keep `Ctrl+Space` owned by Fcitx.
4. Keep shared desktop essentials: D-Bus, Polkit agent, NetworkManager applet or
   equivalent control path, PulseAudio, power management, and removable-drive
   access. Do not autostart DDE desktop, dock, launcher, KWin, or file-manager
   desktop integration in the standalone OxWM session.
5. Keep OxWM autostart minimal. The current configuration starts only Xresources;
   retain that behavior initially. Do not add Picom, wallpaper daemons, status
   scripts, or duplicate IME launchers before the baseline is recorded.
6. Move the non-desktop API/Hermes/OneDrive services listed above to manual or
   delayed start before comparing sessions; otherwise they add the same noise
   to both results.

### Controlled A/B measurement

Run three fresh logins for each session without rebooting between individual
samples. Use the same applications closed and wait 60 seconds after login.
Record:

- Time from LightDM authentication to a ready marker: DDE dock responsive, or
  OxWM bar visible and a terminal launched successfully.
- PSS and private memory of session-specific processes from
  `/proc/PID/smaps_rollup`.
- Total user-slice memory from `systemd-cgtop`.
- Failed units, restart counts, and error-level journal entries.
- Fcitx/Sogou process presence, `Ctrl+Space`, and active GPG standard/SSH
  sockets.

Use the median of three runs. Accept standalone OxWM only if it is consistently
faster or lighter, Chinese input and GPG remain fully functional, and the DDE
session remains selectable as an unchanged fallback.
