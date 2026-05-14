set shell := ["bash", "-euo", "pipefail", "-c"]

flake_user := `tr -d '"' < nix/username.nix`
quality_paths := "flake/devshells.nix flake/packages.nix flake/checks.nix"
nix_tree_paths := "flake modules nix overlays profiles security"

run: build
    nix run

build:
    nix build

repl:
    nix repl

dev:
    nix develop

fmt:
    alejandra {{quality_paths}}

fmt-check:
    alejandra --check {{quality_paths}}

lint:
    statix check flake
    deadnix --no-lambda-pattern-names {{quality_paths}}

syntax:
    find {{nix_tree_paths}} -name '*.nix' -print0 | xargs -0 -n1 sh -c 'nix-instantiate --parse "$1" >/dev/null' _
    nix-instantiate --parse home.nix >/dev/null

check: fmt-check lint syntax

build-home:
    mkdir -p .cache/nix
    XDG_CACHE_HOME=$PWD/.cache nix build .#homeConfigurations.{{flake_user}}.activationPackage --no-link

build-system:
    mkdir -p .cache/nix
    XDG_CACHE_HOME=$PWD/.cache nix build .#nixosConfigurations.system.config.system.build.toplevel --no-link
