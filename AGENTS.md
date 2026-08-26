# Repository Guidelines

## Project Structure & Module Organization

This repository defines a Nix flake with two layers: Home Manager (`homeConfigurations`) and NixOS (`nixosConfigurations`). `flake.nix` is the entry point: it loads host and user values from `nix/`, selects a profile from `profiles/<profile>/home.nix`, applies package overrides from `overlays/`, and imports NixOS hosts from `flake/nixos.nix`.

- `flake/`: development shells, packages/apps, quality checks, and NixOS flake outputs.
- `nix/`: machine identity and user-level settings (shared by both layers).
- `nixos/`: NixOS host modules (boot, kernel, hardware, display, printing). Not a nested flake.
- `profiles/work/`: the active Home Manager module for the `work` profile. It imports `packages.nix` and `modules/app/ai-agents`.
- `modules/app/ai-agents/`: one submodule per AI agent (Codex, Cursor, Pi, Herdr, and related MCP/tools).
- `modules/shared/oxwm/`: oxwm session scripts and wrappers used by both Home Manager and NixOS.
- `overlays/packages/`: focused overrides for individual packages such as `nnn`, `st`, `rtk`, `pi-switch`, `cli-proxy-api`, and `dsh`.
- `docs/ai-agents.md` and `docs/agent-tools.md`: agent module map and tool notes.
- `flake.lock`: pinned dependency revisions; update it intentionally and review input changes.

Keep reusable logic in the appropriate module rather than expanding `flake.nix` or `profiles/work/home.nix`. Home Manager modules stay under `modules/` (new ones may use `modules/home/`); NixOS modules stay under `nixos/`. Name new Nix files and directories with lowercase, descriptive, hyphenated names.

Commands:

- `home-manager switch --flake .#Designers` — user environment.
- `sudo nixos-rebuild switch --flake .#nvme-p6-phytium` — live NixOS host. Do not switch `#sda-phytium` while root is NVMe.

## Build, Test, and Development Commands

- `nix develop`: enter the project shell with Alejandra, Statix, Deadnix, Nix language servers, and Agenix.
- `nix flake check`: run formatting, lint, and syntax checks defined in `flake/checks.nix` (does not eval the Phytium vendor kernel).
- `nix build`: build the default `home-manager-switch` package without activating it.
- `nix build .#homeConfigurations.Designers.activationPackage`: Home Manager closure without activating.
- `nix build .#nixosConfigurations.nvme-p6-phytium.config.system.build.toplevel`: NixOS closure without switching.
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

## AI Browser Automation

Use the Nix-installed `agent-browser` for headless browser automation. Read its
version-matched core guidance with `agent-browser skills get core --full` before
complex interactions. Keep graphical links and OAuth flows on the configured
desktop `BROWSER`; do not replace desktop MIME associations with
`agent-browser`.
