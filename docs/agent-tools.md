# Agent tools

Home Manager installs RTK, fff-mcp, Pi (llm-agents package + UOS wrapper), oh-my-pi (`omp`), pi-switch, Herdr, Collie, and Cursor Agent from `modules/app/ai-agents/`. The work profile only imports that tree.

## Layout

| Path | Owns |
| --- | --- |
| `modules/app/ai-agents/rtk.nix` | `pkgs.rtk`, `pkgs.fff-mcp`, telemetry, PATH |
| `modules/app/ai-agents/pi.nix` | llm-agents Pi, UOS loader shim, `pi-switch` on PATH, settings merge, DeepSeek V4 provider |
| `modules/app/ai-agents/omp.nix` | oh-my-pi (`omp`) Home Manager module and `~/.omp/agent/config.yml` (wizard off; theme/model pinned) |
| `overlays/packages/herdr.nix` | GitHub static release (`herdr-linux-aarch64`/`x86_64`) |
| `overlays/packages/pi.nix` | GitHub release tarball (`pi-linux-arm64`/`x64`) + autoPatchelf + DT_VERDEF |
| `overlays/packages/collie.nix` | GitHub release tarball (`collie-*-linux-arm64`/`x64`) + autoPatchelf + DT_VERDEF |
| `overlays/packages/omp.nix` | GitHub release binary (`omp-linux-arm64`/`x64`) + autoPatchelf + DT_VERDEF repair |
| `modules/app/ai-agents/herdr/` | llm-agents Herdr, plugins, xclip |
| `modules/app/ai-agents/collie.nix` | llm-agents Collie CLI and user unit |
| `modules/app/ai-agents/orca.nix` | llm-agents Orca, `orca serve`, `orca-remote` tunnel |
| `modules/app/ai-agents/cursor/default.nix` | Cursor shim and llm-agents `cursor-agent` |
| `modules/app/ai-agents/nix-profile-cleanup.nix` | Drops leftover `nix profile` copies of herdr/pi/omp/collie/cursor-agent |
| `modules/app/ai-agents/codex/default.nix` | Codex files, TOML merge, `rtk init --codex`, fff MCP |
| `overlays/packages/rtk.nix` | Pinned RTK release |
| `overlays/packages/fff-mcp.nix` | Pinned fff-mcp release |
| `overlays/packages/cli-proxy-api.nix` | Pinned CLIProxyAPI Linux binary |
| `overlays/packages/dsh.nix` | DeepSeek Harness CLI wrapper (source checkout + pnpm). npm cache is `~/.cache/dsh-npm` (not root-owned `~/.npm`). Boot fixes: hoist profile packages into checkout `node_modules`, fetch arm64 landlock prebuild, run with `node --expose-internals`. Web: `dsh web --no-open` on `127.0.0.1:3080`. |

See `.codex/skills/agent-tools/SKILL.md` for the operational checklist.
Host restore: `.codex/skills/repair-cursor-to-openai/SKILL.md`,
`.codex/skills/repair-dsh/SKILL.md`, `.codex/skills/configure-video-mcp/SKILL.md`,
`.codex/skills/configure-notion-mcp/SKILL.md`. Notion MCP: `docs/notion-mcp.md`.

Drive MCP: Cursor and Kiro use Google's remote HTTP server
(`https://drivemcp.googleapis.com/mcp/v1`). Complete Google sign-in in the
desktop client once. The stdio `gdrive-mcp` wrapper (Codex/Codeium) keeps npm
off root-owned `~/.npm` by using `~/.cache/gdrive-mcp-npm`.

## Why Pi is wrapped

On aarch64 UOS, the llm-agents Bun binary is started with `/lib/ld-linux-aarch64.so.1` so it does not mix the Nix dynamic loader with UOS libc.

## Why pi-switch is a Nix package

`@heihei0299/pi-switch` publishes native addons for x86_64 Linux and Darwin, not aarch64 Linux. The overlay builds `libpi_switch_native.so` and wraps `bin/pi-switch.js` with Nix `nodejs`.
