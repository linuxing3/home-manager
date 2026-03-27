# Incus container workflow

This directory is the source of truth for buildable Incus images.

## Layout

- `*.nix`: top-level NixOS container modules discovered by the flake
- `build.py`: builds Nix image outputs and imports them into Incus
- `relaunch.py`: relaunches stale running Incus instances
- `instance_map.json` (optional): maps `instance-name` to `image-alias`

By default, both scripts run `incus` through the Docker image `ghcr.io/cmspam/incus-docker`.
Set `INCUS_RUNTIME=host` if you want to call a local `incus` binary directly.
Set `INCUS_DOCKER_IMAGE` if you need a different image tag.

## Add a new container image

1. Add a new top-level `containers/<name>.nix`.
2. Build outputs from the repo root:
   - `nix build .#<name>`
   - `nix build .#<name>-metadata`

The flake auto-discovers top-level `.nix` files in this directory.

## Build and import images

From the repo root:

- List discoverable images:
  - `python3 containers/build.py --list`
- Build all images and import into Incus:
  - `python3 containers/build.py`
- Build only selected images:
  - `python3 containers/build.py base`
- Build images used by currently running instances:
  - `python3 containers/build.py --nightly`
- Show exact commands without execution:
  - `python3 containers/build.py --dry-run base`

## Relaunch stale running instances

`relaunch.py` compares each running instance `volatile.base_image` fingerprint with the current fingerprint behind the image alias. It only relaunches stale instances.

- Dry run:
  - `python3 containers/relaunch.py --dry-run`
- Execute:
  - `python3 containers/relaunch.py`

If an instance profile with the same name does not exist, the instance is skipped.

## Optional instance mapping

Create `containers/instance_map.json` when instance names differ from image aliases:

```json
{
  "prod-web-1": "base"
}
```

Both scripts read this file by default and also accept `--instance-map <path>`.
