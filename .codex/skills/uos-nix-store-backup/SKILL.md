---
name: uos-nix-store-backup
description: >-
  Backs up and verifies UOS + standalone Home Manager Nix closures using a
  KeyVault-signed local binary cache, GPG-encrypted OneDrive archive, and
  Cachix recovery cache. Use when the user asks about Nix store backup,
  recovery materials, KeyVault nix-system-recovery, onedrive-linuxing3 Nix
  archives, linuxing3-system-recovery Cachix, or nix-recovery-guide.
---

# UOS Nix Store Backup

Operational skill distilled from the 2026-08-13 Designers-PC backup run
(Codex session `019ffb8a-b79c-7c03-8b54-0a07aba0f00f`). Prefer
`docs/nix-store-backup-and-recovery-manual.md` for prose and
`tools/nix-recovery-guide` for the prompted UI.

## Non-negotiable boundaries

- Do **not** treat a plain copy of `/nix/store` as a backup.
- Scope is the **current** Home Manager generation plus the **current** user
  Nix profile closure. Never default to `nix copy --all`.
- KeyVault (~15 GiB) holds keys, manuals, manifests, Git bundles, and
  receipts. Large NAR data goes to `/share/recovery/nix-cache`, then remote.
- Never print or commit secrets: GPG private keys, Nix/Cachix signing keys,
  `CACHIX_AUTH_TOKEN`, Bitwarden passwords, or 2FA codes.
- Do not activate Home Manager, run GC, or rewrite partitions unless the user
  separately confirms that step.
- Command exit status alone is insufficient. Require size/hash/URL evidence.

## Layered materials

| Layer | Purpose | Host paths / remotes |
|---|---|---|
| Config | Rebuild from source | Git repo + `flake.lock`; KeyVault `repository/` |
| Identity | Decrypt Agenix / SSH / rclone | KeyVault credentials + `credential-vault` |
| Signed Nix cache | Fast/offline closure restore | `/share/recovery/nix-cache`; Cachix; GPG OneDrive archive |
| Full-disk image | Bootable UOS | Offline Clonezilla/Rescuezilla of the NVMe |

`/nix`, `/home`, and `/var` share one NVMe data partition on this host; they
are not independent disaster replicas. `/share` is the local large-cache disk.

## Backup workflow

1. Confirm non-activation build of the intended generation when config changed.
2. Unlock and mount filesystem labelled `KEYVAULT`.
3. Run `tools/nix-recovery-guide` → create/refresh recovery package.
4. Sign current HM + profile closures into `file:///share/recovery/nix-cache`
   with the KeyVault cache signing secret key.
5. Verify locally with the matching public key.
6. Publish remotes as requested (OneDrive archive and/or Cachix).
7. Update KeyVault `SHA256SUMS` and repo receipts under `docs/`.
8. `sync` before unmounting KeyVault.

Entry points:

```sh
tools/nix-recovery-guide
```

Docs:

- `docs/nix-store-backup-and-recovery-manual.md`
- `docs/nix-store-remote-restore-readme.md`
- `docs/nix-store-remote-backup-receipt-20260813.md`

## OneDrive encrypted archive lessons

Target used successfully: `onedrive-linuxing3:Backups/Nix/Designers-PC`.

1. Build the local signed cache first.
2. Stream-encrypt with the KeyVault GPG **encryption subkey** only. Import the
   public key into a throwaway GPG home; do not export private keys.
3. Disable redundant GPG compression when NAR content is already zstd-packed.
4. Write an atomic `.sha256` sidecar after the archive is complete. Do not
   upload empty/partial checksum files.
5. Upload under a temporary name; rename only after size + hash checks.
6. Verify with exact byte size **and** OneDrive QuickXorHash against a local
   QuickXorHash of the same file. Keep SHA-256 for post-download crypto check.
7. Bundle small recovery metadata (public key, top-level paths, README) into
   one small tar. OneDrive small-file `rclone copyto` calls often hang after
   success and can leave 0-byte placeholders.
8. Avoid `gpg --list-packets` over multi-GiB ciphertext; inspect header packets
   only.
9. Never upload Nix cache signing private keys or GPG private keys.

## Cachix lessons

### Credentials and naming

- Correct historical binary cache name is `linuxing3`, not `nuxing3`.
- Completed recovery cache is
  `https://linuxing3-system-recovery.cachix.org`
  with public key
  `linuxing3-system-recovery.cachix.org-1:PspTtTON4FR/Id+reL0/Bli8lvrU17yr/8OR1q9F67c=`.
- Push needs a write-capable `CACHIX_AUTH_TOKEN`. Client-signed caches also
  need the matching `CACHIX_SIGNING_KEY`.
- Inject tokens from Bitwarden/clipboard into the child process only. Prefer
  `0600` files under `$XDG_RUNTIME_DIR` and delete them when finished.
- Clear X11 Clipboard/Primary after use.

### Signing-key format trap

`CACHIX_SIGNING_KEY` must be the **Base64 private material after the first
colon**. Passing the full Nix `name:Base64` string makes Cachix 1.11.x
mis-decode the key and produce signatures that do not match the registered
public key.

When creating a cache via management API, `publicSigningKey` is also **Base64
only**. Sending `name:Base64` produced a duplicated prefix and required
deleting the empty misconfigured cache.

### Platform limits

- Once a Cachix cache already has a client signing public key, the platform
  rejected adding a second key:
  `A public signing key already exists...`.
- Do **not** delete or recreate an existing shared cache such as `linuxing3`
  without an explicit user decision about current consumers.
- Candidate key `linuxing3.cachix.org-2` on KeyVault is **unregistered** and
  must not be used against `linuxing3`.
- Delete-then-recreate with the **same** cache name left inconsistent signing
  backend state. Prefer a never-used name (as with
  `linuxing3-system-recovery`).

### Push / verify traps

1. `cachix push` may report most NARs “already present” because content is
   globally reusable. That does **not** mean this cache has narinfo entries.
2. Cachix bulk missing-path API can return 0 missing while thousands of public
   `https://<cache>.cachix.org/<hash>.narinfo` URLs still HTTP 404.
3. Always acceptance-check with real public narinfo URLs for every path in the
   closure, not only top-level roots and not only the bulk API.
4. When narinfo is missing but a local signed cache exists, backfill by
   uploading verified local zstd NAR bytes and publishing narinfo signed with
   the **registered** cache key (multipart API path used on 2026-08-13).
5. On Nix 2.35.1, `nix store verify --store https://...` may report
   `path ... is not valid` even when narinfo metadata and full compressed /
   decompressed byte hashes match. Split acceptance into:
   - Nix public-key / metadata verification;
   - independent remote byte-stream hash verification.
6. Keep the OneDrive GPG archive as an independent remote layer even after
   Cachix succeeds.

## Restore order

1. Protect the original disk; do not format or `dd` without rescue-media
   confirmation.
2. Restore identity from KeyVault / credential tools first.
3. Restore repo from Git bundle or remote; apply reviewed patches.
4. Import closure from local `file://` cache, decrypted OneDrive archive, or
   `linuxing3-system-recovery` Cachix using the public key only.
5. Non-activation build of
   `path:.#homeConfigurations.Designers.activationPackage`.
6. Activate only after separate confirmation.
7. Restore ordinary user data and UOS system-layer settings last.

## Acceptance checklist

- [ ] KeyVault `SHA256SUMS` passes; secrets remain mode `0600`.
- [ ] Local cache verifies under the KeyVault public key.
- [ ] OneDrive: exact size + QuickXorHash (+ SHA-256 after download).
- [ ] Cachix: every closure narinfo is HTTP 200 with the registered key name.
- [ ] Remote NAR hashes match local signed-cache metadata.
- [ ] No private keys uploaded; runtime token files deleted; clipboards cleared.
- [ ] Receipts under `docs/` and KeyVault manifests updated together.
