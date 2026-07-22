---
name: configure-caps-escape
description: Configure Caps Lock as Escape when pressed alone and Caps Lock when pressed with Shift across Linux virtual consoles and X11 desktop sessions. Use for system-wide Caps/Escape remapping, TTY keyboard mappings, or persistent DDE/oxwm X11 keyboard behavior.
---

# Configure Caps/Escape

Use `scripts/install-caps-escape install` with administrator privileges, then run `scripts/install-caps-escape activate` as the desktop user. The workflow provides Caps→Escape and Shift+Caps→Caps Lock through an action-based XKB definition, not `xmodmap` (which cannot implement the conditional modifier correctly).

The installer installs a `loadkeys` map and systemd service for TTYs, adds the missing XKB symbol/rules on older Debian/UOS hosts, preserves existing `XKBOPTIONS`, and installs Xsession/DDE startup hooks for X11. It is idempotent and creates `.configure-caps-escape.bak` backups before changing system-owned files.

Before acting, inspect the host and require `loadkeys`, `setxkbmap`, and `systemctl`. Do not run `setxkbmap` in Wayland sessions; use the compositor’s native XKB option instead. Verify with `scripts/install-caps-escape verify` and report authentication or missing-tool failures honestly.
