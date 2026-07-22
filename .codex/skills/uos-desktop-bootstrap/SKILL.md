---
name: uos-desktop-bootstrap
description: Bootstrap and repair this project’s UOS Desktop environment on Debian/UOS-style systems using Home Manager, Agenix, Atuin, SecretSpec, XKB keyboard mappings, st terminfo, and secure AI/CLI automation. Use when setting up a new UOS host, restoring this desktop profile, or applying the project’s complete workstation configuration.
---

# UOS Desktop Bootstrap

Apply changes in this order and verify each boundary before continuing.

## 1. Inspect and protect prerequisites

- Confirm the host is UOS/Debian-like, the active user is `Designers`, and the active flake profile is `work`.
- Never print or commit plaintext secret values. Preserve existing user edits and use Home Manager backups (`-b hm-bak`).
- Ensure `~/.ssh/id_ed25519` exists with mode `0400`; its public key must be an Agenix recipient before it can decrypt secrets.
- Remember that this standalone Home Manager flake cannot grant daemon-level Nix trust by itself; system Nix configuration may still need root changes.

## 2. Apply system-level UOS settings

- Configure `st-256color` with `tic -x` using the pinned `st.info` source from the project’s `st` package.
- Install the project-local `configure-caps-escape` skill’s system mapping: TTY `loadkeys` plus action-based XKB for X11/DDE/oxwm. Do not use `xmodmap`; it cannot implement Shift-sensitive Caps behavior correctly. Wayland compositors must use their native XKB option.
- Verify `infocmp st-256color`, the console map, and the X11 keymap after authentication.

## 3. Activate Home Manager

Run:

```sh
env PATH=/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin \
  home-manager switch --flake .#Designers -b hm-bak
```

The profile provides the `bat` alias, Atuin Bash/Zsh integration, `secretspec`, `.Xdefaults`, the Numtide cache settings, `agenix-env`, and the allowlisted `agent-env` wrapper. Run Alejandra and focused Home Manager evaluation before activation; treat unrelated `cachix-agent` failures separately.

## 4. Manage secrets with Agenix

- Keep sensitive values in an encrypted `.age` file, never Atuin or shell startup.
- When replacing an unavailable recipient, encrypt a new file with the generated SSH public key using `age`, validate decryption with the matching private key without printing contents, and update `security/secrets/secrets.nix` plus `security/security.nix` together.
- If old encrypted files cannot be decrypted, scope Agenix to the new file only rather than pretending migration succeeded; retain old encrypted files as recoverable backups outside the active mapping.
- Confirm the user Agenix service succeeds and the materialized runtime file is mode `0600` before exposing it.

## 5. Keep Atuin non-secret

- Use `.codex/skills/import-atuin-env/scripts/import-atuin-env` for dotenv imports. It parses safely without `source`/`eval`, skips empty assignments, and does not sync by default.
- Review a names-only secret list and remove reviewed secret names with `remove-reviewed-secrets names-file --apply`.
- Do not delete the plaintext source until Agenix decryption and approved Atuin cleanup are verified. Never run `atuin sync` for secret values.

## 6. Provide automation access

- Use `agent-env -- command` for approved automation tools (`git`, `gh`, `curl`, SSH tools, and configured AI CLIs). Secrets exist only in the child process.
- Use `agenix-env -- command` only for an explicitly authorized arbitrary command.
- Never place secret values in prompts, command arguments, logs, shell startup files, or temporary files.

## Acceptance checks

- `agenix.service` completes successfully and the expected runtime secret exists with restrictive permissions.
- `agent-env -- <approved-command>` succeeds; the parent shell has no secret variables afterward.
- Atuin contains only reviewed non-secret variables.
- `secretspec --version`, `infocmp st-256color`, and keyboard mapping checks pass.
- Alejandra and focused Home Manager evaluation pass; report full flake-check blockers separately from bootstrap failures.
