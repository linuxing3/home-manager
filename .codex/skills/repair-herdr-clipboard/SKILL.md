---
name: repair-herdr-clipboard
description: Use when herdr copy or paste is empty, logs "copied selection to clipboard" with nothing on the X11 clipboard, xclip is missing from PATH, or Ctrl+Shift+C/V does nothing in Luke Smith st.
---

# Repair herdr copy/paste

Herdr copies with `xclip --clipboard --input`, then OSC 52. Luke Smith `st` does not implement OSC 52, so a missing `xclip` looks like a successful copy and leaves the clipboard empty.

`herdr` on this host is often a `nix profile` install. Its server PATH must contain `xclip`. Home Manager `copy_on_select` does not install a clipboard tool.

Luke Smith `st` clipboard keys are **Alt+c / Alt+v** and **Alt+Shift+C/V**. Ctrl+Shift+C/V exists only after the overlay patch in `overlays/packages/st.nix`.

## Diagnose

```sh
command -v xclip || echo 'xclip missing'
xclip -version
echo "$DISPLAY"
pgrep -a herdr
tr '\0' '\n' < /proc/$(pgrep -n -f 'herdr server')/environ | awk -F= '$1=="PATH"{print}'
rtk rg -i 'copied selection to clipboard|xclip|osc' ~/.config/herdr/herdr-server.log
printf 'probe\n' | xclip -selection clipboard -in
xclip -selection clipboard -o
```

Failure is `command -v xclip` empty, or a round-trip that does not print `probe`. Do not treat the herdr log line as proof the X11 clipboard changed.

## Runtime repair

```sh
PATH=/home/Designers/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
nix profile add nixpkgs#xclip
command -v xclip
```

The running server already includes `~/.nix-profile/bin` on PATH, so a new `xclip` is visible without a session restart. If copy is still empty, restart herdr so it re-probes the tool. Do not add OSC 52 support to `st` for this bug.

## Persist

Keep `pkgs.xclip` in `modules/app/ai-agents/herdr/default.nix` `home.packages` and in `flake/devshells.nix`. Keep `[ui] copy_on_select = true` in `modules/app/ai-agents/herdr/files/config.toml`. Keep Ctrl+Shift+C/V `clipcopy`/`clippaste` bindings in `overlays/packages/st.nix`.

Activate Home Manager for the config and `st` rebuild. New `st` windows pick up Ctrl+Shift+C/V. Existing terminals keep Alt+c/v until restarted.

`home-manager switch` may still fail later on a missing `codex` activation hook. `xclip` on the user profile PATH is enough for herdr copy.

## Verify

```sh
.codex/skills/repair-herdr-clipboard/scripts/verify-herdr-clipboard
```

Require `xclip` on PATH, `DISPLAY` set, and a CLIPBOARD round-trip. After a herdr mouse selection, `xclip -selection clipboard -o` must show that text.
