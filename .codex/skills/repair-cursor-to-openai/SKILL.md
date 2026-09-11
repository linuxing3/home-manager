---
name: repair-cursor-to-openai
description: >-
  Use when cursor-to-openai.service crash-loops, journal says Failed to load
  environment files, Result is resources, /v1/models returns 401/500, chat
  completions hang, or cloudflared-cursor-openai is inactive because
  ~/.cloudflared/cursor-openai.yml is missing.
---

# Repair cursor-to-openai

There is no `cursor-agent` systemd unit. Ops mean **`cursor-to-openai.service`**
(API, port 3010) and optionally **`cloudflared-cursor-openai.service`** (public
tunnel). Checkout: `/share/data/sources/cursor-to-openai`. HM:
`modules/app/ai-agents/cursor-to-openai.nix` and `cursor/default.nix`.

Never print `auth.json`, Bearer tokens, or env values.

## Quick health

```sh
systemctl --user status cursor-to-openai.service cloudflared-cursor-openai.service --no-pager
ss -ltnp | rg 3010
python3 -c 'import json; json.load(open("/home/Designers/.config/cursor/auth.json"))["accessToken"]'
TOKEN=$(python3 -c 'import json; print(json.load(open("/home/Designers/.config/cursor/auth.json"))["accessToken"])')
curl -sS -o /dev/null -w 'hello %{http_code}\n' http://127.0.0.1:3010/api/hello
curl -sS -o /dev/null -w 'noauth %{http_code}\n' http://127.0.0.1:3010/v1/models
curl -sS -o /dev/null -w 'local %{http_code}\n' -H "Authorization: Bearer $TOKEN" \
  http://127.0.0.1:3010/v1/models
unset TOKEN
```

Expect hello **200**, noauth **401**, local **200** with a real Cursor token.
Optional chat: `POST /v1/chat/completions` model `composer-2.5-fast`, non-stream,
`--max-time 90`. Healthy reply has `finish_reason: stop`.

## Symptom → cause

| Symptom | Cause |
|---|---|
| `Failed to load environment files` / `Result: resources` | Missing `~/.config/cursor-to-openai.env` |
| No auth → **401** | Expected |
| Fake Bearer → **500** + `ERROR_NOT_LOGGED_IN` | Expected; value is treated as a Cursor token |
| Real token → **200** | Healthy |
| Listen `*:3010` | `PORT` from env is a string; loopback preload only patches numeric `listen` |
| Tunnel **inactive**, `ConditionPathExists` failed | Missing `~/.cloudflared/cursor-openai.yml` |
| Public **530** | Tunnel not running |
| Tunnel **exit 218/CAPABILITIES** | User systemd cannot drop caps; need `*.service.d/override.conf` |

HM activation seeds `~/.config/cursor-to-openai.env` (`PORT=3010`, mode 600) if
missing. Unit uses `EnvironmentFile=-…` so a missing file no longer crash-loops.
Token comes from Bearer or `~/.config/cursor/auth.json`, not the env file.

## Restore API unit

```sh
test -f ~/.config/cursor-to-openai.env || printf 'PORT=3010\n' > ~/.config/cursor-to-openai.env
chmod 600 ~/.config/cursor-to-openai.env
systemctl --user reset-failed cursor-to-openai.service
systemctl --user restart cursor-to-openai.service
journalctl --user -u cursor-to-openai.service -n 40 --no-pager -q
```

If **218/CAPABILITIES**, keep drop-in
`~/.config/systemd/user/cursor-to-openai.service.d/override.conf` that clears
hardening (`NoNewPrivileges=false`, `ProtectSystem=no`, empty
`RestrictAddressFamilies`, real nix `node` `ExecStart`). Then `daemon-reload` +
restart.

## Restore Cloudflare tunnel

HM `mergeYamlFile` does **not** create the YAML. Hostnames:
`cursor.efwmcsyle.ccwu.cc`, `cursor-origin.efwmcsyle.ccwu.cc` →
`http://127.0.0.1:3010`. Bootstrap once from `orca-remote.yml` shape; later
activations only merge ingress. Do not commit credentials JSON or `cert.pem`.
