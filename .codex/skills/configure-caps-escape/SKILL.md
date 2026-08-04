---
name: configure-caps-escape
description: Use when a Linux machine needs system-wide Caps Lock tap-hold remapping, TTY keyboard remapping, or a persistent Caps Lock to Escape setup with a Shift+Shift Caps Lock trigger.
---

# Configure Caps/Escape

Use `scripts/install-caps-escape install` with administrator privileges. The workflow installs a `keyd` config that makes `Caps Lock` send `Escape` when tapped, act as `Control` when held with other keys, and uses the `shift` layer so `Left Shift + Right Shift` act as Caps Lock together.

The installer writes `/etc/keyd/default.conf`, checks it with `keyd check`, and enables `keyd.service`. This is the system-wide path for both TTYs and desktop sessions. Do not use `xmodmap` or XKB options for this mapping; they cannot reliably express the tap-hold behavior across the whole machine.

Before acting, require `keyd` and `systemctl`. Verify with `scripts/install-caps-escape verify` and report service or permission failures honestly. If `keyd` exits because the host blocks realtime scheduling, treat that as a host capability issue rather than a config error.
