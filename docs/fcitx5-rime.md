# fcitx5 and Rime

Chinese input on oxwm is fcitx5 plus Rime. Sogou Pinyin is not packaged in nixpkgs. Home Manager owns the setup in `modules/wm/input/chinese-sogou.nix`. The repair notes are `.codex/skills/configure-fcitx5-rime/SKILL.md`.

## Process

`modules/shared/oxwm/autostart.sh` starts `fcitx5 -d --replace`. The Home Manager user unit `fcitx5-daemon.service` is kept installed for the fcitx5 package and input-method variables, but `WantedBy` is forced empty so `graphical-session.target` does not start a second daemon. Two processes contend for the same D-Bus name; the unit then exits and unloads its addons.

## Active schema

`luna_pinyin_simp` (朙月拼音·简化字), dictionary `luna_pinyin`, five candidates per page.

- Full pinyin, space as the syllable delimiter, and abbreviation (first letter; `zh`/`ch`/`sh` stay two letters).
- Syllable aliases such as `lv`/`nve`, `jv`, `un`/`uen`, `ui`/`uei`, `iu`/`iou`.
- Sentences from the dictionary. Choices are remembered in `~/.local/share/fcitx5/rime/luna_pinyin.userdb`.
- Upper case, email addresses, and URLs commit as typed.
- `Ctrl+Shift+2` Chinese/Western, `Ctrl+Shift+3` half/full width, `Ctrl+Shift+4` simplified/traditional. Simplified is the default.
- Stroke reverse lookup: `` ` `` then `h` 一, `s` 丨, `p` 丿, `n` 丶, `z` 乙.
- `/` opens the symbol tables (`/sx` math, `/xl` Greek, `/zy` bopomofo, `/0` zero forms).

Terra pinyin, double pinyin, and `luna_pinyin_fluency` ship in rime-data. They are not selected.

## Fuzzy pinyin

`xdg.dataFile."fcitx5/rime/luna_pinyin_simp.custom.yaml"` patches `speller/algebra`. The stock rules stay, and these pairs are added:

| Input | Also matches |
| --- | --- |
| zh / z | each other |
| ch / c | each other |
| sh / s | each other |
| n / l | each other |
| an / ang | each other |
| en / eng | each other |
| in / ing | each other |

Changing the patch does not affect a running Rime process until deploy:

```sh
rime_deployer --build \
  ~/.local/share/fcitx5/rime \
  ~/.nix-profile/share/rime-data \
  ~/.local/share/fcitx5/rime/build
fcitx5 -d --replace
```

Confirm `luna_pinyin_simp.custom` in `~/.local/share/fcitx5/rime/build/luna_pinyin_simp.schema.yaml` is not `0`.
