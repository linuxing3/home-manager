# AI agent Home Manager modules

All agent configuration for the `work` profile is imported from `modules/app/ai-agents/default.nix`. `profiles/work/home.nix` does not list individual agents.

| Submodule | Responsibility |
| --- | --- |
| `mcp.nix` / `mcp-lib.nix` | Shared Drive (Cursor/Kiro: official HTTP MCP; Codex/Codeium: stdio wrapper), Canva, AWS, Veo, Higgsfield, Notion |
| `rtk.nix` | RTK, fff-mcp, PATH |
| `pi.nix` | llm-agents Pi and UOS loader shim |
| `omp.nix` | oh-my-pi (`omp`) HM module; package from `overlays/packages/omp.nix` release binary |
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

Operational skills live in `.codex/skills/`: `agent-tools`, `use-cf-cli`,
`wrangler`, `repair-cloudflared-office`, `repair-cursor-to-openai`,
`repair-dsh`, `configure-video-mcp`, `configure-notion-mcp`. Prefer `cf`
(1.0.0-beta.12) over Wrangler for API and account work; see `use-cf-cli`.

Plugin and service defaults live in `modules/app/ai-agents/options.nix`:

- `my.ai.herdr.enable` / `package` / `plugins` / `installPlugins` — Herdr from `overlays/packages/herdr.nix` (GitHub static release); plugins still from module
- `my.ai.pi.enable` / `package` — Pi from `overlays/packages/pi.nix` (GitHub release + patchelf) plus UOS loader shim. Default Pi model stays openai-codex.
- `my.ai.omp.enable` / `package` — oh-my-pi (`omp`). Package is the GitHub release binary via `overlays/packages/omp.nix` (patchelf + DT_VERDEF fix); flake input stays only for the Home Manager module. Config is `~/.omp/agent/config.yml` (`programs.omp.settings`) with wizard pinned off. Do not `nix profile add github:can1357/oh-my-pi`.
- `my.ai.collie.enable` / `package` — Collie from `overlays/packages/collie.nix` (GitHub release + patchelf) and Herdr bridge unit on loopback 8788 (`collie.efwmcstyle.ccwu.cc`; 8787 is Cursor MCP OAuth)
- `my.ai.orca.enable` / `package` — llm-agents Orca ADE, `orca serve` on loopback 6768, Cloudflare Tunnel `orca-remote` at `orca.efwmcstyle.ccwu.cc` with pairing URL `https://orca.efwmcstyle.ccwu.cc` (wss)
- `my.ai.cursorAgent.enable` / `package` — llm-agents `cursor-agent`
- Herdr, Pi, OMP, Collie, Orca, and Cursor Agent are Home Manager packages. Do not `nix profile add` them from `github:numtide/llm-agents.nix` or `github:can1357/oh-my-pi`; activation removes those profile names so they cannot collide with `home-manager-path`.
- `my.ai.cliProxyApi.enable` — user unit

nnn plugin scripts are installed from `pkgs.nnn.src` via `my.features.home.nnn.plugins` in `modules/tui/nnn-plugins.nix`.

Non-agent desktop merges (Atuin, Glow, Zellij, SMPlayer, gcloud, SSH cloudflared) stay in `modules/app/personal-configs/`.
