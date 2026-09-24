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


## Mail / Gnus (Gmail + QQ)

| Account | Role in Gnus | Agenix secret |
| --- | --- | --- |
| `overlabor77@gmail.com` | primary `nnimap "gmail"` (bare group names) | `mail-gmail-overlabor77-pass.age` |
| `xingwenju@gmail.com` | secondary `nnimap "gmail-xingwenju"` (`nnimap+gmail-xingwenju:…`) | `mail-gmail-xingwenju-pass.age` |
| `linuxing3@qq.com` | secondary `nnimap "qq"` (`nnimap+qq:…`) | `mail-qq-pass.age` |

| Piece | Location |
| --- | --- |
| Doom `:email gnus` | `modules/app/doom-emacs/doomdir/init.el` |
| IMAP/SMTP + posting styles | `modules/app/doom-emacs/doomdir/config.el` |
| Passwords → `~/.authinfo` | `modules/app/doom-emacs/gmail.nix` + `gmail-authinfo.service` |

Use Google App Passwords / QQ **授权码** (not login passwords). Encrypt / refresh a secret from `security/secrets`.

If `agenix -e FILE` fails with `no identity matched any of the recipients`, the existing ciphertext was encrypted for old keys. Move it aside, then re-encrypt for current `secrets.nix` recipients:

```sh
cd security/secrets
mv mail-qq-pass.age mail-qq-pass.age.old-undecryptable   # only if decrypt fails
# paste the 16-char code (spaces optional), then Ctrl-D
EDITOR=tee agenix -e mail-qq-pass.age <<<"YOUR_AUTH_CODE"
# or interactively:
# agenix -e mail-qq-pass.age
git add mail-qq-pass.age secrets.nix
```

After Home Manager activates:

```sh
systemctl --user restart agenix.service gmail-authinfo.service
# ~/.authinfo should list Gmail + QQ IMAP/SMTP machines (passwords redacted locally)
```

In Doom: `M-x gnus`. Compose from the matching group so posting styles pick From/SMTP user (`m`, then `C-c C-c`). `overlabor77` uses English `[Gmail]/*` folders; `xingwenju` uses bare folders (`INBOX`, `Sent`, `Trash`, …); QQ groups are `nnimap+qq:INBOX`, `nnimap+qq:Sent Messages`, etc. Chinese-label zombies are pruned on `gnus-started-hook`.

### N Λ N O look (Gnus only)

Gnus uses Rougier-style nano faces + header-line (`nano-theme`, `nano-modeline`) without replacing Doom’s global theme. Unread is **strong**, read/cite is **faded**, subject/to are **salient**. Rebuild Doom after `packages.el` changes so those packages land.

### Forward QQ Amazon Associates → Gmail (one by one)

From Doom Gnus summary on `nnimap+qq:INBOX`:

| Key (Evil localleader = `SPC m`) | Action |
| --- | --- |
| `SPC m a l` | Limit summary to Associates / Influencer From addresses |
| `SPC m a f` | Open a forward of the current mail To: `xingwenju@gmail.com` |
| `C-u SPC m a f` | Same, original attached as MIME |
| `C-c C-c` | Send via QQ SMTP (`linuxing3@qq.com`) |

Skip KDP “Alert from Amazon” and shopping news unless you want those. Review each forward before sending.

EXWM’s `emacsWithExwm` does **not** load this Doom config — use profile `emacs` / `doom emacs` for mail.

## Font

Doom default UI font is set in `modules/app/doom-emacs/doomdir/config.el`:

```elisp
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16)
      doom-variable-pitch-font (font-spec :family "Inter" :size 16)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 22))
```

Restart Emacs (or `M-x doom/reload`) after changing size.

## Verification

```sh
emacs --version   # GNU Emacs 30.2
doom version      # doom v2.2.x
```

Launch with `emacs` or `doom emacs`. Do not run `doom install` or `doom sync`; packages are built by Nix.

Operational skill: `.codex/skills/install-doom-emacs/SKILL.md`.
