# Nix store remote backup receipt

- Created: 2026-08-13
- Host: `Designers-PC`
- Architecture: `aarch64-linux`
- Scope: current Home Manager generation plus current user Nix profile closure
- Store paths: 2136
- Local signed cache: `/share/recovery/nix-cache`
- Remote: `onedrive-linuxing3:Backups/Nix/Designers-PC`
- Encrypted archive: `nix-store-current-Designers-PC-20260813-123200.tar.gpg`
- Exact archive size: `4674747092` bytes
- OneDrive QuickXorHash: `93ed428afa6290191f69fde2fc521848ab269df4`
- Encryption: KeyVault GPG cv25519 encryption subkey `478475650CC299124D1B5500FE4AA5A6B6BA031A`

The archive SHA-256 is stored in the adjacent `.sha256` file. The encrypted
KeyVault USB holds the matching GPG private key, Nix cache signing secret key,
manual, guided recovery script, and local recovery metadata. No private key was
uploaded.

Before recovery, download the archive, checksum, metadata tar, and README. Check
the SHA-256 before decrypting. Use `nix-recovery-guide` for the prompted import,
non-activation build, and separately confirmed activation workflow.

## Cachix attempt

- Checked: `2026-08-13T15:01:41-03:00`
- Cache: `https://linuxing3.cachix.org`
- Registered public key: `linuxing3.cachix.org-1:IpwG3iKqyxrlckXgsjGmjpC8w1G9BK3xEUM1IDXHaKM=`
- Result: **not completed**

The authenticated push found 1984 reusable NAR objects and 152 objects that
needed uploading, but Cachix rejected narinfo publication because the matching
`linuxing3.cachix.org-1` secret signing key was unavailable. Both top-level
recovery roots still returned HTTP 404 after the attempt.

A replacement candidate keypair named `linuxing3.cachix.org-2` was generated,
verified, and saved only on the encrypted KeyVault USB. Its public key is
`linuxing3.cachix.org-2:zr7zSaYotQtUXI0Z1VECob/RYTjb7KRliE29dy16Fyc=`.
Cachix rejected registering it with: `A public signing key already exists. It's
currently not possible to override or add multiple signing keys.` Therefore the
candidate key is **not registered** and must not be used to push to the existing
`linuxing3` cache. The existing `-1` public key was not changed.

Safe ways forward are to recover the original `-1` secret key, or create a new
Cachix cache for the `-2` keypair. Do not delete or recreate the existing cache
without separately confirming the impact on its current contents and users.

## Cachix completed backup

- Completed: `2026-08-13T16:46:15-03:00`
- Cache: `https://linuxing3-system-recovery.cachix.org`
- Owner: `linuxing3`
- Visibility: public, read-only recovery requires no authentication token
- Public key: `linuxing3-system-recovery.cachix.org-1:PspTtTON4FR/Id+reL0/Bli8lvrU17yr/8OR1q9F67c=`
- Home Manager root: `/nix/store/y18d4fv7g1fr5g0brymmx5jkrd4lv1ks-home-manager-generation`
- User profile root: `/nix/store/0pj2qhxg3bnk036dc1gj7nxxipzyyjqj-profile`
- Unique closure paths: `2136`
- Remote compressed bytes verified: `4724451811`
- Uncompressed NAR bytes verified: `15150974760`
- Result: **completed and independently verified**

After the initial push and one multipart smoke test, a retry-stabilized URL scan
found 154 present entries and 1982 narinfo URLs returning HTTP 404. Cachix's
bulk missing-path API had incorrectly treated globally reusable NAR objects as
already present in this new cache. Those 1982 entries were backfilled from the
existing local signed cache with verified zstd NAR files and the registered
cache signing key. The original `linuxing3` cache was not changed or recreated.

Final acceptance checks all passed:

1. All `2136/2136` public narinfo URLs returned HTTP 200.
2. Nix locally verified all 2136 paths against the registered public key.
3. For all `2136/2136` paths, the remote StorePath, NAR hash and size,
   references, deriver, and Cachix signature exactly matched the locally
   verified Nix metadata.
4. All `2136/2136` remote NAR objects were downloaded and streamed through
   complete compressed SHA-256/size and decompressed NAR SHA-256/size checks;
   no mismatch occurred.
5. Both top-level roots were present and their registered Cachix signatures
   passed Nix metadata verification.

Nix 2.35.1's HTTP binary-cache backend reported `path ... is not valid` when
`nix store verify --store URL` attempted content validation, despite matching
narinfo metadata and independently matching compressed and decompressed hashes.
The acceptance procedure therefore separated Nix public-key verification from
the full remote byte-stream verification described above instead of treating
HTTP 200 alone as proof.

The cache signing secret key remains only on the encrypted KeyVault USB. The
public key may safely be copied to a restored machine as a trusted public key.

## Operational skill

Agent runbook capturing this session’s pitfalls (signing-key Base64 format,
same-name Cachix recreate hazard, bulk missing-API false negatives, OneDrive
small-file hangs, QuickXorHash verification) lives at:

`.codex/skills/uos-nix-store-backup/SKILL.md`

Source Codex session for the executed backup work:
`019ffb8a-b79c-7c03-8b54-0a07aba0f00f` (2026-08-13).
