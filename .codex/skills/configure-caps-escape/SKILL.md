---
name: configure-caps-escape
description: Use when a Linux machine needs system-wide Caps Lock tap-hold remapping, TTY keyboard remapping, a persistent Caps Lock to Escape setup with a Shift+Shift Caps Lock trigger, or when keyd.service fails with pthread_setschedparam: Operation not permitted.
---

# Configure Caps/Escape

On this NixOS host persist Caps/Escape in `nixos/keyd.nix` and rebuild `.#nvme-p6-phytium`. Use `scripts/install-caps-escape install` with administrator privileges only on UOS. The mapping makes `Caps Lock` send `Escape` when tapped, act as `Control` when held with other keys, makes `Left Control` send `Control+B`, and uses the `shift` layer so `Left Shift + Right Shift` act as Caps Lock together.

The NixOS module (and the UOS installer) writes `/etc/keyd/default.conf`, grants `LimitRTPRIO`/`LimitMEMLOCK` plus cgroup RT bandwidth (`grant-rt`), and enables `keyd.service`. `[ids]` must be `*` (keyboards only, per keyd) with an explicit mouse exclude such as `-05af:413a`. `k:*` is **not** an all-keyboards wildcard; keyd treats it as a literal id and ignores every real keyboard. Do not use `xmodmap` or XKB options for this mapping; they cannot reliably express the tap-hold behavior across the whole machine.

Before acting, require `keyd` and `systemctl`. Verify with `scripts/install-caps-escape verify` (UOS) or `systemctl is-active keyd.service` plus `journalctl -u keyd` showing `DEVICE: match` for the real keyboard, not only `ignoring`. Create group `keyd` so the control socket is reachable, and grant the unit `CAP_SETGID` (without it keyd exits 255 once the group exists). If `keyd` still exits with `pthread_setschedparam: Operation not permitted` after the drop-in is active, treat that as a host capability issue rather than a config error.
