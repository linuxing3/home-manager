# Home Manager Bootstrap Skills

This repo is organized so you can bootstrap and maintain a full Home Manager setup quickly.

## Skill 1: One-Key Bootstrap from Remote GitHub

Use this when setting up a machine from scratch.

### Run directly from GitHub branch

```bash
nix run github:linuxing3/home-manager/aarch64#bootstrap
```

Equivalent explicit app:

```bash
nix run github:linuxing3/home-manager/aarch64#home-manager-switch
```

This executes `home-manager switch` for the configured profile/user in this repo.

## Skill 2: Core Settings in One Place

Edit only these files first:

- `nix/username.nix`
- `nix/user-settings.nix`
- `nix/system-settings.nix`

These feed both Home Manager and NixOS module wiring in `flake.nix`.

## Skill 3: WM Switching

Active HM profile imports are in:

- `profiles/work/home.nix`

Toggle one WM module import at a time:

- `modules/wm/xmonad/xmonad.nix`
- `modules/wm/sway/sway.nix`
- `modules/wm/hyprland/hyprland.nix`
- `modules/wm/i3/i3.nix`

## Skill 4: Dev Environment Split

Dev shell is maintained separately in:

- `flake/devshells.nix`

Enter dev shell:

```bash
nix develop
```

## Skill 5: Security Permissions Repair

Sensitive local folders to keep hardened:

- `~/.ssh`
- `~/.gnupg`
- `~/.password-store`
- `~/.config/gh`
- `~/.local/share/keyrings`

Recommended baseline:

- directories: `700`
- private files: `600`
- SSH public keys + known_hosts: `644`

## Skill 6: Validate Before/After Changes

```bash
nix flake check --no-build
nix eval .#homeConfigurations.$(cat nix/username.nix | tr -d '"').activationPackage.drvPath
home-manager switch --flake .#$(cat nix/username.nix | tr -d '"') -b b
```

