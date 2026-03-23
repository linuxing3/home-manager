---
name: hm-bootstrap
description: Bootstrap, validate, switch, and harden a Home Manager flake setup quickly using local scripts or a remote GitHub flake app.
---

# hm-bootstrap

Bootstrap, validate, switch, and harden a Home Manager flake setup quickly.

## Use this skill when
- The user asks to bootstrap Home Manager from a remote GitHub flake.
- The user asks for one-command install/switch/validation.
- The user asks to fix unsafe permissions in sensitive config folders.
- The user asks to prepare a machine quickly from this repo.

## Inputs
- Optional flake ref (default: `github:linuxing3/home-manager/aarch64`)
- Optional app name (default: `bootstrap`)
- Optional username (default read from `nix/username.nix`)

## Commands
- Remote one-key bootstrap:
  - `./skills/hm-bootstrap/scripts/bootstrap.sh`
- Local validation:
  - `./skills/hm-bootstrap/scripts/validate.sh`
- Local switch:
  - `./skills/hm-bootstrap/scripts/switch-local.sh`
- Permissions hardening:
  - `./skills/hm-bootstrap/scripts/harden-perms.sh`

## Workflow
1. Run validation.
2. Run switch/bootstrap.
3. If auth/secret issues appear, run permissions hardening.
4. Re-run validation.

## Expected outputs
- Home Manager generation evaluates successfully.
- `home-manager switch` completes.
- Sensitive folders have secure ownership and modes.

## Notes
- Symlink mode `777` for Home Manager-managed files is expected and not itself unsafe.
- If commit signing fails in non-interactive sessions, use `--no-gpg-sign` when committing.
