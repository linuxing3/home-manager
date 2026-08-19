# AI agent Home Manager modules

All agent configuration for the `work` profile is imported from `modules/app/ai-agents/default.nix`. `profiles/work/home.nix` does not list individual agents.

| Submodule | Responsibility |
| --- | --- |
| `mcp.nix` / `mcp-lib.nix` | Shared Drive, Canva, and AWS MCP wrappers |
| `rtk.nix` | RTK, fff-mcp, PATH |
| `pi.nix` | Pi wrapper and pi-switch |
| `codex/` | Static Codex files, config merge, RTK/fff activation |
| `cursor/` | Cursor shim, hooks, MCP, CLI defaults, tunnel YAML |
| `cursor-to-openai.nix` | Loopback Cursor-to-OpenAI unit and Cloudflare tunnel unit |
| `kiro.nix` | Kiro MCP JSON |
| `codeium.nix` | Codeium MCP JSON |
| `cc-switch.nix` | cc-switch settings merge |
| `herdr/` | Herdr package, config, plugin options, rename, xclip, nnn sync |
| `collie.nix` | Collie Herdr bridge user unit |
| `cliproxyapi.nix` | CLIProxyAPI package, seeded config, and user unit |

Plugin and service defaults live in `modules/app/ai-agents/options.nix`:

- `my.ai.herdr.plugins` — GitHub sources installed on activation
- `my.ai.herdr.installPlugins` — toggle activation install
- `my.ai.collie.enable` / `my.ai.cliProxyApi.enable` — user units

nnn plugin scripts are installed from `pkgs.nnn.src` via `my.features.home.nnn.plugins` in `modules/tui/nnn-plugins.nix`.

Non-agent desktop merges (Atuin, Glow, Zellij, SMPlayer, gcloud, SSH cloudflared) stay in `modules/app/personal-configs/`.
