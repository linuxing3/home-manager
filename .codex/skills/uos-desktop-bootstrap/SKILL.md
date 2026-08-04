---
name: uos-desktop-bootstrap
description: Use when setting up or repairing this project’s UOS Desktop environment, especially Home Manager activation, Cloudflare clients, sudo or APT privileges, DDE memory growth, AI browser tooling, nnn privileged editing, oxwm, Agenix, keyboard or terminal configuration, automation access, or Hermes Gateway service failures.
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

## 9. Configure passwordless sudo

Only install unrestricted passwordless sudo when the user explicitly requests
it. The rule grants the `Designers` account unrestricted root access:

```sudoers
Designers ALL=(ALL:ALL) NOPASSWD: ALL
```

Write the candidate to a temporary file, validate it with
`/sbin/visudo -cf`, then authenticate once to install it as
`/etc/sudoers.d/99-designers-nopasswd` with owner `root:root` and mode `0440`.
Validate both the installed file and `/etc/sudoers`, then require
`sudo -n true` to succeed.

On UOS, `pkexec` can reject a Nix-provided `SHELL` that is absent from
`/etc/shells`; retry the authenticated install with
`env SHELL=/bin/bash pkexec ...`. If no controlling terminal or Polkit agent is
available, stop at the validated candidate and request one manual authenticated
install. Never ask for, receive, or handle the user's password.

## 10. Repair Cloudflare APT on UOS 20

- Run package-list updates as root with `sudo apt-get update`; a plain
  `apt update` cannot acquire `/var/lib/apt/lists/lock` or clean APT caches.
- UOS reports the codename `eagle`, which the Cloudflare WARP repository does
  not publish. On this UOS 20, Debian 10-compatible ARM64 host, use the
  published `buster` channel only after checking both its `Release` file and
  `binary-arm64/Packages.gz` with `curl -fsSI`.
- Back up the existing WARP source, then install this exact source as
  `root:root`, mode `0644`:

  ```text
  deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ buster main
  ```

- Refresh the official WARP signing key when required, run
  `sudo apt-get update`, and verify the result with
  `apt-cache policy cloudflare-warp`.
- Keep the separate `cloudflared` tunnel repository on
  `https://pkg.cloudflare.com/cloudflared any main`. Do not interchange its
  source or key with the WARP client repository.

## 11. Set up Cloudflare clients

Treat the three Cloudflare tools as separate products:

- `cloudflared`: verify `cloudflared --version`, tunnel inventory, and its
  system service. A user configuration may reference a stale tunnel UUID that
  differs from the live named tunnel; do not redirect a hostname or origin
  without the missing routing details. Never print tunnel credential contents
  or tokens.
- `wrangler`: manage the official developer CLI in the profile's
  `networkPackages`. Run `wrangler login`, complete browser OAuth, then verify
  with `wrangler whoami`.
- `cloudflare-warp`: a Home Manager package provides `warp-cli` and `warp-svc`
  binaries but does not create a privileged persistent daemon service.
  `warp-cli status` needs the root daemon socket.

A root foreground `warp-svc` smoke test may bind
`/run/cloudflare-warp/warp_service`; stop the test process afterward and note
that it can create logs under `/var/lib/cloudflare-warp`. A successful daemon
start can still report `RegistrationMissing` or require acceptance of current
terms. Persistent WARP requires the system package and service, not just the
Home Manager package. Do not register an organization, accept terms, or connect
the VPN unless the user explicitly authorizes that state change.

## 12. Recover leaked DDE memory

Diagnose before restarting anything:

```sh
free -h
ps -eo pid,ppid,user,stat,etime,rss,comm,args --sort=-rss
systemd-cgtop -b -n 1 -m
```

Use `/proc/PID/smaps_rollup` and `/proc/PID/smaps` to distinguish RSS, PSS,
cache, and private anonymous memory. In the validated failure, long-running
`dde-lock`, `dde-dock`, and `dde-launcher` processes accumulated roughly 2 GiB
of private memory; controlled restarts recovered it.

- Terminate the launcher and confirm `com.deepin.dde.Launcher` remains
  activatable.
- Terminate the old lock process, start `/usr/bin/dde-lock -d`, and verify both
  the new process and `com.deepin.dde.lockFront`.
- Terminate the current dock and allow `/usr/bin/dde-dock-wrapper` to respawn
  it. Verify the process and `com.deepin.dde.daemon.Dock`; do not rely only on
  `com.deepin.dde.Dock`, whose ownership can race during restart.

Never close an active browser, Codex, Hermes, editor, or its `nixd` evaluators
without user authorization. Compare memory before and after, check for OOM or
new service errors, and report this as runtime recovery rather than a persistent
repository fix.

## 13. Configure agent-browser for AI agents

Keep the graphical desktop browser for OAuth while exporting the Nix-installed
headless browser for agents:

```nix
sessionVariables = {
  AI_BROWSER = lib.getExe pkgs.agent-browser;
  AGENT_BROWSER = lib.getExe pkgs.agent-browser;
  BROWSER = userSettings.browser;
};
```

Add project guidance telling AI agents to use `agent-browser` headlessly and to
load its core instructions with `agent-browser skills get core --full`. Do not
change MIME associations or `xdg-open`.

After activation, verify in a fresh login shell. A long-lived shell may retain
`__HM_SESS_VARS_SOURCED` and skip new Home Manager exports, so unset that guard
for a targeted verification. Check the pinned CLI's actual help: versions
without `read` can be tested with:

```sh
agent-browser --session bootstrap-check open https://example.com
agent-browser --session bootstrap-check get text body
agent-browser --session bootstrap-check close
```

## 14. Repair nnn privileged Helix editing

The stock `suedit` plugin invokes `sudoedit`; sudo policy may ignore `EDITOR`,
fall back to Nano, and exclude the Nix profile from `secure_path`. Configure
nnn's lowercase `s` plugin as a direct privileged Helix command using the
absolute Nix store path, and move the previous `gpgs` mapping to uppercase
`S`:

```nix
s:-!sudo ${pkgs.helix}/bin/hx \\\"\\$nnn\\\"*
S:gpgs
```

The escaping is essential: the generated Home Manager session-variable file
must contain the literal `"$nnn"` so nnn expands the selected path at runtime.
After activation, confirm there is exactly one lowercase `s` mapping, verify
`sudo <absolute-hx-path> --version`, and test with `;s` or Alt+s. `sudoedit`
still rejects directories and user-writable directory paths by design; this
mapping intentionally launches privileged Helix directly so returning from
Helix returns immediately to nnn.

## Acceptance checks

- `agenix.service` completes successfully and the expected runtime secret exists with restrictive permissions.
- `agent-env -- <approved-command>` succeeds; the parent shell has no secret variables afterward.
- Atuin contains only reviewed non-secret variables.
- `secretspec --version`, `infocmp st-256color`, and keyboard mapping checks pass.
- The oxwm screenshot helper contains resolved `maim` and `xclip` runtime dependencies, and `Mod+S` copies a selected PNG to the X11 clipboard.
- `hermes-gateway.service` uses `agenix-env` plus the Nix Hermes wrapper, omits API Server and Feishu variables, remains active, and records no new error-level logs.
- Any requested passwordless-sudo rule passes `visudo` and `sudo -n true`; otherwise no sudoers file is installed.
- Cloudflare APT updates without an `eagle` repository error, and WARP has an ARM64 `buster` candidate.
- Each requested Cloudflare client passes its own verification; package-only WARP installs are not reported as daemon setup.
- Restarted DDE components own their expected D-Bus names, produce no new errors, and reduce measured private memory.
- `AI_BROWSER` and `AGENT_BROWSER` resolve to Nix `agent-browser`, while `BROWSER` remains the graphical desktop browser.
- The activated nnn mapping retains literal `"$nnn"`, launches the absolute Helix path through sudo, and returns to nnn after exit.
- Alejandra and focused Home Manager evaluation pass; report full flake-check blockers separately from bootstrap failures.
