---
name: repair-cloudflared-office
description: >-
  Use when this UOS host's cloudflared-office.service fails or is being
  changed: ExecStart does not expand CLOUDFLARED_TUNNEL_TOKEN, journal says
  tunnel run requires ID or name, keysEnv/XDG_RUNTIME_DIR nounset, ConditionPathExists
  skips the unit, sourcing api-keys-new dumps extra keys, or Agenix runtime
  is missing the tunnel token.
---

# Repair cloudflared-office on UOS systemd 241

Office connector token is `CLOUDFLARED_TUNNEL_TOKEN` inside materialized
`api-keys-new.age`. Never print or log the value. Do not put it in git, Atuin
cleanup output, or `ExecStart=` argv in the unit file beyond the wrapper.

Module: `modules/app/cloudflared-office.nix`. Secret ciphertext:
`security/secrets/api-keys-new.age`.

## Failures

| Symptom | Cause |
| --- | --- |
| `tunnel run` requires ID or name | UOS systemd 241 does not expand `${CLOUDFLARED_TUNNEL_TOKEN}` in `ExecStart` |
| `CLOUDFLARED_TUNNEL_TOKEN is missing` | Runtime `api-keys-new.age` stale vs repo ciphertext; or sourced the wrong file first |
| `XDG_RUNTIME_DIR: unbound variable` | `writeShellApplication` uses `nounset`; Agenix `.path` is literal `${XDG_RUNTIME_DIR}/agenix/...` |
| Unit never starts (`ConditionPathExists`) | Same literal `${XDG_RUNTIME_DIR}` in the unit; 241 does not expand it |
| Extra Cloudflare API keys in `cloudflared` env | Sourced `api-keys-new.age` then `exec` without `env -i` |

## Required shape

- `ConditionPathExists=%t/agenix/api-keys-new.age` (`%t` is the user runtime dir).
- `After=` / `Wants=` `agenix.service` and `network-online.target`.
- `ExecStart` is a `writeShellApplication` wrapper, not `cloudflared ... --token ${VAR}`.
- Wrapper: `keys_env="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agenix/api-keys-new.age"`, quote it, `set -a; . "$keys_env"; set +a`.
- Then `env -i` with only `PATH`, `HOME`, `XDG_RUNTIME_DIR`, `CLOUDFLARED_TUNNEL_TOKEN`.
- Do not splice `config.age.secrets.*.path` into the shell script.

Do not restore a dedicated `cloudflared-office-token.age` unit path unless
`api-keys-new.age` lacks the token. Restarting `agenix.service` rematerializes
the **last Home Manager generation**, not dirty git ciphertext.

## Verify (names only)

```sh
systemctl --user show cloudflared-office.service \
  -p ActiveState,SubState,Result,NRestarts,FragmentPath
awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' \
  "${XDG_RUNTIME_DIR}/agenix/api-keys-new.age" | grep -x CLOUDFLARED_TUNNEL_TOKEN
tr '\0' '\n' < /proc/"$(systemctl --user show -p MainPID --value cloudflared-office.service)"/environ \
  | awk -F= '{print $1}'
```

Expect `active`/`running`, `NRestarts=0`, token **name** present, process env
only those four variables. Journal should show argotunnel prechecks PASS and
quic. Do not dump `/proc/*/cmdline` (it includes `--token`).
