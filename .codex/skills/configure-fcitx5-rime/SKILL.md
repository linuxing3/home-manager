---
name: configure-fcitx5-rime
description: Use when oxwm Chinese input, fcitx5, or Rime luna_pinyin_simp is wrong, fcitx5-daemon fights the oxwm fcitx5 process, or fuzzy pinyin (zh/z, ch/c, sh/s, n/l, an/ang, en/eng, in/ing) needs to change.
---

# fcitx5 + Rime on oxwm

Home Manager module: `modules/wm/input/chinese-sogou.nix`, imported by `modules/wm/oxwm/oxwm.nix`. Doc: `docs/fcitx5-rime.md`.

Sogou Pinyin is not in nixpkgs. The input method is fcitx5 + Rime, schema `luna_pinyin_simp` (朙月拼音·简化字).

## One fcitx5 process

oxwm starts the editor. `modules/shared/oxwm/autostart.sh` runs `fcitx5 -d --replace` when no `/bin/fcitx5` process exists. `startx` does not put `DISPLAY` on the user systemd manager, so do not also start `fcitx5-daemon.service` (`WantedBy=graphical-session.target`).

The module sets:

```nix
systemd.user.services.fcitx5-daemon.Install.WantedBy = lib.mkForce [];
```

A second process fails with `Unable to request dbus name. Is there another fcitx already running?` and then unloads its addons. Do not `systemctl --user enable --now fcitx5-daemon.service` on this host. Do not kill the oxwm `fcitx5 -d --replace` process to "fix" the inactive unit.

Check:

```sh
systemctl --user is-enabled fcitx5-daemon.service || true
ps -u "$(id -u)" -o pid,args | awk 'BEGIN{IGNORECASE=1} /fcitx5/ && !/awk/'
```

The unit should be disabled or not wanted. One `fcitx5 -d --replace` process should remain.

## Fuzzy pinyin

Stock luna_pinyin has abbreviation and a few syllable aliases. It does not blur zh/z, ch/c, sh/s, n/l, or front/back nasals. Home Manager owns:

`xdg.dataFile."fcitx5/rime/luna_pinyin_simp.custom.yaml"` (`force = true`)

The patch replaces `speller/algebra`, so it repeats the stock abbrev/derive rules and then adds:

- `zh` = `z`, `ch` = `c`, `sh` = `s`
- `n` = `l`
- `an` = `ang`, `en` = `eng`, `in` = `ing`

After changing that file, rebuild against the Home Manager rime-data and reload fcitx5. `--build` arguments are user dir, shared data, staging dir:

```sh
rime_deployer --build \
  ~/.local/share/fcitx5/rime \
  ~/.nix-profile/share/rime-data \
  ~/.local/share/fcitx5/rime/build
fcitx5 -d --replace
```

`luna_pinyin_simp.custom` in `build/luna_pinyin_simp.schema.yaml` must be a non-zero timestamp, and the algebra must contain `derive/^([zcs])h/$1/`.

## Switches on this schema

- `Ctrl+Shift+2`: 中文 / 西文
- `Ctrl+Shift+3`: 半角 / 全角
- `Ctrl+Shift+4`: 简体 / 繁体 (`zh_simp` defaults on)
- `` ` `` plus `hspnz`: stroke reverse lookup (一丨丿丶乙)
- `/` prefixes: symbol tables (`/sx`, `/xl`, `/zy`, `/0`)

Double pinyin, terra pinyin, and luna_pinyin_fluency are installed with rime-data and are not the active schema.
