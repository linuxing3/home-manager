---
name: agent-tools
description: Use when installing, wrapping, or debugging RTK, fff-mcp, the UOS Pi loader, or pi-switch on this Home Manager host.
---

# Agent tools on UOS

These tools live in `modules/app/ai-agents/`, not in the work profile `home.nix`.

| Tool | Module | Role |
| --- | --- | --- |
| RTK | `rtk.nix` | Token-compact shell proxy; telemetry off |
| fff-mcp | `rtk.nix` + `codex/default.nix` | Fast file MCP; Codex registers it on activation |
| Pi | `pi.nix` | UOS `ld-linux-aarch64` wrapper around the Nix Pi binary |
| pi-switch | `pi.nix` + `overlays/packages/pi-switch.nix` | Profile switcher CLI on `~/.local/bin` |

## RTK

Package overlay: `overlays/packages/rtk.nix` (aarch64 GNU tarball, autoPatchelf). Config: `~/.config/rtk/config.toml` with telemetry disabled.

Codex integration is `rtk init -g --codex` in `codex/default.nix` after packages are linked. Skip Codex MCP registration when `~/.nix-profile/bin/codex` is missing.

Prefer `rtk git`, `rtk rg`, and other RTK wrappers for inspect commands. Do not set `RTK_DISABLED`.

## fff-mcp

Overlay: `overlays/packages/fff-mcp.nix`. Codex MCP command must be `$HOME/.nix-profile/bin/fff-mcp`. Activation removes and re-adds `fff` when the command path drifts.

## Pi wrapper

`llm-agents.nix` ships a Bun standalone that mixes the Nix loader with UOS libc on aarch64. `~/.local/bin/pi` execs `/lib/ld-linux-aarch64.so.1` against `libexec/pi/pi` when that loader exists.

Zsh prepends `~/.local/bin` after UOS rewrites PATH so this shim wins over the profile binary.

## pi-switch

Install the Pi extension with `pi install npm:@heihei0299/pi-switch` (activation does this if the npm tree is missing). Keep `packages` in `~/.pi/agent/settings.json`.

The npm tarball has no aarch64-linux native addon. PATH uses the Nix overlay `pkgs.pi-switch` (GitHub `v20260807`, local `libpi_switch_native.so` as `pi-switch-native.linux-arm64-gnu.node`).

```sh
command -v pi-switch
pi-switch doctor
pi-switch --help
```

Do not `npm install -g` this package on this host; it will fail at native load.

## PATH

`rtk.nix` appends `~/.nix-profile/bin` for bash and restores `~/.local/bin` first on zsh. Put agent shims in `home.file.".local/bin/..."`.
