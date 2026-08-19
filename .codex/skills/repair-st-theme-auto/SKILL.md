---
name: repair-st-theme-auto
description: Use when st stays on the wrong Gruvbox light/dark colors after 07:00 or 18:00, st-theme-auto.timer is enabled but inactive (dead), or xrdb st.background does not match st-theme auto for the local hour.
---

# Repair st auto light/dark theme

`st` reads `st.*` Xresources at start. `st-theme auto` merges Gruvbox light from 07:00 inclusive to 18:00 exclusive, dark otherwise. `st-theme-auto.timer` must be **active** (`Persistent=true`) so a missed 07:00/18:00 still applies.

UOS Deepin does not reach `graphical-session.target`. Home Manager does not start newly enabled timers in an already-running user manager. `.xsessionrc` is often not sourced. The timer stays `enabled` and `inactive (dead)`, so `st-theme` never runs at 18:00.

Luke Smith `st` does not reload xrdb until patched for `SIGUSR1`. Unpatched `st` dies on `USR1` (default terminate). `st-theme` only signals PIDs whose `/proc/pid/exe` matches the current Nix `st`.

## Diagnose

```sh
date +%H
st-theme status
systemctl --user is-enabled st-theme-auto.timer
systemctl --user is-active st-theme-auto.timer
systemctl --user status st-theme-auto.timer --no-pager
systemctl --user is-active graphical-session.target timers.target default.target
xrdb -query | awk '$1 ~ /^st\.(background|foreground):/'
pgrep -ax st
```

After 18:00 or before 07:00 expect `dark`, timer `active`, `st.background: #282828`. Daytime expect `light` and `#fbf1c7`.

## Runtime repair

```sh
systemctl --user start st-theme-auto.timer
systemctl --user start st-theme-auto.service
st-theme auto
st-theme status
xrdb -query | awk '$1=="st.background:" {print $2}'
```

`Persistent=true` should fire the elapsed 07:00/18:00 job when the timer starts. New `st` windows pick up xrdb immediately. Existing windows reload only if they run the patched Nix `st` (`kill -USR1`). Restart unpatched `st` once after Home Manager installs the overlay patch.

Do not `pkill -USR1 -x st` blindly: that kills unpatched terminals.

## Persist

Keep `modules/tui/st-theme.nix` imported from the work profile. The timer is `WantedBy` `timers.target` and `default.target`. Activation starts the timer and runs `st-theme auto`. DDE autostart and oxwm `st-theme auto` cover login. Overlay `overlays/packages/st-reload-xrdb.patch` reloads colors on `SIGUSR1`.

After editing, activate Home Manager, then `systemctl --user is-active st-theme-auto.timer`.

## Verify

```sh
.codex/skills/repair-st-theme-auto/scripts/verify-st-theme
```

Require timer `active`, `st-theme status` matching the local hour, and xrdb `st.background` matching that mode. Do not treat an inactive `graphical-session.target` as a timer failure on this DDE host.
