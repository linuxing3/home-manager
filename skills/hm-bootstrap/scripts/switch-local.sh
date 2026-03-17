#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

USERNAME="${1:-$(tr -d '"[:space:]' < nix/username.nix)}"
BACKUP_EXT="${HM_BACKUP_EXT:-hm-bak}"

exec home-manager switch --flake ".#${USERNAME}" -b "$BACKUP_EXT" "${@:2}"
