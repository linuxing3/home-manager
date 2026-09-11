---
name: repair-dsh
description: >-
  Use when the DeepSeek Harness CLI `dsh` fails with npm EACCES on ~/.npm,
  first boot hangs on pnpm install, `dsh web` is not listening on 3080, or
  someone looks for a dsh systemd unit that does not exist.
---

# Repair DeepSeek Harness (`dsh`)

`dsh` is a Home Manager CLI wrapper, not a user systemd unit. Web UI:
`dsh web --no-open` on **`http://127.0.0.1:3080`**. Overlay:
`overlays/packages/dsh.nix`. Module: `modules/app/ai-agents/dsh.nix`.

Checkout: `$DSH_SRC` (default `~/.local/share/deepseek-harness`), pinned rev in
the overlay. pnpm lives in `~/.local/share/dsh-tools`. Home: `~/.dsh`.

## Failures

| Symptom | Cause |
|---|---|
| `npm error EACCES` / `~/.npm/_cacache` | `~/.npm` is root-owned; do not `sudo chown` as the first fix |
| First `dsh --help` takes many minutes | Clone + `pnpm install` + `pnpm run build` |
| No unit in `systemctl --user list-units '*dsh*'` | Expected; start the web profile by hand |
| UI 200 but model calls fail | Empty `DEEPSEEK_API_KEY` |
| `landlock-run` missing on aarch64 | Overlay fetches `@deepseek-ai/node-addon-landlock-run-linux-arm64` |

## Required shape

Wrapper sets `NPM_CONFIG_CACHE` / `npm_config_cache` to
`$DSH_NPM_CACHE` (default `~/.cache/dsh-npm`) so npm never uses root-owned
`~/.npm`. It also strips `--expose-internals` from `NODE_OPTIONS` and passes
that flag on argv.

Do not `npm install -g`. After a successful first boot, `.dsh-build/runtime-ready`
exists and profile packages are hoisted into the checkout `node_modules`.

## Boot and verify

```sh
command -v dsh
dsh --version
dsh web --help
ss -ltn | rg 3080 || dsh web --no-open
curl -sS -o /dev/null -w 'ui %{http_code}\n' --max-time 15 http://127.0.0.1:3080/
```

Expect version `0.1.0-rc.8` (or the overlay pin), help text, listen
`127.0.0.1:3080`, `GET /` **200** HTML. Leave `--no-open` on; do not replace
the desktop `BROWSER`.

LLM calls need `DEEPSEEK_API_KEY` from the inherited env, `~/.dsh/.env`, or
`~/.config/pi-switch/env` (Pi wrapper sources the latter). Do not commit keys.

Graceful stop: SIGTERM. Do not create a systemd unit unless the user asks.
