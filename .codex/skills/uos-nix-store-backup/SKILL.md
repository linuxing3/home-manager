---
name: uos-nix-store-backup
description: >-
  Backs up and restores UOS + standalone Home Manager using KeyVault packs
  uos-Designers (SSH/GPG/Agenix) and uos-system-recovery (Nix guide, manifests,
  signed-cache keys), plus local file:// cache, GPG OneDrive archives, and
  linuxing3-system-recovery Cachix. Use for KeyVault layout, identity restore,
  nix-recovery-guide, or Nix store remote backup/verify.
---

# UOS KeyVault + Nix Store Recovery

Operational skill for Designers-PC. Prefer
`docs/nix-store-backup-and-recovery-manual.md` and
`docs/personal-config-migration-manual.md` (KeyVault sections). Prompted UI:
`tools/nix-recovery-guide`.

## Current KeyVault top-level layout

```text
KEYVAULT/
├── uos-Designers/                 # this host user identity
│   ├── ssh/
│   ├── gpg/                       # armored exports + revocation/
│   ├── age/README.txt             # Agenix uses ../ssh/id_ed25519
│   ├── age/cloudflared-office-token.age
│   └── checksums/SHA256SUMS
├── uos-system-recovery/
│   ├── README.txt
│   ├── luks-uuid.txt
│   ├── ext4-uuid.txt
│   └── nix-system-recovery/       # guide, manifests, repo, Nix/Cachix keys
├── alpine-efwmc/                  # other-host identity pack (optional)
└── sources/                       # optional non-secret source trees
```

Deprecated: root-level `ssh/`, `gpg/`, `age/`, `checksums/`, and
`recovery/nix-system-recovery/`. Always use `uos-Designers/` and
`uos-system-recovery/nix-system-recovery/`.

## Non-negotiable boundaries

- Do **not** treat a plain copy of `/nix/store` as a backup.
- Nix scope is the **current** Home Manager generation plus the **current**
  user profile. Never default to `nix copy --all`.
- KeyVault (~15 GiB) holds identity + recovery metadata/keys only. Large NAR
  data stays in `/share/recovery/nix-cache`, then remote.
- Never print or commit secrets (SSH/GPG private material, Nix/Cachix signing
  keys, tokens, Bitwarden passwords, 2FA codes).
- Do not activate Home Manager, run GC, or rewrite partitions unless the user
  separately confirms.
- Command exit status alone is insufficient. Require size/hash/URL evidence.

## Layered materials

| Layer | Purpose | Location |
|---|---|---|
| Identity | SSH / GPG / Agenix | KeyVault `uos-Designers/` |
| Config | Rebuild HM | Git + `uos-system-recovery/nix-system-recovery/repository/` |
| Signed Nix cache | Fast/offline closure | `/share/recovery/nix-cache`; Cachix; OneDrive `.tar.gpg` |
| Full-disk image | Bootable UOS | Offline Clonezilla/Rescuezilla of the NVMe |

`/nix`, `/home`, and `/var` share one NVMe data partition here; they are not
independent disaster replicas.

## Unlock KeyVault

```sh
# LUKS UUID is also in uos-system-recovery/luks-uuid.txt after unlock
sudo cryptsetup open /dev/disk/by-uuid/<LUKS-UUID> keyvault
sudo mkdir -p /media/Designers/KEYVAULT
sudo mount -o nodev,nosuid,noexec /dev/mapper/keyvault /media/Designers/KEYVAULT
```

Desktop pinentry + `sudo cryptsetup --key-file` is acceptable when there is no
TTY. Never echo the passphrase. After use: `sync`, `umount`, `cryptsetup close`.

## Restore SSH / GPG / Agenix (`uos-Designers`)

```sh
KV=/media/Designers/KEYVAULT
cd "$KV/uos-Designers"
sha256sum -c checksums/SHA256SUMS

mkdir -m 700 -p ~/.ssh
install -m 0400 ssh/id_ed25519 ~/.ssh/id_ed25519
install -m 0644 ssh/id_ed25519.pub ~/.ssh/id_ed25519.pub
install -m 0400 ssh/id_rsa ~/.ssh/id_rsa
install -m 0644 ssh/id_rsa.pub ~/.ssh/id_rsa.pub
install -m 0644 ssh/known_hosts ~/.ssh/known_hosts
install -m 0600 ssh/authorized_keys ~/.ssh/authorized_keys

gpg --import gpg/public.asc
gpg --import gpg/master-secret.asc
gpg --import-ownertrust gpg/ownertrust.txt
```

Rules:

- Restore `id_ed25519` **before** Agenix or Home Manager secret activation.
- Do **not** restore `~/.ssh/config` from KeyVault.
- Verify SSH with `ssh-keygen -y` vs `.pub`; verify GPG in a temp `GNUPGHOME`
  requiring `sec` and `ssb`; smoke-test Agenix without printing secrets.
- Other hosts use sibling packs (for example `alpine-efwmc/`), never mix into
  `uos-Designers/`.

### Refreshing `uos-Designers` backups

1. Copy SSH identities into `uos-Designers/ssh/` with correct modes.
2. Export GPG armored files into `uos-Designers/gpg/` via pinentry (loopback +
   desktop pinentry when headless). Require `master-secret.asc`.
3. Keep revocation under `gpg/revocation/`.
4. Copy encrypted Agenix files such as `cloudflared-office-token.age` into
   `uos-Designers/age/` (ciphertext only; identity remains `../ssh/id_ed25519`).
5. Regenerate `uos-Designers/checksums/SHA256SUMS` and verify immediately.

## Nix recovery package (`uos-system-recovery`)

`tools/nix-recovery-guide` reads/writes:

`$KEYVAULT/uos-system-recovery/nix-system-recovery/`

Workflow:

1. Non-activation build when config changed.
2. Unlock KeyVault.
3. Run `tools/nix-recovery-guide` → create/refresh package.
4. Sign current HM + profile into `file:///share/recovery/nix-cache`.
5. Verify with KeyVault public key under that package’s `secrets/`.
6. Publish remotes if requested; update repo `docs/` receipts.
7. `sync` before unmount.

## OneDrive encrypted archive lessons

Target: `onedrive-linuxing3:Backups/Nix/Designers-PC`.

1. Build local signed cache first.
2. Encrypt to KeyVault GPG encryption subkey only; never upload private keys.
3. Skip redundant GPG compression for already-zstd NARs.
4. Atomic `.sha256` after archive completion.
5. Temp-name upload; rename after exact size + QuickXorHash match.
6. Bundle small metadata into one tar (OneDrive small-file hangs / 0-byte stubs).
7. Do not `gpg --list-packets` multi-GiB ciphertext end-to-end.

## Cachix lessons

- Recovery cache: `https://linuxing3-system-recovery.cachix.org`
  public key `linuxing3-system-recovery.cachix.org-1:PspTtTON4FR/Id+reL0/Bli8lvrU17yr/8OR1q9F67c=`.
- Historical cache name is `linuxing3` (not `nuxing3`).
- `CACHIX_SIGNING_KEY` and management-API `publicSigningKey` are **Base64 after
  the colon only**, not full Nix `name:Base64`.
- Existing caches cannot add a second signing public key; do not delete shared
  caches lightly. Prefer a never-used cache name for new recovery caches.
- Delete-then-recreate **same name** can leave inconsistent signing state.
- Bulk missing-path API can lie for globally reusable NARs; accept only when
  every closure `.narinfo` URL is HTTP 200.
- Nix 2.35.1 `nix store verify --store https://...` may report `not valid`
  despite matching hashes; split public-key/metadata checks from byte-stream
  hash checks.
- Keep OneDrive archive even after Cachix succeeds.

## Full restore order

1. Protect original disk; no format/`dd` without rescue confirmation.
2. Restore `uos-Designers` identity first.
3. Restore repo from
   `uos-system-recovery/nix-system-recovery/repository/` or Git.
4. Import closure from local cache, decrypted OneDrive archive, or Cachix.
5. Non-activation build of
   `path:.#homeConfigurations.Designers.activationPackage`.
6. Activate only after separate confirmation.
7. Restore ordinary user data and UOS system-layer settings last.

## Acceptance checklist

- [ ] `uos-Designers/checksums/SHA256SUMS` passes.
- [ ] `uos-system-recovery/nix-system-recovery/SHA256SUMS` passes.
- [ ] SSH pubkey derivation matches; GPG temp import shows `sec`/`ssb`.
- [ ] Local Nix cache verifies under package public key.
- [ ] OneDrive: exact size + QuickXorHash (+ SHA-256 after download).
- [ ] Cachix: every closure narinfo HTTP 200 with registered key name.
- [ ] No private keys uploaded; runtime token files deleted; clipboards cleared.
- [ ] Repo docs and KeyVault manifests/receipts updated together.
