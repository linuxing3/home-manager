# Repository Guidelines

## Project Structure & Module Organization

This repository defines a Nix flake for a Home Manager environment. `flake.nix` is the entry point: it loads host and user values from `nix/`, selects a profile from `profiles/<profile>/home.nix`, and applies package overrides from `overlays/`.

- `flake/`: development shells, packages/apps, and quality checks.
- `nix/`: machine identity and user-level settings.
- `profiles/work/`: the active Home Manager module for the `work` profile.
- `overlays/packages/`: focused overrides for individual packages such as `nnn` and `st`.
- `flake.lock`: pinned dependency revisions; update it intentionally and review input changes.

Keep reusable logic in the appropriate module rather than expanding `flake.nix`. Name new Nix files and directories with lowercase, descriptive, hyphenated names.

## Build, Test, and Development Commands

- `nix develop`: enter the project shell with Alejandra, Statix, Deadnix, Nix language servers, and Agenix.
- `nix flake check`: run formatting, lint, and syntax checks defined in `flake/checks.nix`.
- `nix build`: build the default `home-manager-switch` package without activating it.
- `nix run`: build and activate the configured Home Manager profile. Review configuration changes first because this modifies the user environment.
- `nix flake lock --update-input <input>`: update one dependency instead of refreshing every input.

## Coding Style & Naming Conventions

Use two-space indentation and idiomatic Nix formatting. Run `alejandra <file-or-directory>` before submitting changes. Prefer small modules, `let` bindings for repeated expressions, and inherited attributes (`inherit pkgs;`) where clear. Keep package override filenames aligned with their exported package names.

## Testing Guidelines

There is no separate unit-test suite. Treat `nix flake check` as the required validation step. New flake infrastructure should be added to the relevant `qualityPaths` or check definition so it is covered by formatting, Statix, Deadnix, and parse validation. Build affected outputs when changing profiles, packages, or overlays.

## Commit & Pull Request Guidelines

No commit history is available in this checkout. Use concise, imperative subjects such as `Add work profile packages` or `Fix st overlay patch`. Keep commits scoped to one logical change. Pull requests should explain the motivation, list affected profiles or hosts, report `nix flake check` results, and call out lock-file, package-source, or activation-impacting changes. Include screenshots only for visible desktop or theme changes.

## Security & Configuration Tips

Do not commit plaintext secrets. Use Agenix-managed encrypted files for sensitive values. Treat password hashes, SSH keys, hostnames, and user settings in `nix/` as sensitive configuration and avoid unrelated edits.
