---
name: use-cf-cli
description: >-
  Use when talking to the Cloudflare API, DNS, zones, Workers, D1, R2, KV,
  Access, or tunnels from this NixOS host. Prefer the beta Cloudflare CLI
  (`cf`, alias `cloudflare`) over Wrangler unless the project has
  wrangler.jsonc/wrangler.toml and no cloudflare.config.ts.
---

# Cloudflare CLI (`cf`) on UOS

Pinned on PATH by Home Manager: `overlays/packages/cf-cli.nix` as `cf-cli`
(`profiles/work/packages.nix`). Wrapper: `npx --yes cf@1.0.0-beta.12`.
Binaries: `cf` and `cloudflare`. Docs:
https://developers.cloudflare.com/cf/
https://developers.cloudflare.com/cf/agents/

`cf` is **beta**. Retrieve docs and `cf --help` / `cf cli search` instead of
memorized Wrangler flags. Do not `npm install -g cf`; bump the overlay pin.

## When to use which CLI

| Situation | Tool |
| --- | --- |
| Zones, DNS, Access, account, resources, API | `cf` |
| Project has `cloudflare.config.ts` | `cf` (`dev`/`build`/`deploy`) |
| Project has only `wrangler.jsonc` / `wrangler.toml` | Wrangler for `dev`/`deploy`; `cf` for account/API |
| Live logs / single secret | Wrangler (`wrangler tail`, secrets) |
| Named Cloudflare Tunnel on this host | `cloudflared` + `repair-cloudflared-office` |

Do **not** run `cf dev`, `cf build`, or `cf deploy` in a Wrangler-only project.
Preview migration: `cf migrate --dry-run`, then `cf migrate`.

This host Wrangler is overlay `4.147.0` (`overlays/packages/wrangler.nix`).
`cf` does **not** reuse `wrangler login`.

## Auth

Interactive:

```sh
cf --version          # 1.0.0-beta.12
cf auth login         # --no-browser over SSH
cf auth whoami
cf zones list
```

CI / unattended: `CLOUDFLARE_ACCOUNT_ID` plus `CLOUDFLARE_API_TOKEN` (never
paste the token). Token beats every profile. Named profiles:
`cf auth create`, `cf auth activate`. Requires Node ≥ 22 (this host: 24).
Bun is unsupported for `cloudflare.config.ts`.

## Agent workflow

1. `cf cli search "create a DNS record"` — local, no credentials, quote the
   whole task.
2. `cf schema <product> <command>` for generated API commands.
3. `--dry-run` before mutating. JSON on stdout; status on stderr.
4. Destructive deletes in non-interactive sessions need `--force` or they
   print `Aborted.` and exit 0.
5. `--local` only for a few KV / D1 / R2 commands.

IDs, not names, for many resources (`cf d1 query <DATABASE_ID>`).

## This repo

Sites under `sites/` still use Wrangler config. Keep Wrangler for those
deploys until migrated. Overlay pin lives in `overlays/packages/cf-cli.nix`.
To update: bump `cf@x.y.z` in the wrapper, `home-manager switch --flake .#Designers`.
