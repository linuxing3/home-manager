# Nix store remote backup restore note

Backup scope: the complete dependency closures of the current Home Manager
generation and current user Nix profile on Designers-PC (`aarch64-linux`).

There are two independently verified remote layers from 2026-08-13:

1. **OneDrive GPG archive** under `onedrive-linuxing3:Backups/Nix/Designers-PC`
2. **Cachix** public cache `https://linuxing3-system-recovery.cachix.org`

Prefer Cachix when network access to that cache is available. Keep the OneDrive
archive as the offline/cloud-file fallback. See
`docs/nix-store-remote-backup-receipt-20260813.md` for hashes and public keys.

The large `*.tar.gpg` object is encrypted to the GPG encryption subkey whose
public key is stored on the KeyVault USB. Its matching private key is required
for decryption. Never upload or print that private key.

## Restore from OneDrive archive

1. Download the `.tar.gpg`, `.sha256`, this README, and the metadata directory.
2. Verify the encrypted archive before decryption:

   ```bash
   sha256sum -c nix-store-current-Designers-PC-*.tar.gpg.sha256
   ```

3. On a trusted machine with the KeyVault GPG private key available, decrypt
   and extract onto a filesystem with enough free space:

   ```bash
   gpg --decrypt nix-store-current-Designers-PC-*.tar.gpg | tar -xvf -
   ```

4. Use `metadata/top-level-paths.txt` and
   `metadata/nix-cache-public-key` with `nix copy --from file:///...`.
   The KeyVault `nix-recovery-guide` provides the prompted workflow.
5. Build the Home Manager activation package without activation first. Only
   activate after reviewing the build and current repository state.

## Restore from Cachix

Trusted public key:

```text
linuxing3-system-recovery.cachix.org-1:PspTtTON4FR/Id+reL0/Bli8lvrU17yr/8OR1q9F67c=
```

1. Add that public key as a one-shot `trusted-public-keys` value for the import
   command. Do not disable signature checking.
2. Copy the recorded Home Manager and user-profile roots from
   `https://linuxing3-system-recovery.cachix.org`.
3. Confirm every required path’s public `.narinfo` returns HTTP 200. Do not
   trust Cachix bulk missing-path results alone.
4. Non-activation build, then separately confirmed activation.

On Nix 2.35.1, `nix store verify --store https://...` may report
`path ... is not valid` even when narinfo metadata and remote NAR hashes match.
Treat public-key/metadata checks and full byte-stream hash checks as separate
acceptance steps.

This is a binary-cache backup, not a bootable UOS disk image and not a backup
of ordinary user data. Agent runbook:
`.codex/skills/uos-nix-store-backup/SKILL.md`.
