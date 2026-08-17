---
name: configure-caps-escape
description: Use when a Linux machine needs system-wide Caps Lock tap-hold remapping, TTY keyboard remapping, a persistent Caps Lock to Escape setup with a Shift+Shift Caps Lock trigger, or when keyd.service fails with pthread_setschedparam: Operation not permitted.
---

# Configure Caps/Escape

Use `scripts/install-caps-escape install` with administrator privileges. The workflow installs a `keyd` config that makes `Caps Lock` send `Escape` when tapped, act as `Control` when held with other keys, makes `Left Control` send `Control+B`, and uses the `shift` layer so `Left Shift + Right Shift` act as Caps Lock together.

The installer writes `/etc/keyd/default.conf`, installs a `keyd.service` drop-in that grants `LimitRTPRIO`/`LimitMEMLOCK` and cgroup RT bandwidth (`grant-rt`), checks the config with `keyd check`, and enables `keyd.service`. This is the system-wide path for both TTYs and desktop sessions. Do not use `xmodmap` or XKB options for this mapping; they cannot reliably express the tap-hold behavior across the whole machine.

Before acting, require `keyd` and `systemctl`. Verify with `scripts/install-caps-escape verify` and report service or permission failures honestly. If `keyd` still exits with `pthread_setschedparam: Operation not permitted` after the drop-in is active, treat that as a host capability issue rather than a config error.
