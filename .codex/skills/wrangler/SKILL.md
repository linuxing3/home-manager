---
name: wrangler
description: >-
  Run or troubleshoot Wrangler on this host (Home Manager overlay 4.147.0)
  for Worker projects that still use wrangler.jsonc or wrangler.toml. Prefer
  the use-cf-cli skill for the public Cloudflare API and for projects with
  cloudflare.config.ts.
---

# Wrangler on UOS

If the project has `cloudflare.config.ts`, or the user asked for the Cloudflare
CLI, stop and use `use-cf-cli`. Docs:
https://developers.cloudflare.com/cf/wrangler/

Host binary: Home Manager `wrangler` from `overlays/packages/wrangler.nix`
(**4.147.0**). Prefer the **project-local** Wrangler from the lockfile when a
site has its own `package.json`. Do not silently upgrade a project's Wrangler
to match the host overlay.

## Host vs project

| Path | Version |
| --- | --- |
| `~/.nix-profile/bin/wrangler` | 4.147.0 overlay |
| `sites/*/package.json` | whatever the site pins |

`wrangler.jsonc` preferred over TOML. `cf` does not read Wrangler config.
Do not run `cf dev` / `cf build` / `cf deploy` until `cf migrate`.

## Still Wrangler-only

- Live logs: `wrangler tail <WORKER_NAME>`
- Single secrets: Wrangler secret commands (see current docs)
- Tunnel connectors: `cloudflared`, not Wrangler

## Retrieve, then run

Use project `wrangler --help` and
https://developers.cloudflare.com/workers/wrangler/commands/index.md
Do not invent flags. Dry-run deploys with `wrangler deploy --dry-run` when
supported. Keep secrets out of argv and logs. `wrangler login` is separate
from `cf auth login`.
