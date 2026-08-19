# Agent tools

Home Manager installs RTK, fff-mcp, the Pi UOS wrapper, and pi-switch from `modules/app/ai-agents/`. The work profile only imports that tree.

## Layout

| Path | Owns |
| --- | --- |
| `modules/app/ai-agents/rtk.nix` | `pkgs.rtk`, `pkgs.fff-mcp`, telemetry, PATH |
| `modules/app/ai-agents/pi.nix` | Pi loader shim, `pi-switch` on PATH, settings merge, `pi install` |
| `modules/app/ai-agents/codex/default.nix` | Codex files, TOML merge, `rtk init --codex`, fff MCP |
| `overlays/packages/rtk.nix` | Pinned RTK release |
| `overlays/packages/fff-mcp.nix` | Pinned fff-mcp release |
| `overlays/packages/cli-proxy-api.nix` | Pinned CLIProxyAPI Linux binary |

See `.codex/skills/agent-tools/SKILL.md` for the operational checklist.

## Why Pi is wrapped

On aarch64 UOS, the llm-agents Bun binary is started with `/lib/ld-linux-aarch64.so.1` so it does not mix the Nix dynamic loader with UOS libc.

## Why pi-switch is a Nix package

`@heihei0299/pi-switch` publishes native addons for x86_64 Linux and Darwin, not aarch64 Linux. The overlay builds `libpi_switch_native.so` and wraps `bin/pi-switch.js` with Nix `nodejs`.
