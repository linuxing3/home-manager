# Notion MCP

Home Manager registers Notion’s hosted MCP at `https://mcp.notion.com/mcp`
in `modules/app/ai-agents/mcp-lib.nix` and `cursor/default.nix`. Auth is
OAuth only. Tokens stay in `~/.cursor/projects/*/mcp-auth.json`. Never commit
them.

Operational skill: `.codex/skills/configure-notion-mcp/SKILL.md`.

## Ports

Cursor MCP OAuth listens on **8787** (`http://localhost:8787/callback`).
Collie was moved to **8788** so those callbacks are free. The office
Cloudflare tunnel for `collie.efwmcstyle.ccwu.cc` must target
`http://127.0.0.1:8788`.

## How to log in

1. Confirm 8787 is free: `ss -ltn | rtk grep 8787`.
2. Prefer `cursor-agent mcp login notion` (Nix package; not `~/.local/bin/agent`).
3. Finish Allow in the desktop browser. Do not `curl` `/callback`.
4. If CLI login 404s (Brave service worker on `:8787`) or `mcp_auth` is
   unavailable in an agent chat, run
   `.codex/skills/configure-notion-mcp/scripts/notion-mcp-login.py`.
5. Verify: `cursor-agent mcp list-tools notion`.

Copy `notion.tokens` into every project `mcp-auth.json` the CLI will use.
A Cursor Agent chat can stay `needsAuth` after CLI login; use `cursor-agent`
or a new desktop chat.

## Do not

- Put Collie back on 8787.
- Print access or refresh tokens.
- Reuse an old Notion authorize tab after the listener restarted
  (`Client ID mismatch`).
- Paste a truncated authorize URL (`Missing redirect_uri` on
  `mcp.notion.com/callback`).
