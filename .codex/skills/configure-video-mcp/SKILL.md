---
name: configure-video-mcp
description: >-
  Use when Veo MCP tools fail, GEMINI_API_KEY is missing, Google reports
  prepaid credits depleted (429), Higgsfield MCP shows needsAuth, or the user
  asks to generate video from Cursor via veo-mcp or higgsfield.
---

# Veo and Higgsfield MCP

HM registers both in `modules/app/ai-agents/mcp-lib.nix`, then
`cursor/default.nix` and `kiro.nix`. Do not put keys in git.

## Veo (stdio)

Wrapper: `veo-mcp` on PATH. Server:
`modules/app/ai-agents/veo-mcp/server.py`. Key file:
`~/.config/veo-mcp/env` (mode 600). Output: `~/Videos/veo`.

```
GEMINI_API_KEY=
```

Tools: `veo_account_status`, `veo_estimate_cost`, `veo_generate_video`.
Models include `veo-3.1-generate-preview`, `veo-3.1-fast-generate-preview`,
`veo-3.1-lite-generate-preview`. Official USD/sec with audio (720p): Lite
$0.05, Fast $0.10, Standard $0.40.

| Symptom | Cause |
|---|---|
| Missing key | Empty `~/.config/veo-mcp/env` |
| **429** prepaid depleted | AI Studio prepaid, not the GCP billing card |
| Untracked `server.py` | Flake ignores untracked files; `git add` before `home-manager switch` |

Top-up: https://aistudio.google.com/ . After credit lands, re-run
`veo_account_status`. Do not drive Google Flow with `agent-browser`; Flow
quota is not AI Studio prepaid.

`veo-mcp-help` seeds the env template if missing.

## Higgsfield (HTTP OAuth)

URL: `https://mcp.higgsfield.ai/mcp`. No API key. Cursor plugin
`plugin-higgsfield-higgsfield` stays `needsAuth` until the **desktop IDE**
completes OAuth (`mcp_auth` from this agent cannot open the interactive
login).

Cursor: Customize → MCP → higgsfield → Connect. Needs a Higgsfield account
and a paid plan. After auth, start a new Agent chat before expecting tools.
