#!/usr/bin/env bash
set -euo pipefail

# Run in repo root.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

USERNAME="$(tr -d '"[:space:]' < nix/username.nix)"

nix flake check --no-build
nix eval ".#homeConfigurations.${USERNAME}.activationPackage.drvPath"
nix eval .#devShells.aarch64-linux.default.drvPath
