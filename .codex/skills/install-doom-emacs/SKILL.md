---
name: install-doom-emacs
description: Use when installing, updating, or repairing Doom Emacs via marienz/nix-doom-emacs-unstraightened, enabling the doom-emacs-unstraightened Cachix cache, colliding with EXWM's emacs-with-packages, or rebuilding Doom on aarch64-linux.
---

# Install Doom Emacs (unstraightened)

Source: <https://github.com/marienz/nix-doom-emacs-unstraightened>. Host: `Designers` on `.#nvme-p6-phytium`. Persist in `modules/app/doom-emacs/default.nix` and enable with `my.features.home.doomEmacs` in `profiles/work/home.nix`.

## Cachix

Nix must trust the official binary cache before evaluating or building the flake. Put the same values in both places:

- Flake `nixConfig` in `flake.nix` (literal lists; Nix forbids importing `nixConfig` from another file)
- `nix.settings` on NixOS via `nix/nix-config.nix`

```text
https://doom-emacs-unstraightened.cachix.org
doom-emacs-unstraightened.cachix.org-1:O5oOlRPnmQEvVaFyuMTmthCEooHbrg54WgSLR07tmg4=
```

Pass `--accept-flake-config` on first evaluation so the flake cache is used. Then `sudo nixos-rebuild switch --flake .#nvme-p6-phytium` so `/etc/nix/nix.conf` trusts it persistently.

This cache currently publishes `x86_64-linux` and `aarch64-darwin`. On Phytium `aarch64-linux`, Emacs still builds locally; `cache.nixos.org` and `nix-community` still cover dependencies.

## Flake input

```nix
nix-doom-emacs-unstraightened = {
  url = "github:marienz/nix-doom-emacs-unstraightened";
  inputs.nixpkgs.follows = "";
};
```

Leave `nixpkgs` empty so the overlay uses the host pkgs, matching the project README.

## Home Manager

Import `inputs.nix-doom-emacs-unstraightened.homeModule`. Point `programs.doom-emacs.doomDir` at a tracked directory (`modules/app/doom-emacs/doomdir`) containing `init.el`, `packages.el`, and `config.el`. Keep mutable state in `doomLocalDir` under `xdg.dataHome` (`~/.local/share/nix-doom`). Enable `experimentalFetchTree`.

New Nix files must be `git add`ed or the flake cannot see them.

## EXWM collision

Do not put `emacsWithExwm` on `home.packages`. Both it and Doom ship `bin/ctags`. Keep EXWM Emacs only inside `exwm-session` / `exwm-nested`.

## Verification

```sh
rg -n 'doom-emacs-unstraightened' /etc/nix/nix.conf
emacs --version
doom version
```

Expected: GNU Emacs 30.2, Doom v2.2.x. Launch with `emacs` or `doom emacs`. Do not run `doom install` or `doom sync` against this store-backed config.

See `docs/doom-emacs.md`.
