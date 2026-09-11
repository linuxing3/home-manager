# AI agent Home Manager modules

All agent configuration for the `work` profile is imported from `modules/app/ai-agents/default.nix`. `profiles/work/home.nix` does not list individual agents.

| Submodule | Responsibility |
| --- | --- |
| `mcp.nix` / `mcp-lib.nix` | Shared Drive (Cursor/Kiro: official HTTP MCP; Codex/Codeium: stdio wrapper), Canva, AWS, Veo, Higgsfield, Notion |
| `rtk.nix` | RTK, fff-mcp, PATH |
| `pi.nix` | llm-agents Pi, UOS loader shim, pi-switch, and the DeepSeek V4 provider combo |
| `codex/` | Static Codex files, config merge, RTK/fff activation |
| `cursor/` | Cursor shim, Cursor Agent package, hooks, MCP, CLI defaults |
| `cursor-to-openai.nix` | Loopback Cursor-to-OpenAI unit and Cloudflare tunnel unit |
| `kiro.nix` | Kiro MCP JSON |
| `codeium.nix` | Codeium MCP JSON |
| `cc-switch.nix` | cc-switch settings merge |
| `herdr/` | Herdr package, config, plugin options, rename, xclip, nnn sync |
| `collie.nix` | Collie package and Herdr bridge user unit |
| `orca.nix` | llm-agents Orca package, `orca serve` user unit, and `orca-remote` tunnel |
| `cliproxyapi.nix` | CLIProxyAPI package, seeded config, and user unit |
| `dsh.nix` | DeepSeek Harness CLI (`dsh`) from GitHub `deepseek-ai/deepseek-harness` |

Operational skills live in `.codex/skills/`: `agent-tools`, `repair-cursor-to-openai`, `repair-dsh`, `configure-video-mcp`, `configure-notion-mcp`.

Plugin and service defaults live in `modules/app/ai-agents/options.nix`:

- `my.ai.herdr.enable` / `package` / `plugins` / `installPlugins` — llm-agents Herdr
- `my.ai.pi.enable` / `package` — llm-agents Pi plus UOS loader shim, pi-switch, and a DeepSeek V4 profile (`deepseek-v4-flash` / `deepseek-v4-pro` / vision). Default Pi model stays openai-codex; put `DEEPSEEK_API_KEY` in `~/.config/pi-switch/env` or SecretSpec.
- `my.ai.collie.enable` / `package` — llm-agents Collie CLI and Herdr bridge unit on loopback 8788 (`collie.efwmcstyle.ccwu.cc`; 8787 is Cursor MCP OAuth)
- `my.ai.orca.enable` / `package` — llm-agents Orca ADE, `orca serve` on loopback 6768, Cloudflare Tunnel `orca-remote` at `orca.efwmcstyle.ccwu.cc` with pairing URL `https://orca.efwmcstyle.ccwu.cc` (wss)
- `my.ai.cursorAgent.enable` / `package` — llm-agents `cursor-agent`
- Herdr, Pi, Collie, Orca, and Cursor Agent are Home Manager packages. Do not `nix profile add` them from `github:numtide/llm-agents.nix`; activation removes those profile names so they cannot collide with `home-manager-path`.
- `my.ai.cliProxyApi.enable` — user unit

nnn plugin scripts are installed from `pkgs.nnn.src` via `my.features.home.nnn.plugins` in `modules/tui/nnn-plugins.nix`.

Non-agent desktop merges (Atuin, Glow, Zellij, SMPlayer, gcloud, SSH cloudflared) stay in `modules/app/personal-configs/`.
