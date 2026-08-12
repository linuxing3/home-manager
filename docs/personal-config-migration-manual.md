# Personal configuration migration manual

Status: implemented on 2026-08-11. Home Manager owns static non-secret files,
merges declared defaults into mutable application files, and declares the five
previously unmanaged AI services. No source config, credential, secret, skill
checkout, or executable was deleted.

Inventory snapshot: 2026-08-11, user `Designers`, UOS on `aarch64-linux`, Home
Manager profile `work`.

## Goal

Move durable personal configuration into this Home Manager flake while keeping
credentials encrypted, application-owned state writable, and Git-managed
projects outside the migration. Perform the work in small batches so each
application can be verified and rolled back independently.

## Implemented optimized defaults

The implementation is split between
`modules/app/personal-configs/default.nix` and
`modules/app/user-services/default.nix`, imported by the `work` profile.

| Area | Implemented ownership |
| --- | --- |
| Static agent config | Home Manager owns Codex global rules/hooks, Claude and Cursor Herdr hooks, Cursor/Codeium/Kiro token-free MCP declarations, Hermes `SOUL.md`, Herdr UI/key settings, and Pi-compatible supporting files. |
| Mutable agent config | Activation performs recursive semantic merges into Codex, Claude, Cursor, Hermes, Pi, CC Switch, and CLIProxyAPI files. Unknown, credential, authentication, provider-account, cache, and application-generated fields remain intact. |
| CLI/GUI config | Atuin uses native `programs.atuin.settings`; Glow, Television, Zellij, Herdr, and SMPlayer HiDPI settings are static; stable SMPlayer and gcloud defaults are merged into writable files. |
| Cloudflare routing | Only reviewed ingress routes are merged. Tunnel identifiers and credential-file paths remain in the local writable YAML and never enter the flake. |
| Hermes cron | The three intentional jobs have a sanitized desired-state manifest and the explicit `hermes-cron-sync` command. IDs, run state, errors, timestamps, origin identities, and delivery IDs are excluded. Existing delivery targets are preserved; a new-machine restore requires local `HERMES_CRON_DELIVER`. Activation never rewrites the jobs database. |
| Herdr plugins | `herdr-plugin-sync` restores GitHub plugins from source identifiers only and refuses to run outside `HERDR_ENV=1`. The local palette remains inventory-only. Plugin Git checkouts are not managed. |
| Claude marketplace | `claude-marketplace-sync` idempotently declares the official Anthropic marketplace when explicitly run. Activation does not perform network installation. |
| User services | Cloudflared Cursor tunnel, Collie, Cursor-to-OpenAI, Hermes dashboard, and Hermes gateway are Home Manager user units with stable launch paths, restrictive umasks, current restart behavior, and existing local environment files. |
| Small scripts | The Cursor shim is a `writeShellApplication` with recursion protection, explicit executable checks, and the existing Cursor Agent fallback. Other small or large entries remain excluded according to the inventory. |

Before changing any writable application file, activation creates a
non-overwriting sibling backup with suffix `.hm-bak` when one is not already
present. Home Manager is also activated with `-b hm-bak`, so replaced static
files and old regular user units are retained rather than deleted.

The following candidates intentionally remain unmanaged:

- Bottom's current file contains only the shipped commented template and no
  personal values.
- No Grok durable config exists at the verified paths.
- Copilot's current file says it is automatically managed and contains only a
  first-launch timestamp.
- CC Switch WebDAV credentials, sync status, and migration counters remain
  mutable local state.
- gcloud account/project identity values remain in the writable local profile;
  only telemetry denial is declared.
- Browser profiles, Obsidian, Helix, DDE/Deepin, nnn, every Git checkout, and
  all data-only roots remain excluded.

The inventory covers:

1. AI agent and AI tool configuration, excluding temporary and data-only files.
2. CLI and GUI configuration only when the application is installed by Home
   Manager or `nix profile`.
3. Credentials, private keys, authentication tokens, and OAuth material.
4. User services already installed by Home Manager, plus unmanaged AI-tool
   units that should become Home Manager modules.
5. AI skills as installation instructions in the project-local Codex UOS
   bootstrap skill, not copied skill bodies.
6. Small, independent scripts in `~/.local/bin`; compiled programs and generated
   entry points are excluded.

## Hard exclusions

- Do not migrate `~/.config/helix` or any Helix file. It is intentionally a
  standalone Git repository.
- Do not migrate DDE, Deepin, Sogou, desktop keyring, or other desktop-managed
  state. In particular, exclude `~/.config/deepin`, `~/.deepin*`, DDE user
  units, `~/.local/share/deepin-keyrings-wb`, and the UOS Vault files.
- Do not copy files from a Git worktree, Git submodule, plugin checkout, or
  dependency checkout. Examples found during the scan include
  `~/.config/helix`, `~/.config/nnn`, `~/.agents/story-to-handdrawn-video`,
  `~/.config/herdr/plugins/github/*`, Grok plugin checkouts, and Neovim plugin
  checkouts. Record an installer or source reference instead.
- Do not migrate histories, sessions, logs, caches, databases, lock files,
  telemetry, generated models, browser profiles, downloaded executables,
  `node_modules`, backups, or temporary files.
- Do not commit plaintext credentials, OAuth JSON, private keys, passwords,
  bearer tokens, environment files containing secrets, or decrypted Agenix
  output.
- Do not turn mutable application files into read-only Nix-store symlinks.

## Ownership rules

Use these mechanisms consistently:

| File type | Home Manager mechanism |
| --- | --- |
| Immutable, non-secret config | `xdg.configFile` or `home.file` |
| Config supported by Home Manager | The relevant `programs.*` or `services.*` option |
| Generated script | `pkgs.writeShellApplication` or `pkgs.writeShellScriptBin` with explicit runtime dependencies |
| Static secret consumed read-only | Agenix `age.secrets`, referenced by its runtime path |
| Mutable credential or refresh-token file | Login/bootstrap runbook, or an Agenix seed copied once to a mode `0600` mutable file |
| User service | `systemd.user.services`, `.timers`, `.paths`, or `.sockets` |
| Plugin or skill checkout | Installer declaration and validation only; never `home.file` over the checkout |
| Pure application data | Backup/sync policy outside Home Manager |

For mutable files, an activation step may create a parent directory and copy a
decrypted seed only when the destination is absent. It must not overwrite a
newer refresh token on every activation. Use `UMask=0077` for services that
create credentials.

## Current package boundary

The independent `nix profile` contains the following configuration-relevant
applications: Agent Browser, Bitwarden CLI, CC Switch, Claude Code,
CLIProxyAPI, Cloudflare CLI, Codex, Cursor Agent, Google Cloud SDK, Herdr,
Hermes Agent, Pi, Starship, tmux, tmuxai, Zellij, and Zsh. Node.js and the
remaining profile entries are runtimes or have no personal config candidate.

The active Home Manager profile provides the shell, Git/GitHub tooling, Atuin,
Bottom, Glow, LazyGit, Neovim, nnn, oxwm, Ranger, rclone, RTK, SMPlayer,
Television, Chromium, media tools, and supporting command-line packages.

Duplicate `nix profile` entries for Zellij and Zsh were observed. Clean those
only after configuration migration and command-resolution checks; package
cleanup is not part of this plan.

## Migration matrix: AI agents and tools

### Codex

Migrate:

- `~/.codex/config.toml`
- `~/.codex/AGENTS.md`
- `~/.codex/hooks.json`
- `~/.codex/herdr-agent-state.sh`
- The RTK installation declaration that produces `~/.codex/RTK.md`

Keep `config.toml` writable only if Codex changes it at runtime; otherwise
render it from `modules/app/agent-tools/default.nix`. Preserve the existing
`[tui] vim_mode_default = true` setting. Keep RTK setup idempotent and retain
the declarative telemetry denial already in that module.

Do not migrate `auth.json` as plaintext. It was observed with mode `0644`, so
the credential phase must either re-authenticate Codex or materialize an
encrypted bootstrap copy at mode `0600`. Exclude history, shell snapshots,
SQLite files, memories, goals, logs, queues, model caches, sessions, and
temporary plugin caches.

### Claude Code

Migrate `~/.claude/settings.json`, the Herdr hook script, and the marketplace
installation declarations. Treat `~/.claude.json` as a mixed config/auth file:
extract only reviewed non-secret preferences into Home Manager and restore
authentication through the supported login flow or an encrypted mutable seed.
Exclude history, sessions, cleanup timestamps, plugin caches, and generated
state.

### Cursor Agent, Codeium, Copilot, and Kiro

Migrate the following non-secret configuration after field-by-field review:

- `~/.cursor/cli-config.json`
- `~/.cursor/hooks.json`
- `~/.cursor/mcp.json`
- `~/.cursor/herdr-agent-state.sh`
- `~/.codeium/mcp_config.json`
- `~/.copilot/config.json`
- `~/.kiro/settings/mcp.json`

Treat Cursor authentication as a secret. Exclude Cursor project state,
tracking databases, statistics caches, chat/session data, and downloaded
agent binaries. MCP files must not embed tokens; configure MCP commands to use
`agent-env` or another child-process-only secret wrapper.

### Grok

Migrate `~/.grok/config.toml`, `trusted_folders.toml`, hook declarations,
hook scripts, and user-created rules such as the RTK rule. Treat `auth.json` as
a credential. Exclude bundled documentation and personas, downloads, vendor
binaries, worktree databases, sessions, model caches, memory traces, copy
buffers, relocation state, and plugin Git checkouts.

### Hermes Agent

Migrate:

- `~/.hermes/config.yaml`, after separating embedded secrets
- `~/.hermes/SOUL.md`
- Intentional cron definitions from `~/.hermes/cron/jobs.json`
- The declarative installation of the RTK and Herdr-state plugins

Treat `~/.hermes/.env`, `auth.json`, and `shared/nous_auth.json` as secrets.
Cron definitions are mutable application config: export a reviewed desired
job specification and apply it through Hermes commands rather than symlinking
the live jobs database/file. Exclude databases, gateway state, pairing state,
memories, histories, logs, caches, response stores, model catalogs, and LSP
runtime files.

### Herdr

Migrate `~/.config/herdr/config.toml`, reviewed host-specific settings from
`config.efwmc.toml`, and the desired plugin identifiers represented by
`plugins.json`. Exclude `session.json`, logs, release notes, lock files, and all
plugin Git checkouts.

Do not manage generated Cloudmanic project TOMLs directly. Keep
`modules/tui/nnn-herdr-sync.nix` and its generator as the declarative source.
Herdr plugin installation or control must be run from a Herdr-managed Codex
pane with `HERDR_ENV=1`; Home Manager activation should not drive the Herdr
server.

### Pi

Migrate `~/.pi/agent/settings.json`. Treat `~/.pi/agent/auth.json` as a mutable
credential and exclude the model store and sessions. Preserve the existing
UOS loader compatibility shim in `modules/app/agent-tools/default.nix` until
the upstream ARM64 package starts normally without it.

### CC Switch

Migrate `~/.cc-switch/settings.json` only. Exclude its SQLite database,
write-ahead logs, locks, scan cache, session pages, and backups.

### CLIProxyAPI

Keep the already-declared service in
`modules/app/cli-proxy-api/default.nix`. Migrate a sanitized
`~/.cli-proxy-api/config.yaml`; move any embedded secrets to Agenix. Treat the
provider account JSON files as mutable credentials and exclude the generated
management page and runtime state. Continue using the stable
`~/.nix-profile/bin/cli-proxy-api` executable; do not add a flake input solely
for this service.

### Skill-only and data-only agent roots

Many other agent homes currently contain only shared skill links or no durable
config at the scanned depth, including Aider Desk, Augment, Autohand, Bob,
OpenClaw, Qoder, Trae, Vibe, Zcode, Zencoder, and similar roots. Do not create
empty Home Manager modules for them. They are handled by the skill installer
section below. Re-scan a root before adding it later.

## Migration matrix: CLI and GUI applications

### Candidate non-secret configuration

| Application | Live path | Action |
| --- | --- | --- |
| Atuin | `~/.config/atuin/config.toml` | Convert reviewed settings to `programs.atuin.settings`; keep databases out of Home Manager. |
| Bottom | `~/.config/bottom/bottom.toml` | Add a focused module or `xdg.configFile`. |
| Glow | `~/.config/glow/glow.yml` | Add a focused `xdg.configFile`. |
| Television | `~/.config/television/config.toml` | Add a focused module; preserve writable cable/runtime directories. |
| Zellij | `~/.config/zellij/config.kdl` | Migrate the active file; exclude `.bak`. |
| SMPlayer | `smplayer.ini`, `hdpi.ini` | Migrate stable preferences only. Exclude playlists, favorites, radio/TV lists, per-file state, and `player_info.ini`. |
| Bash private extra | `~/.config/bash/extra/private.bash` | Split PATH/non-secret shell logic from credentials before migration. |
| Google Cloud SDK | `~/.config/gcloud/configurations/*` | Migrate non-secret defaults only; credentials use the credential plan. |
| Cloudflared | `~/.cloudflared/config.yml`, reviewed auxiliary YAML | Render non-secret tunnel routing separately from credentials. |

### Already declarative or generated

- Git XDG config, ignore rules, GPG agent integration, and GitHub CLI config are
  managed by `modules/app/git/git.nix`. Review the legacy `~/.gitconfig` by key
  name and retire it only after the effective Git config is identical.
- Ranger, Neovim, oxwm, RTK, the Pi shim, Nix settings, `.Xdefaults`, and shell
  startup are already Home Manager-managed.
- LazyGit config is already a Nix-store symlink; ignore its backup file.
- The `fusermount3` compatibility script is already declared in
  `modules/app/rclone/default.nix`.

### No config candidate or excluded state

- No durable config candidate was found for Agent Browser, conversation-tk,
  Starship, tmux, or mpv.
- `~/.config/tmuxai/tmuxai.log` is data only.
- Chromium and other browser profile directories are mutable application data;
  migrate preferences through supported policies or sync, never by linking the
  profile directory into the Nix store.
- Obsidian data is not included in this Home Manager migration.
- `~/.config/nnn` is a Git repository and is excluded even though nnn is
  installed by Home Manager.

## Credential migration plan

The current Agenix setup manages `security/secrets/api-keys-new.age` and uses
`~/.ssh/id_ed25519` as its decryption identity. Extend the existing scheme; do
not introduce a second plaintext secret system.

### Credential inventory

| Class | Paths or patterns | Required handling |
| --- | --- | --- |
| SSH private keys | `~/.ssh/id_ed25519`, `~/.ssh/id_rsa` | Keep an offline encrypted backup. The identity that decrypts Agenix cannot depend solely on itself being restored by Agenix. |
| SSH public config | `~/.ssh/config`, `known_hosts`, `authorized_keys`, public keys | Review and manage non-secret policy separately; do not publish host/user details casually. |
| GPG secret material | `~/.gnupg/private-keys-v1.d/*`, revocation certificates | Export an encrypted recovery backup and document an import bootstrap. Never create raw private-key `home.file` entries. |
| Agent authentication | Codex, Claude, Cursor, Grok, Hermes, Pi, CLIProxyAPI account JSON | Prefer supported login. If offline restore is required, use encrypted one-time seeds and mode `0600` mutable destinations. |
| API environment files | `~/.hermes/.env`, `~/.config/bash/extra/private.bash`, `~/.config/cursor-to-openai.env` | Move values to Agenix; leave only child-process wrappers and non-secret shell logic in Home Manager. |
| CNB | `~/.cnb/token` | Encrypt or re-run device login; retain directory mode `0700` and token mode `0600`. |
| GitHub CLI | `~/.config/gh/hosts.yml` | Prefer `gh auth login`; otherwise restore as a mutable encrypted seed. |
| Bitwarden CLI | `~/.config/bitwarden/env`, `~/.config/Bitwarden CLI/data.json` | Encrypt reviewed environment values. Prefer login/unlock for the mutable CLI data file. |
| rclone | `rclone.conf`, OAuth client JSON files | Encrypt the configuration and client credentials. Materialize a writable mode `0600` config because refresh tokens may change. |
| Cloudflared | certificate PEM, tunnel credential JSON, access/token files | Use separate Agenix secrets with mode `0600`; reference runtime secret paths from declarative services. Do not print tunnel IDs or tokens. |
| Google Cloud SDK | ADC JSON, credentials/access-token databases | Prefer `gcloud auth login` and ADC login. Do not symlink SQLite databases; use an encrypted ADC seed only when required. |
| Atuin | `~/.local/share/atuin/key` | Back up/encrypt the key separately. Histories and databases remain data, not Home Manager config. |
| Desktop/browser credentials | generic keyring, Chromium/Brave/other login stores, PKI/NSS databases | Use vendor sync, export, re-enrollment, or an encrypted archive outside the flake. Do not manage mutable browser databases with Home Manager. |

Two permissions require correction during the credential phase, after a safe
backup: `~/.codex/auth.json` and
`~/.config/bash/extra/private.bash` were observed as mode `0644`. Do not change
them in the planning-only commit.

### Agenix implementation sequence

1. Make an inventory containing secret names and destination paths only.
2. Decide whether each item is static, mutable, or login-recoverable.
3. Add one logically grouped `.age` file at a time under `security/secrets/`.
4. Add recipients and attributes in `security/secrets/secrets.nix` without
   printing public identity details in logs or documentation.
5. Reference the secret through `config.age.secrets.<name>.path`.
6. For mutable seeds, copy only when absent, set mode `0600`, and never replace
   a refreshed credential during activation.
7. Test decryption with a command that prints no content, then test the owning
   application with a status/whoami command that prints no token.
8. Remove the plaintext source only after an encrypted backup, a fresh-login
   test, and explicit approval.

## One-key encrypted credential backup and restore

Home Manager installs `credential-vault` from
`modules/app/credential-backup/`. Running it without arguments opens an action
menu for backup, listing, or restoring. The command streams credential
archives to InfinityCloud WebDAV through an rclone crypt remote. Credentials
can be read from Bitwarden or entered for the current run; password prompts
show `*` indicators and values are never echoed or stored by the script.
Neither a plaintext archive nor an rclone config containing credentials is
written to disk.

The interactive endpoint menu defaults to
`https://kurio.infini-cloud.net`. The second choice accepts another URL. For
non-interactive use, set `CREDENTIAL_VAULT_WEBDAV_URL`; otherwise a URL saved
in Bitwarden is used, falling back to the same default.

### Bitwarden preparation

Create or update a Bitwarden login item named `kurio.infini-cloud.net`. If that
exact default is absent, the command searches for a unique login item whose
name contains `InfiniCLOUD` or `InfinityCloud`, preferring a name that also
contains `WebDAV`. It never prints matching item contents. The login item must
contain its username and password; a stored encryption password is strongly
recommended:

| Bitwarden property | Purpose |
| --- | --- |
| Login username | InfinityCloud WebDAV username |
| Login password | InfinityCloud WebDAV password |
| Hidden custom field `crypt_password` | Separate, stable rclone crypt password; otherwise it is prompted each run |

Optional custom fields are `webdav_url` (a saved custom endpoint),
`webdav_vendor` (default `other`), `remote_path` (default
`credential-backups`), and hidden `crypt_password2` for additional
filename-encryption salt. Never reuse the WebDAV password as
`crypt_password`. Losing or changing the crypt fields makes old archives
unreadable, so retain them in Bitwarden history or another independent
recovery mechanism.

The item name can be overridden without exposing its contents:

```sh
CREDENTIAL_VAULT_BW_ITEM='another item name' credential-vault backup
```

An explicit override is resolved strictly as an exact Bitwarden item name or
ID; fuzzy discovery is used only for the default.

Bitwarden must already be logged in. If it is locked, `credential-vault` uses
its own masked local prompt and passes the master password to the Bitwarden
child process through `--passwordenv`, never through command arguments. It
relocks the vault when the operation ends. A fresh-machine restore still
requires independent access to the Bitwarden account; backing up Bitwarden's
local data file does not replace that bootstrap requirement.

Choose `Enter credentials for this run` to bypass Bitwarden. The WebDAV
username, masked password, and a separately confirmed backup-encryption
password remain memory-only. The same encryption password must be supplied on
future list and restore operations; save it independently, preferably as the
hidden Bitwarden field `crypt_password`.

### Commands

```sh
# Open the interactive action, authentication, and endpoint menus.
credential-vault

# Create, upload, download-verify, and authenticate an encrypted backup.
credential-vault backup

# List decrypted backup names without exposing archive contents.
credential-vault list

# Validate, create a pre-restore backup, prompt, then restore the latest backup.
credential-vault restore latest

# Non-interactive apply after the caller has reviewed the target.
credential-vault restore latest --yes

# Restore an explicitly selected name returned by `list`.
credential-vault restore credential-backup-v1-HOST-UTC_TIMESTAMP.tar
```

`restore` accepts only regular version-1 backup names. It will not restore a
pre-restore snapshot directly. It rejects absolute paths, parent traversal,
and archive entries outside the credential allowlist. Restore extracts into a
mode `0700` runtime staging directory, creates and verifies a new encrypted
pre-restore backup when credential files already exist, then copies the staged
files into `HOME` and hardens key credential modes. On an empty new home, it
reports that there is nothing to snapshot and proceeds with the restore. It
does not stop agents, browsers, or services; close or pause applications that
may rewrite credential databases before running an important restore.

### Included credential files

Missing paths are skipped. Existing directories are archived recursively.
The encrypted backup includes every credential path or class identified in
this manual's credential inventory:

- SSH private keys, public keys, `config`, `known_hosts`, and
  `authorized_keys`.
- GPG private-key and revocation directories, public keyring, trust database,
  and SSH-control file.
- Codex, Claude, Cursor, Grok, Hermes, Pi, and CLIProxyAPI authentication
  files, including root-level CLIProxyAPI account JSON files.
- Hermes, Bash-private, and Cursor-to-OpenAI environment files.
- CNB token, GitHub CLI hosts file, Bitwarden environment and local CLI data,
  rclone config and OAuth client JSON, Google Cloud ADC and credential/token
  databases, and the Atuin encryption key.
- Cloudflared certificate, tunnel credential JSON, and access/token files.
- The generic user keyring and the user's PKI/NSS directory. DDE/Deepin
  keyrings remain excluded.
- Chromium, Brave, Google Chrome, and QAX Browser `Local State` and per-profile
  `Login Data` files when present. Other browser cache, history, cookies, and
  profile data remain excluded.

The archive is stored below a host-specific directory on the rclone crypt
remote. Both content and remote filenames are encrypted. The command performs
a full download/decrypt/tar validation after every upload and never prunes old
backups automatically.

## Offline USB KeyVault plan

This is the offline recovery copy for root credentials. It complements the
InfinityCloud archive; it does not replace it. Keep the USB disconnected
except during backup, verification, or recovery.

### Verified host inventory and destructive gate

The 2026-08-11 read-only scan found one removable candidate:

| Property | Observed state |
| --- | --- |
| Device | `/dev/sdb` at the time of the scan; device names can change |
| Hardware | SanDisk Ultra, 14.9 GiB, USB, removable |
| Existing content | Four DOS partitions from an ISO image |
| Active mount | `/dev/sdb3` mounted read-only as `ISOIMAGE` |

Repartitioning this disk destroys the existing installer. Before every
initialization, repeat `lsblk` and `fdisk -l`, resolve a stable
`/dev/disk/by-id/usb-*` path, and verify that it still maps to the same
removable model and size. Never infer the target from `/dev/sdb` alone. Stop
unless the user explicitly confirms destruction of the currently observed
device after reviewing those results.

The current recovery material is small:

- SSH has Ed25519 and RSA private/public pairs. The Agenix identity is the
  mode-`0400` `~/.ssh/id_ed25519`; preserving it is mandatory for decrypting
  the active Agenix secrets.
- GPG has one signing/certification-capable Ed25519 master secret key, one
  encryption subkey, two private-key files, and one existing revocation file.
  Key identifiers and user IDs are intentionally omitted here.
- No standalone SOPS/age identity exists at the standard paths. Do not create
  an unused age identity during this backup. Record that Agenix uses the SSH
  identity and place its public key beside the SSH recovery copy.
- `cryptsetup`, `fdisk`, `wipefs`, `partprobe`, `mkfs.ext4`, GPG, SSH tooling,
  and checksum tooling are already available. `age` is absent but is not
  required for the current SSH-backed Agenix design.

### Intended encrypted layout

```text
LUKS2 partition
└── ext4 label KEYVAULT
    ├── ssh/
    ├── gpg/
    ├── age/
    ├── recovery/
    └── checksums/
```

Use `/mnt/keyvault` only while the mapper is open. The mount root and the
`ssh`, `gpg`, `age`, and `recovery` directories must be mode `0700`.

### Initialization sequence

Run this phase only after the destructive gate is approved. Enter LUKS
passphrases through `cryptsetup`'s local terminal prompt; never put them in a
shell argument, environment file, documentation, or chat.

1. Resolve and record the exact `/dev/disk/by-id/usb-*` disk path and its
   current partition child. Re-check `TRAN=usb`, `RM=1`, model, size, and mount
   sources immediately before modifying it.
2. Unmount every partition belonging to that exact disk. Require `findmnt` to
   show no remaining source from the disk.
3. Run `wipefs -a` against the resolved whole-disk path, create a GPT, and
   create one partition from 1 MiB to 100 percent. Run `partprobe`, resolve the
   new by-id `-part1` path, and verify it before continuing.
4. Format only that partition with `cryptsetup luksFormat --type luks2`.
   Require an explicit uppercase `YES` confirmation and a dedicated random
   multiword passphrase.
5. Open it as mapper `keyvault`, format `/dev/mapper/keyvault` as ext4 label
   `KEYVAULT`, mount it at `/mnt/keyvault`, assign the mount root to the active
   user, and set mode `0700`.
6. Create the standard directory layout and verify that the filesystem source
   is `/dev/mapper/keyvault`, not an internal disk.

Do not add the volume to `/etc/fstab` or auto-unlock configuration. Its safety
model requires deliberate insertion, local passphrase entry, and offline
storage.

### Backup contents

#### SSH and Agenix

Copy these files without following unrelated repositories or Home
Manager-managed configuration:

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
~/.ssh/known_hosts
~/.ssh/authorized_keys
```

Do not copy `~/.ssh/config`; its policy belongs in Home Manager. Set private
keys to `0600`, public keys to `0644`, `known_hosts` to `0644`, and
`authorized_keys` to `0600`. Add `age/README.txt` stating that the active
Agenix identity is the backed-up Ed25519 SSH key. Do not print or copy public
identity details into this repository.

#### GPG

Resolve the sole master fingerprint into a shell variable without printing it,
and abort unless exactly one master secret key is present. Export directly to
the mounted vault:

- armored public key as `gpg/public.asc`, mode `0644`;
- complete armored secret keys as `gpg/master-secret.asc`, mode `0600`;
- armored secret subkeys as `gpg/subkeys-secret.asc`, mode `0600`;
- ownertrust as `gpg/ownertrust.txt`, mode `0600`;
- the existing revocation file under `gpg/revocation/`, mode `0600`.

Use local GPG pinentry for protected-key export. Never pass a GPG passphrase on
the command line. Preserve the existing revocation certificate instead of
generating an unnecessary replacement during an automated run.

#### Recovery documentation

Create a plaintext `recovery/README.txt` inside the encrypted filesystem with
commands for:

- locating the LUKS partition by UUID and opening mapper `keyvault`;
- mounting and safely closing the vault;
- restoring SSH files and their modes;
- importing GPG public, complete secret, and ownertrust exports;
- restoring the Agenix SSH identity before attempting Home Manager secret
  activation;
- running all verification checks before trusting restored keys.

Record the LUKS UUID and ext4 UUID in `recovery/` after formatting. UUIDs are
identifiers, not unlock credentials, but do not use UUID alone as proof that a
destructive target is correct.

### Integrity and recovery tests

Generate `checksums/SHA256SUMS` over files under `ssh`, `gpg`, `age`, and
`recovery`, using null-delimited sorted paths. Run `sha256sum -c` immediately
and again whenever the vault is opened.

Verification is required before the USB is accepted:

1. For each SSH private key, derive its public key into a protected temporary
   file and compare it with the backed-up `.pub` key. Remove only the exact
   temporary file afterward.
2. Create a mode-`0700` temporary `GNUPGHOME`, import `public.asc`,
   `master-secret.asc`, and `ownertrust.txt`, then verify that both `sec` and
   `ssb` records exist. Do not print user IDs or secret packets in logs.
3. Test Agenix decryption with the restored SSH identity against a disposable
   copy or a command that emits no secret content.
4. Re-run the checksum manifest after all tests.

### Close and physical recovery

Run `sync`, unmount `/mnt/keyvault`, close mapper `keyvault`, confirm both the
mount and mapper are absent, and power off the exact whole USB disk with
`udisksctl` before unplugging it.

After USB A passes recovery tests:

- initialize USB B independently and keep it at another physical location;
- add a second LUKS passphrase in a separate key slot and keep its paper
  recovery copy away from both USB devices;
- create a LUKS header backup and store it on USB B or another separately
  encrypted offline medium. A header backup stored only inside USB A cannot
  recover USB A from header damage;
- schedule a periodic insert, checksum, restore-test, close, and power-off
  drill.

### Execution gates

- [x] Read-only device and key inventory completed.
- [ ] User confirms destruction of the currently observed SanDisk Ultra.
- [ ] Exact by-id whole-disk and partition paths revalidated immediately before wipe.
- [ ] LUKS2/ext4 initialization completed through local hidden prompts.
- [ ] SSH, GPG, revocation, ownertrust, and Agenix recovery material copied.
- [ ] Checksums and isolated SSH/GPG/Agenix recovery tests pass.
- [ ] Vault is unmounted, mapper closed, USB powered off, and physically removed.
- [ ] Second USB, separate recovery passphrase, and external LUKS header backup completed.

## User service migration

### Already installed by Home Manager

| Unit | Declarative source | Validation |
| --- | --- | --- |
| `agenix.service` | `security/security.nix` and Agenix module | Successful oneshot result and mode `0600` runtime secrets. |
| `cli-proxy-api.service` | `modules/app/cli-proxy-api/default.nix` | Enabled, active, zero restarts, expected loopback listener. |
| `nnn-herdr-sync.path` and service | `modules/tui/nnn-herdr-sync.nix` | Path enabled; generated projects converge without direct edits. |
| `onedrive-sync.timer` and service | `modules/app/rclone/default.nix` | Timer enabled; final sync result succeeds. |
| GPG agent service/sockets | `modules/app/git/git.nix` | SSH socket resolves and signing test succeeds. |
| `set-SSH_AUTH_SOCK.service` | generated by the active Home Manager configuration | Unit succeeds and exports only the socket path. |

Do not add DDE units from the live user manager to this list.

### Unmanaged AI-tool units to convert

The following regular files under `~/.config/systemd/user` should become
focused Home Manager modules:

- `cloudflared-cursor-openai.service`
- `collie.service`
- `cursor-to-openai.service`
- `hermes-dashboard.service`
- `hermes-gateway.service` and its override

Copy only unit intent, not files from referenced Git checkouts. Replace
hard-coded executable paths with stable profile paths or Nix package paths.
Move `EnvironmentFile` secrets to Agenix. Preserve loopback binding, restart
policy, `UMask=0077`, network ordering, and `ConditionPathExists` gates where
appropriate.

For each unit:

1. Record current enabled/active/result/restart state without printing its
   environment.
2. Build the new Home Manager generation and inspect the generated unit.
3. Stop only the exact old unit or process immediately before activation.
4. Activate, reload the user manager, and start the declarative unit.
5. Require enabled, active, `Result=success`, zero new restarts, and the
   expected listener or application status.
6. Remove the old regular unit only after the Nix-store-linked unit is active.

## AI skill installation instructions

Do not migrate skill instruction bodies with `home.file`. The scan found a
canonical shared root at `~/.agents/skills`, extensive symlink fan-out into
agent-specific roots, separate Codex system/project skills, curated Hermes
skills, and several Git-managed skill sources.

Add a new section named `Install shared AI skills` to
`.codex/skills/uos-desktop-bootstrap/SKILL.md`. That section must:

1. Declare `~/.agents/skills` as the shared global source of truth.
2. Install the Baoyu set from `jimliu/baoyu-skills` with the supported global
   skills installer.
3. Install CNB skills with:

   ```sh
   /usr/bin/env PATH=/home/Designers/.nix-profile/bin:/usr/bin:/bin \
     /home/Designers/.nix-profile/bin/npx --yes skills add \
     https://cnb.cool/cnb/skills/cnb-skill.git -g --agent '*' -y
   ```

4. Record explicit upstream installer/source instructions for AWS skills,
   `story-to-handdrawn-video`, and curated Hermes skills. Do not copy their Git
   repositories into this flake.
5. Preserve Codex project-local skills in `.codex/skills/` and Codex system
   skills in their owning installation; do not replace them with global links.
6. Verify the lock manifest, expected skill names, all supported agent roots,
   and zero broken symlinks. Do not hard-code a historical symlink count as a
   success condition.
7. State that Eve and PromptScript were previously observed not to support the
   global installer, so their absence is not a broken-link failure.

The future skill update must be validated with the project/system
`quick_validate.py` using a Python environment that can import YAML.

## Small executable scripts

Use `64 KiB` as the review threshold. A file below the threshold is still
excluded if it is generated by pip/npm, is a symlink into a package or Git
checkout, or only launches a large unmanaged binary bundle.

| Path | Classification | Action |
| --- | --- | --- |
| `~/.local/bin/cursor` | Small independent shell shim | Migrate to `pkgs.writeShellApplication`; retain the fallback to Cursor Agent and add explicit runtime/path checks. |
| `~/.local/bin/fusermount3` | Small compatibility shim | Already migrated as `fusermount3Compat` in the rclone module; do not duplicate it. |
| `~/.local/bin/pi` | Home Manager symlink | Already managed by the agent-tools module. |
| `obscura`, `obscura-worker` | Small wrappers coupled to large local binary/runtime trees | Exclude under the large-executable rule unless the whole package receives a separate Nix packaging project. |
| `pip*`, `wheel`, `normalizer`, `pyrsa-*`, `google-oauthlib-tool` | Generated Python entry points | Exclude; obtain them from a declared Python environment if needed. |
| `agent`, `cursor-agent`, `grok`, `herdr-palette`, `aws*` | Symlinks into app, plugin, or downloaded trees | Exclude; manage the owning package or installer. |
| `uv`, `uvx`, `rtk`, `fff-mcp`, `cnb`, `*.real` | Large executables | Exclude from script migration. |

## Recommended repository layout

Create modules only when implementation begins:

```text
modules/app/agent-configs/
  codex.nix
  claude.nix
  cursor.nix
  grok.nix
  hermes.nix
  herdr.nix
  pi.nix
modules/app/personal-configs/
  atuin.nix
  bottom.nix
  glow.nix
  smplayer.nix
  television.nix
  zellij.nix
modules/app/user-services/
  cloudflared-cursor-openai.nix
  collie.nix
  cursor-to-openai.nix
  hermes-dashboard.nix
  hermes-gateway.nix
```

Keep modules small. Merge with an existing active module when it already owns
the application; do not create competing owners for the same path.

## Execution order

### Phase 0: freeze and review

1. Start from a clean logical Git state. Preserve the current uncommitted
   `modules/app/agent-tools/default.nix` work as a separate change.
2. Save metadata-only inventories: path, owner, mode, size, symlink target,
   package owner, and Git-boundary decision.
3. Record checksums locally for source/backup comparison; do not commit the
   inventory if it contains private path or account names.
4. Verify every proposed source is outside a Git worktree and outside the hard
   exclusions.

### Phase 1: already-managed audit

Confirm that every current Nix-store symlink matches its repository source.
Remove stale `.hm-bak` files only in a later, explicitly approved cleanup.

### Phase 2: non-secret static config

Migrate one application per commit. Prefer native `programs.*` options, then
`xdg.configFile`. Build before replacing the live file. Let Home Manager create
its normal backup on first activation, compare behavior, and keep the backup
until a reboot/fresh-login test passes.

### Phase 3: credentials

Complete the Agenix sequence above. Correct unsafe modes, introduce login
runbooks for mutable OAuth stores, and validate without printing content. This
phase requires explicit approval before removing any plaintext source.

### Phase 4: services

Convert the five unmanaged AI-tool units one at a time. Do not restart unrelated
desktop or agent processes. Validate service state and listener ownership after
each activation.

### Phase 5: skills

Update only the UOS bootstrap skill instructions. Run the supported installers
manually from the required environment, then verify discovery and symlinks.

### Phase 6: scripts

Migrate only the Cursor shim. Confirm both `cursor <file>` and `cursor agent`
resolution before removing the live script.

## Validation commands

Run changed-file formatting and parsing first:

```sh
alejandra path/to/changed.nix
nix-instantiate --parse path/to/changed.nix >/dev/null
git diff --check
```

Then run focused checks and the activation build:

```sh
nix build .#checks.aarch64-linux.formatting \
  .#checks.aarch64-linux.lint --no-link --no-update-lock-file
nix build 'path:.#homeConfigurations.Designers.activationPackage' \
  --no-link --no-update-lock-file
```

On this host, the full flake syntax check may fail because a sandboxed builder
cannot create `/nix/var/nix/profiles`. Report that host limitation separately;
do not treat it as a source failure when changed-file parsing, formatting,
lint, and the activation package all pass.

Before activation, inspect the complete diff and obtain approval for the exact
batch. Activate with:

```sh
env PATH=/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin \
  home-manager switch --flake .#Designers -b hm-bak
```

After activation, open a fresh login shell and validate:

- The owning application reads the intended config.
- Mutable config and credential destinations remain writable.
- No secret appears in the Git diff, Nix store, process arguments, logs, or
  shell environment.
- All migrated services have the required state and no new restarts.
- Agent CLIs start, MCP commands resolve, and Pi still uses the compatibility
  shim successfully.
- `find` reports no broken skill links.
- Git status contains only the intended batch.

## Rollback

1. Stop only the affected service or application.
2. Activate the previous Home Manager generation.
3. Restore the application-specific backup if the previous generation does
   not own that path.
4. Restore credential files from the encrypted/offline backup without printing
   them, and reapply restrictive modes.
5. Re-run the application or service acceptance check.
6. Keep the failed migration commit available for diagnosis; do not use a
   destructive repository reset.

## Completion checklist

- [x] Every included live path has one declared owner and a documented rollback.
- [x] Helix, DDE, and every Git worktree/submodule remain untouched.
- [x] All agent histories, sessions, logs, caches, databases, and model data remain outside Home Manager.
- [x] Static credentials are encrypted; mutable credentials have a safe login or seed workflow.
- [x] `credential-vault backup` uploads and verifies an encrypted InfinityCloud archive without creating a plaintext archive.
- [x] A controlled test restore creates a verified pre-restore backup and restores only allowlisted paths.
- [x] SSH and GPG have tested out-of-band recovery procedures.
- [x] No plaintext secret or private key is present in Git or the Nix store.
- [x] Existing Home Manager services and the five migrated services pass their acceptance checks after activation; the unrelated pre-existing OneDrive failure remains out of scope.
- [x] The five unmanaged AI-tool units are declared by Home Manager; their old regular files are retained as `.hm-bak` by policy.
- [x] Shared skills are reproducible from UOS bootstrap instructions with zero broken links required at install time.
- [x] Only the Cursor shim required a new script declaration; generated and large executables remain excluded.
- [x] Formatting, parsing, lint, activation build, live verification, and fresh-login verification passed after the final implementation pass.
