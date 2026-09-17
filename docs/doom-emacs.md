# Doom Emacs (nix-doom-emacs-unstraightened)

Installed from <https://github.com/marienz/nix-doom-emacs-unstraightened> through Home Manager.

## Ownership

| Path | Purpose |
| --- | --- |
| `flake.nix` `nixConfig` | Flake-time Cachix substituters, including `doom-emacs-unstraightened` |
| `nix/nix-config.nix` | Same caches for NixOS `nix.settings` |
| `modules/app/doom-emacs/default.nix` | Home Manager `programs.doom-emacs` |
| `modules/app/doom-emacs/doomdir/` | Tracked Doom `init.el`, `packages.el`, `config.el` |
| `profiles/work/home.nix` | `my.features.home.doomEmacs = true` |
| `modules/wm/exwm/default.nix` | EXWM wrappers only; vanilla Emacs stays off PATH |

Local mutable state: `~/.local/share/nix-doom`.

## Cachix

```text
https://doom-emacs-unstraightened.cachix.org
doom-emacs-unstraightened.cachix.org-1:O5oOlRPnmQEvVaFyuMTmthCEooHbrg54WgSLR07tmg4=
```

On this `aarch64-linux` host the cache has no Emacs closure, so Doom still compiles locally. Keep the cache enabled for x86_64 rebuilds and upstream CI artifacts.

## Verification

```sh
emacs --version   # GNU Emacs 30.2
doom version      # doom v2.2.x
```

Launch with `emacs` or `doom emacs`. Do not run `doom install` or `doom sync`; packages are built by Nix.

Operational skill: `.codex/skills/install-doom-emacs/SKILL.md`.
