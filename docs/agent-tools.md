# Agent tools

Home Manager installs RTK, fff-mcp, Pi (llm-agents package + UOS wrapper), pi-switch, Herdr, Collie, and Cursor Agent from `modules/app/ai-agents/`. The work profile only imports that tree.

## Layout

| Path | Owns |
| --- | --- |
| `modules/app/ai-agents/rtk.nix` | `pkgs.rtk`, `pkgs.fff-mcp`, telemetry, PATH |
| `modules/app/ai-agents/pi.nix` | llm-agents Pi, UOS loader shim, `pi-switch` on PATH, settings merge |
| `modules/app/ai-agents/herdr/` | llm-agents Herdr, plugins, xclip |
| `modules/app/ai-agents/collie.nix` | llm-agents Collie CLI and user unit |
| `modules/app/ai-agents/cursor/default.nix` | Cursor shim and llm-agents `cursor-agent` |
| `modules/app/ai-agents/nix-profile-cleanup.nix` | Drops leftover `nix profile` copies of herdr/pi/collie/cursor-agent |
| `modules/app/ai-agents/codex/default.nix` | Codex files, TOML merge, `rtk init --codex`, fff MCP |
| `overlays/packages/rtk.nix` | Pinned RTK release |
| `overlays/packages/fff-mcp.nix` | Pinned fff-mcp release |
| `overlays/packages/cli-proxy-api.nix` | Pinned CLIProxyAPI Linux binary |
| `overlays/packages/dsh.nix` | DeepSeek Harness CLI wrapper (source checkout + pnpm; npm rc.7 graph is incomplete) |

See `.codex/skills/agent-tools/SKILL.md` for the operational checklist.

## Why Pi is wrapped

On aarch64 UOS, the llm-agents Bun binary is started with `/lib/ld-linux-aarch64.so.1` so it does not mix the Nix dynamic loader with UOS libc.

## Why pi-switch is a Nix package

`@heihei0299/pi-switch` publishes native addons for x86_64 Linux and Darwin, not aarch64 Linux. The overlay builds `libpi_switch_native.so` and wraps `bin/pi-switch.js` with Nix `nodejs`.
