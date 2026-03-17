# Quick Bootstrap

## Prerequisites

- Nix with flakes enabled
- Network access to GitHub

## One command

```bash
nix run github:linuxing3/home-manager/aarch64#bootstrap
```

## What it does

- Evaluates this flake
- Runs Home Manager switch for the configured user profile
- Uses backup extension `hm-bak` by default (override with `HM_BACKUP_EXT`)

## Common follow-up

```bash
nix run github:linuxing3/home-manager/aarch64#bootstrap -- --show-trace
```

