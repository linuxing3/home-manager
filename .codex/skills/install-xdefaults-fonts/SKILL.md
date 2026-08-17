---
name: install-xdefaults-fonts
description: Use when st or X11 shows the wrong typeface, ~/.Xdefaults names JetBrainsMono Nerd Font, or fc-match falls back to Source Han Sans instead of the Nerd Font family.
---

# Install Xdefaults fonts on UOS

`modules/tui/st-theme.nix` sets:

```
st.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
```

Home Manager `pkgs.nerd-fonts.jetbrains-mono` puts the family in the Nix profile. Existing `st` windows and some X11 path lookups still miss Nix fonts, so `fc-match 'JetBrainsMono Nerd Font'` can return Source Han Sans.

## Diagnose

```sh
grep -E '^st\.font' "$HOME/.Xdefaults"
fc-match 'JetBrainsMono Nerd Font'
fc-list 'JetBrainsMono Nerd Font' file family | head
```

## System install

Copy the Nix nerd-fonts tree into the UOS system font path, then rebuild caches:

```sh
SRC=$(nix eval --raw nixpkgs#nerd-fonts.jetbrains-mono.outPath)/share/fonts/truetype/NerdFonts/JetBrainsMono
# Prefer the exact store path already on this host if nix eval is slow.
DEST=/usr/local/share/fonts/truetype/NerdFonts/JetBrainsMono
sudo install -d -m 0755 "$DEST"
sudo cp -a "$SRC"/. "$DEST"/
sudo chmod -R a+rX /usr/local/share/fonts/truetype/NerdFonts
sudo fc-cache -fs /usr/local/share/fonts
fc-cache -f
fc-match 'JetBrainsMono Nerd Font'
```

Require `JetBrainsMonoNerdFont-Regular.ttf`. Restart existing `st` windows so they reload the XLFD/fontconfig name. Keep the Home Manager package so later switches do not drop the family from the profile.

Install only families named in `.Xdefaults`. Do not replace `st.font` with a different family to hide a missing-font problem.
