# CLIamp and Quickshell

## CLIamp

CLIamp is installed from the project overlay at `overlays/packages/cliamp.nix` and included by `modules/shell/cli-collection.nix`.

Source: <https://www.cliamp.stream/> and <https://github.com/bjarneo/cliamp>.

The current package pins official release 2.2.0 binaries for Linux ARM64 and AMD64. This is deliberate: CLIamp 2.2.0 requires Go 1.26.6, while the pinned Nixpkgs currently provides Go 1.26.4. The package does not bypass the upstream toolchain constraint. It verifies release checksums, patches the ELF for Nix, supplies `libasound`, configures ALSA/PipeWire plugin discovery, and wraps optional `ffmpeg` and `yt-dlp` tools into PATH.

When Nixpkgs provides a sufficient Go version, rebuilding from upstream source may replace the binary package after validating audio and provider behavior.

## Quickshell

Quickshell 0.3.0 is the release package from pinned Nixpkgs, added in `profiles/work/packages.nix`.

Guide: <https://quickshell.org/docs/v0.3.0/guide/install-setup/#nix>.

No separate flake input is necessary for this release. If the project later tracks Quickshell master or another tag, make its Nixpkgs input follow the project Nixpkgs; mismatched Qt dependencies can crash at runtime.

## Verification

```sh
nix build --no-link .#homeConfigurations.Designers.activationPackage
$(nix eval --raw '.#homeConfigurations.Designers.pkgs.cliamp')/bin/cliamp --version
$(nix eval --raw '.#homeConfigurations.Designers.pkgs.quickshell')/bin/quickshell --version
```

Operational skill: `.codex/skills/install-cliamp-quickshell/SKILL.md`.
