# Hermes Gateway Agenix Environment Design

## Goal

Run the existing Hermes Gateway user service through `agenix-env` so the
gateway receives the Agenix-managed environment only in its child process.

## Design

Keep the existing user-level systemd drop-in and replace its `ExecStart` with:

```ini
ExecStart=/home/Designers/.nix-profile/bin/agenix-env -- /home/Designers/.nix-profile/bin/hermes gateway run
```

Use Home Manager profile paths rather than Nix store paths so profile upgrades
continue to resolve the active wrappers. Keep the existing empty `ExecStart=`
reset and empty `ExecStopPost=` override.

No secret values are written to the unit, repository, command line, or logs.
`agenix-env` reads the materialized Agenix environment at runtime and exposes
it only to the Hermes child process.

## Failure Handling

If the Agenix environment is unavailable, `agenix-env` exits with an error and
systemd follows the service's existing restart policy. The wrapper must not
fall back to the plaintext `~/.hermes/.env` file.

## Verification

1. Confirm the Agenix user service is successful and its materialized
   environment file has restrictive permissions without displaying contents.
2. Reload the user systemd manager and restart `hermes-gateway.service`.
3. Confirm the service is enabled and remains active with zero new restarts.
4. Confirm the effective `ExecStart` begins with `agenix-env`.
5. Review new gateway logs for wrapper, decryption, import, or startup errors.
