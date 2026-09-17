---
name: repair-st-theme-auto
description: Use when the system stays on the wrong Catppuccin light/dark theme after 07:00 or 18:00, theme-auto.timer is enabled but inactive (dead), or xrdb/GTK/nvim do not match theme-switch auto for the local hour.
---

# Repair system-wide auto light/dark theme

`theme-switch` is the unified Catppuccin light/dark switcher. It handles:
- **st** terminal (xrdb + SIGUSR1 reload)
- **GTK / browsers** (gsettings `color-scheme` + `gtk-theme`)
- **Neovim** (writes `~/.local/state/theme-mode`; nvim watches it)
- **Helix** (sed `config.toml`; helix auto-reloads)
- **fzf** (writes `~/.local/state/fzf-theme.sh`; new shells source it)
- **Herdr** (`auto_switch = true` follows system theme)

`theme-switch auto` applies Catppuccin Latte (light) from 07:00 inclusive to 18:00 exclusive, Catppuccin Mocha (dark) otherwise. `theme-auto.timer` must be **active** (`Persistent=true`).

`Super+F5` (oxwm) runs `theme-switch toggle`.

UOS Deepin does not reach `graphical-session.target`. Home Manager does not start newly enabled timers in an already-running user manager. `.xsessionrc` is often not sourced. The timer stays `enabled` and `inactive (dead)`, so `theme-switch` never runs at 18:00.

Luke Smith `st` does not reload xrdb until patched for `SIGUSR1`. Unpatched `st` dies on `USR1` (default terminate). `theme-switch` only signals PIDs whose `/proc/pid/exe` matches the current Nix `st`.

## Diagnose

```sh
date +%H
theme-switch status
systemctl --user is-enabled theme-auto.timer
systemctl --user is-active theme-auto.timer
systemctl --user status theme-auto.timer --no-pager
systemctl --user is-active graphical-session.target timers.target default.target
xrdb -query | awk '$1 ~ /^st\.(background|foreground):/'
gsettings get org.gnome.desktop.interface color-scheme
pgrep -ax st
```

After 18:00 or before 07:00 expect `dark`, timer `active`, `st.background: #010101`, `color-scheme: prefer-dark`. Daytime expect `light`, `#eff1f5`, `prefer-light`.

## Runtime repair

```sh
systemctl --user start theme-auto.timer
systemctl --user start theme-auto.service
theme-switch auto
theme-switch status
xrdb -query | awk '$1=="st.background:" {print $2}'
gsettings get org.gnome.desktop.interface color-scheme
```

`Persistent=true` should fire the elapsed 07:00/18:00 job when the timer starts. New `st` windows pick up xrdb immediately. Existing windows reload only if they run the patched Nix `st` (`kill -USR1`). Restart unpatched `st` once after Home Manager installs the overlay patch.

Do not `pkill -USR1 -x st` blindly: that kills unpatched terminals.

## Persist

Keep `modules/tui/st-theme.nix` imported from the work profile. The timer is `WantedBy` `timers.target` and `default.target`. Activation runs `theme-switch auto`. DDE autostart and oxwm `theme-switch auto` cover login. Overlay `overlays/packages/st-reload-xrdb.patch` reloads colors on `SIGUSR1`.

After editing, activate Home Manager, then `systemctl --user is-active theme-auto.timer`.

## Verify

```sh
.codex/skills/repair-st-theme-auto/scripts/verify-st-theme
```

Require timer `active`, `theme-switch status` matching the local hour, xrdb `st.background` and gsettings `color-scheme` matching that mode. Do not treat an inactive `graphical-session.target` as a timer failure on this DDE host.
