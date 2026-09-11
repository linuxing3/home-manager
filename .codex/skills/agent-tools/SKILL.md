---
name: agent-tools
description: >-
  Use when installing, wrapping, or debugging RTK, fff-mcp, the UOS Pi loader,
  pi-switch, the DeepSeek V4 Pi combo, dsh, cursor-to-openai, Veo MCP, or
  Higgsfield MCP on this Home Manager host.
---

# Agent tools on UOS

These tools live in `modules/app/ai-agents/`, not in the work profile `home.nix`.

| Tool | Module | Role |
| --- | --- | --- |
| RTK | `rtk.nix` | Token-compact shell proxy; telemetry off |
| fff-mcp | `rtk.nix` + `codex/default.nix` | Fast file MCP; Codex registers it on activation |
| Pi | `pi.nix` | UOS `ld-linux-aarch64` wrapper around the Nix Pi binary |
| pi-switch | `pi.nix` + `overlays/packages/pi-switch.nix` | Profile switcher CLI on `~/.nix-profile/bin` |
| DeepSeek (Pi) | `pi.nix` | V4 profile `pi-switch-deepseek`; key `$DEEPSEEK_API_KEY` |
| dsh | `dsh.nix` + `overlays/packages/dsh.nix` | DeepSeek Harness CLI; web on 3080 |
| cursor-to-openai | `cursor-to-openai.nix` | OpenAI-compatible Cursor proxy on 3010 |
| veo-mcp | `mcp-lib.nix` + `veo-mcp/server.py` | Gemini Veo video MCP |
| higgsfield | `mcp-lib.nix` | HTTP MCP; Cursor desktop OAuth |
| notion | `mcp-lib.nix` | HTTP MCP `https://mcp.notion.com/mcp`; OAuth on 8787 |
| gdrive | `mcp-lib.nix` | Cursor/Kiro: `https://drivemcp.googleapis.com/mcp/v1`; Codex: stdio `gdrive-mcp` with `~/.cache/gdrive-mcp-npm` |

## RTK

Package overlay: `overlays/packages/rtk.nix` (aarch64 GNU tarball, autoPatchelf). Config: `~/.config/rtk/config.toml` with telemetry disabled.

Codex integration is `rtk init -g --codex` in `codex/default.nix` after packages are linked. Skip Codex MCP registration when `~/.nix-profile/bin/codex` is missing.

Prefer `rtk git`, `rtk rg`, and other RTK wrappers for inspect commands. Do not set `RTK_DISABLED`.

## fff-mcp

Overlay: `overlays/packages/fff-mcp.nix`. Codex MCP command must be `$HOME/.nix-profile/bin/fff-mcp`. Activation removes and re-adds `fff` when the command path drifts.

## Pi wrapper

`llm-agents.nix` ships a Bun standalone that mixes the Nix loader with UOS libc on aarch64. `~/.nix-profile/bin/pi` is a `hiPrio` wrapper: on UOS it execs `/lib/ld-linux-aarch64.so.1` against `libexec/pi/pi`; on NixOS (`/etc/NIXOS`) it execs the Nix-wrapped binary because that path is stub-ld.

## pi-switch

Install the Pi extension with `pi install npm:@heihei0299/pi-switch` (activation does this if the npm tree is missing). Keep `packages` in `~/.pi/agent/settings.json`.

The npm tarball has no aarch64-linux native addon. PATH uses the Nix overlay `pkgs.pi-switch` (GitHub `v20260807`, local `libpi_switch_native.so` as `pi-switch-native.linux-arm64-gnu.node`).

```sh
command -v pi-switch
pi-switch doctor
pi-switch --help
pi-switch provider show deepseek
```

Home Manager seeds a DeepSeek V4 combo:

- Profile: `~/.pi-switch/config.json` → `profiles.deepseek`
- Pi registry: `~/.pi/agent/models.json` → `providers.pi-switch-deepseek`
- Models: `deepseek-v4-flash`, `deepseek-v4-pro`, `deepseek-v4-flash-vision-exp`
- Key: `$DEEPSEEK_API_KEY` from `~/.config/pi-switch/env` (mode 600, not in git) or SecretSpec item `DEEPSEEK_API_KEY`

Pi default stays `openai-codex` / `gpt-5.6-terra`. In Pi, `/model` and pick the `pi-switch-deepseek` provider. Do not use the retired `deepseek-chat` / `deepseek-reasoner` IDs.

Do not `npm install -g` this package on this host; it will fail at native load.

## Related skills

- **REQUIRED:** `repair-cursor-to-openai` for the 3010 proxy and tunnel
- **REQUIRED:** `repair-dsh` for DeepSeek Harness web / npm EACCES
- **REQUIRED:** `configure-video-mcp` for Veo and Higgsfield
- **REQUIRED:** `configure-notion-mcp` for hosted Notion MCP OAuth

## PATH

Keep `~/.nix-profile/bin` ahead of `~/.local/bin`. Cursor Agent rewrites `~/.local/bin` and would shadow or delete Home Manager shims. Put wrappers in `home.packages` (use `lib.hiPrio` when the unwrapped package is also installed).
