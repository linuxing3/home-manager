---
name: uos-desktop-bootstrap
description: Use when setting up or repairing this project’s UOS Desktop environment, including Home Manager activation, oxwm screenshots, Agenix secrets, keyboard mappings, terminal configuration, automation access, or a Hermes Gateway systemd service that loops with Python module import errors.
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

## 3. Repair oxwm screenshot capture

- Define a `screenshot-to-clipboard` helper with `pkgs.writeShellApplication` in `modules/wm/oxwm/oxwm.nix`.
- Put both `maim` and `xclip` in `runtimeInputs`; do not rely on either tool being incidentally installed or available in oxwm's inherited `PATH`.
- Capture a selected X11 region with `maim --select` and pipe it to `xclip -selection clipboard -target image/png -in`.
- Bind oxwm's screenshot key directly to `oxwm.spawn({ "screenshot-to-clipboard" })` instead of embedding a shell pipeline in `config.lua`.
- Build `.#homeConfigurations.Designers.activationPackage`, activate Home Manager, restart oxwm, and verify that an image can be pasted into an image-aware application.

## 4. Activate Home Manager

Run:

```sh
env PATH=/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin \
  home-manager switch --flake .#Designers -b hm-bak
```

The profile provides the `bat` alias, Atuin Bash/Zsh integration, `secretspec`, `.Xdefaults`, the Numtide cache settings, `agenix-env`, and the allowlisted `agent-env` wrapper. Run Alejandra and focused Home Manager evaluation before activation; treat unrelated `cachix-agent` failures separately.

## 5. Manage secrets with Agenix

- Keep sensitive values in an encrypted `.age` file, never Atuin or shell startup.
- When replacing an unavailable recipient, encrypt a new file with the generated SSH public key using `age`, validate decryption with the matching private key without printing contents, and update `security/secrets/secrets.nix` plus `security/security.nix` together.
- If old encrypted files cannot be decrypted, scope Agenix to the new file only rather than pretending migration succeeded; retain old encrypted files as recoverable backups outside the active mapping.
- Confirm the user Agenix service succeeds and the materialized runtime file is mode `0600` before exposing it.

## 6. Keep Atuin non-secret

- Use `.codex/skills/import-atuin-env/scripts/import-atuin-env` for dotenv imports. It parses safely without `source`/`eval`, skips empty assignments, and does not sync by default.
- Review a names-only secret list and remove reviewed secret names with `remove-reviewed-secrets names-file --apply`.
- Do not delete the plaintext source until Agenix decryption and approved Atuin cleanup are verified. Never run `atuin sync` for secret values.

## 7. Provide automation access

- Use `agent-env -- command` for approved automation tools (`git`, `gh`, `curl`, SSH tools, and configured AI CLIs). Secrets exist only in the child process.
- Use `agenix-env -- command` only for an explicitly authorized arbitrary command.
- Never place secret values in prompts, command arguments, logs, shell startup files, or temporary files.

## 8. Repair Hermes Gateway

Use this procedure when `hermes-gateway.service` loops in `activating
(auto-restart)` with `ModuleNotFoundError: No module named 'hermes_cli'` or
`No module named 'gateway'`.

1. Confirm the Nix package contains `hermes_cli` and `gateway`. Do not add
   `PYTHONPATH` manually: the Hermes wrapper carries the full transitive Python
   dependency set.
2. Confirm `agenix.service` is `Type=oneshot`, `Result=success`, and
   `ExecMainStatus=0`. It is normally `inactive (dead)` after success.
3. Confirm the materialized file without reading it:

   ```sh
   stat -Lc '%a %U:%G %n' \
     "$XDG_RUNTIME_DIR/agenix/api-keys-new.age"
   /home/Designers/.nix-profile/bin/agenix-env -- /usr/bin/true
   ```

   Require mode `600`, owner `Designers`, and a successful smoke test.
4. Create
   `~/.config/systemd/user/hermes-gateway.service.d/nix-wrapper.conf`:

   ```ini
   [Service]
   ExecStart=
   ExecStart=/home/Designers/.nix-profile/bin/agenix-env -- /usr/bin/env -u API_SERVER_CORS_ORIGINS -u API_SERVER_ENABLED -u API_SERVER_HOST -u API_SERVER_KEY -u API_SERVER_MODEL_NAME -u API_SERVER_PORT -u FEISHU_ALLOWED_USERS -u FEISHU_ALLOW_ALL_USERS -u FEISHU_ALLOW_BOTS -u FEISHU_APP_ID -u FEISHU_APP_SECRET -u FEISHU_CONNECTION_MODE -u FEISHU_DOMAIN -u FEISHU_ENCRYPT_KEY -u FEISHU_HOME_CHANNEL -u FEISHU_HOME_CHANNEL_NAME -u FEISHU_HOME_CHANNEL_THREAD_ID -u FEISHU_VERIFICATION_TOKEN /home/Designers/.nix-profile/bin/hermes gateway run
   ExecStopPost=
   ```

   The empty assignments replace the generated bare-Python commands. Stable
   Home Manager profile paths survive Nix store upgrades. `agenix-env` injects
   secrets only into the child process. The `env -u` list prevents global
   Agenix values from unintentionally enabling the API Server or Feishu.
5. Reload, restart, and verify:

   ```sh
   systemctl --user daemon-reload
   systemctl --user restart hermes-gateway.service
   systemctl --user is-enabled hermes-gateway.service
   systemctl --user is-active hermes-gateway.service
   systemctl --user show hermes-gateway.service \
     -p ExecStart -p Result -p ExecMainStatus -p NRestarts -p MainPID
   /home/Designers/.nix-profile/bin/hermes gateway status
   ```

   Require `enabled`, `active`, `Result=success`, `ExecMainStatus=0`, and no
   new restarts. Inspect only post-restart logs. Never print `/proc/*/environ`
   values; compare variable names if environment propagation must be checked.

## Acceptance checks

- `agenix.service` completes successfully and the expected runtime secret exists with restrictive permissions.
- `agent-env -- <approved-command>` succeeds; the parent shell has no secret variables afterward.
- Atuin contains only reviewed non-secret variables.
- `secretspec --version`, `infocmp st-256color`, and keyboard mapping checks pass.
- The oxwm screenshot helper contains resolved `maim` and `xclip` runtime dependencies, and `Mod+S` copies a selected PNG to the X11 clipboard.
- `hermes-gateway.service` uses `agenix-env` plus the Nix Hermes wrapper, omits API Server and Feishu variables, remains active, and records no new error-level logs.
- Alejandra and focused Home Manager evaluation pass; report full flake-check blockers separately from bootstrap failures.
