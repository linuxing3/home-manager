#!/usr/bin/env bash
set -euo pipefail

FLAKE_REF="${1:-github:linuxing3/home-manager/aarch64}"
APP_NAME="${2:-bootstrap}"

exec nix run "${FLAKE_REF}#${APP_NAME}" -- "${@:3}"
