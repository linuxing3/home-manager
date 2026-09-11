---
name: configure-notion-mcp
description: >-
  Use when Notion MCP is needsAuth, cursor-agent mcp login notion fails,
  localhost:8787/callback shows Not found, Collie collides with Cursor OAuth,
  or the user asks to fetch Notion pages from Cursor CLI on this Home Manager
  host.
---

# Notion MCP on this host

HM registers the hosted server in `modules/app/ai-agents/mcp-lib.nix`
(`https://mcp.notion.com/mcp`), then `cursor/default.nix`. OAuth only. Do not
put Notion tokens in git.

## Ports

| Port | Owner |
|---|---|
| **8787** | Cursor MCP OAuth (`http://localhost:8787/callback`) |
| **8788** | Collie Herdr bridge (`COLLIE_PORT` in `collie.nix`) |

Do not move Cursor’s callback. If Collie is back on 8787, login fails with
`EADDRINUSE` or a foreign 404. Office tunnel hostname
`collie.efwmcstyle.ccwu.cc` must origin `http://127.0.0.1:8788`.

## What works here

| Surface | Auth |
|---|---|
| Desktop Cursor → Customize → Notion → Connect | Official. `mcp_auth` in this agent chat cannot open the browser. |
| `cursor-agent mcp login notion` | Official CLI. Exact pathname `/callback` only. One-shot: a GET without `code` kills the login. |
| `scripts/notion-mcp-login.py` | Fallback when CLI 404s or the agent cannot run `mcp_auth`. |

`~/.local/bin/agent` is a generic Linux binary and fails NixOS stub-ld. Use
Nix `cursor-agent`.

## CLI login (preferred)

```sh
# 8787 must be free
ss -ltn | rtk grep 8787 || true
cursor-agent mcp login notion
# Complete Allow in the desktop browser. Do not curl /callback.
cursor-agent mcp list-tools notion
```

## Fallback script

```sh
python3 .codex/skills/configure-notion-mcp/scripts/notion-mcp-login.py
# Print only the authorize URL file, never tokens:
rtk read /tmp/notion-mcp-authorize.url
```

The script DCR-registers a public client (needs a browser User-Agent or
Cloudflare 1010 bans Python-urllib), listens on `0.0.0.0:8787`, accepts a
`code` on any path, serves a no-op `sw.js`, and writes `notion.tokens` into
each existing `~/.cursor/projects/*/mcp-auth.json`. Never print
`access_token` / `refresh_token`.

Use **one** authorize URL per listener. Mixing tabs from an older
`client_id` yields `invalid_grant: Client ID mismatch`.

## Failures

| Symptom | Cause |
|---|---|
| Chat `notion` is `needsAuth`; `mcp_auth` fails | Interactive OAuth is desktop/CLI only |
| `Not found` on `localhost:8787/callback` | Brave SW for `:8787` (`/index.html`, `/sw.js`) or path ≠ `/callback` |
| `Missing redirect_uri` on `mcp.notion.com/callback` | Truncated authorize URL |
| `Client ID mismatch` | Old authorize tab vs new DCR client |
| CLI still `requires authentication` | Tokens written to another project’s `mcp-auth.json` |
| Chat still `needsAuth` after CLI works | This agent session does not load CLI tokens; new desktop chat or `cursor-agent` |

Unregister `localhost:8787` under `brave://serviceworker-internals` if the SW
keeps eating the redirect. Keep OAuth in the configured desktop browser.

## Verify (names only)

```sh
python3 -c 'import json,pathlib; p=pathlib.Path.home()/".cursor/projects";
print([x.name for x in p.glob("*/mcp-auth.json")])'
# Then, without dumping values:
# notion.tokens has access_token + refresh_token
cursor-agent mcp list-tools notion
```

Expect dozens of tools (`notion-search`, `notion-fetch`, …). Hosted Notion
MCP has no API-key path. The unmaintained stdio `@notionhq/notion-mcp-server`
plus `NOTION_TOKEN` is a different server; do not add it unless hosted OAuth
is impossible.

## Related

- `modules/app/ai-agents/mcp-lib.nix` — `notion` HTTP entry
- `modules/app/ai-agents/collie.nix` — Collie on 8788
- `docs/notion-mcp.md`
- `repair-cloudflared-office` — office token tunnel; Collie origin is remote
