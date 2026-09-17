---
name: install-cliamp-quickshell
description: Use when installing, updating, or repairing CLIamp or Quickshell in this Home Manager flake, especially CLIamp aarch64 binary patching, ALSA plugins, missing ffmpeg or yt-dlp, upstream Go toolchain mismatches, or Quickshell 0.3.0 availability.
---

# Install CLIamp and Quickshell

## CLIamp

`overlays/packages/cliamp.nix` packages the official CLIamp 2.2.0 Linux release binaries for `aarch64-linux` and `x86_64-linux`. `overlays/default.nix` imports the overlay, and `modules/shell/cli-collection.nix` adds `cliamp` to Home Manager.

The upstream v2.2.0 source flake requires Go 1.26.6, while this project’s pinned Nixpkgs provides Go 1.26.4. Do not lower the upstream `go.mod` requirement. Until Nixpkgs catches up, use the release binary and verify its published SHA-256 checksum.

The package must:

- run `autoPatchelfHook` so the release ELF uses Nix’s loader and `libasound`;
- include `alsa-lib`;
- expose ALSA and PipeWire plugin directories through `ALSA_PLUGIN_DIR` for non-NixOS and NixOS audio routing;
- add `ffmpeg-headless` and `yt-dlp` to the wrapped PATH.

## Quickshell

Nixpkgs already provides Quickshell 0.3.0. `profiles/work/packages.nix` adds `quickshell` directly to `home.packages`; no extra flake input is needed for the requested release.

Use the upstream Quickshell flake only when tracking master or a newer tag. If added, its `inputs.nixpkgs.follows = "nixpkgs"` is mandatory to prevent Qt dependency mismatches.

## Verification

```sh
nix build --no-link .#homeConfigurations.Designers.activationPackage
cliamp=$(nix eval --raw '.#homeConfigurations.Designers.pkgs.cliamp')
"$cliamp/bin/cliamp" --version
quickshell=$(nix eval --raw '.#homeConfigurations.Designers.pkgs.quickshell')
"$quickshell/bin/quickshell" --version
```

Expected versions are `cliamp version v2.2.0` and `Quickshell 0.3.0` while those pins remain unchanged.

See `docs/cliamp-quickshell.md` for source links and package ownership.
