# Incus Container Deployment Design

## Context

This repository is a Home Manager + NixOS flake, not a standalone container project. The reference implementation in `r6t/nixos-r6t` uses a simple pattern:

- `containers/*.nix` are the source of truth for buildable LXC images.
- `nixos-generators` turns each container module into two flake outputs:
  - `name` for the rootfs image
  - `name-metadata` for the matching Incus metadata image
- `containers/build.py` builds and imports the images into Incus.
- `containers/relaunch.py` refreshes running Incus instances when the underlying image changes.

This design adapts that pattern to this repo and keeps the scope Incus-only.

## Goals

1. Add an Incus-native container workflow that mirrors the reference repo’s structure.
2. Make container images discoverable from `containers/*.nix` without hand-maintaining a package list.
3. Provide build and relaunch helpers that work from the repo root.
4. Keep the implementation generic enough that new container modules can be added later without changing the flake wiring.
5. Avoid introducing Podman, Docker, or other container runtimes.

## Non-goals

- Defining a specific application container in this first pass.
- Remote Incus orchestration or multi-host image pushing.
- Converting existing home-manager modules into containers automatically.
- Changing unrelated NixOS, Home Manager, or theme code.

## Proposed Structure

The repository will gain a `containers/` directory with a discoverable module layout:

- `containers/*.nix`
  - Each top-level `.nix` file defines one Incus/LXC image.
  - The filename becomes the flake package name.
- `containers/build.py`
  - Builds one, many, or all containers.
  - Imports the resulting image and metadata into local Incus.
- `containers/relaunch.py`
  - Scans running Incus instances.
  - Compares each instance’s stored base image with the current alias.
  - Stops, deletes, and relaunches instances when the base image changes.
- `containers/README.md`
  - Documents the workflow for adding a new container module and using the scripts.

If shared helpers are needed later, they will live under `containers/lib/` or a similar non-discoverable subdirectory so the top-level discovery rule stays simple.

## Flake Changes

`flake.nix` will gain a `nixos-generators` input and a container package export.

The package export will:

1. Read `builtins.readDir ./containers`.
2. Keep only top-level files with the `.nix` suffix.
3. Derive the package name from the filename stem.
4. Generate two outputs per file:
   - `packages.${system}.<name>` using `format = "lxc"`
   - `packages.${system}.<name>-metadata` using `format = "lxc-metadata"`

The output modules will receive the same special arguments used elsewhere in the flake so they can reference `inputs`, `systemSettings`, and `userSettings` if needed.

## Container Module Contract

Each container module will be written as a normal NixOS module and should be able to stand alone.

Expected contract:

- It may set container-specific services, packages, users, files, and networking.
- It should not assume a full desktop host environment.
- It should not require changes to the flake when a new container is added.
- It should be named to match the desired Incus image alias.

The first implementation will keep the contract lightweight and documented rather than enforcing a custom helper API.

## Build Workflow

`containers/build.py` will support three modes:

1. No arguments: build all discoverable containers.
2. Explicit container names: build only those containers.
3. `--nightly`: build only containers that correspond to currently running Incus instances.

The script will:

1. Discover available containers from `containers/*.nix`.
2. Build `.#<name>` and `.#<name>-metadata` with `nix build`.
3. Copy the resulting tarballs into a temporary staging directory.
4. Import both artifacts into Incus with `incus image import`.
5. Alias the imported image under the container name.

If the image fingerprint is unchanged, the import should be treated as a no-op rather than a failure.

## Relaunch Workflow

`containers/relaunch.py` will:

1. Read the running Incus container list.
2. Resolve each instance name to a container image alias.
3. Query the current image fingerprint for that alias.
4. Compare it with the instance’s `volatile.base_image`.
5. Stop, delete, and relaunch the instance when the base image differs.

The relaunch behavior will preserve the current pattern from the reference repo:

- Require a matching Incus profile before relaunching.
- Use a graceful stop first.
- Fall back to a forced stop only if needed.
- Relaunch the instance from the current image alias with the original profile.

## Instance Mapping

The reference repo supports an instance-to-image mapping for cases where the Incus instance name does not match the flake package name.

This design keeps that idea, but adapts it to the current repository layout:

- The mapping file will live under `containers/` instead of host-specific directories.
- If the file is absent, direct name matching will be used.
- The mapping format will be a simple JSON object of `instance_name -> image_alias`.

This gives the same flexibility as the reference repo without introducing host-specific directory structure that does not exist here today.

## Error Handling

The scripts will fail loudly on real build and Incus errors, but they should also separate user mistakes from system failures.

Expected behaviors:

- Unknown container names should print the available set and exit with a non-zero status.
- Missing `containers/` content should be reported clearly.
- Incus import failures should show the underlying error output.
- Relaunch should skip instances whose profiles are missing, because deleting them would lose configuration.

## Testing Strategy

The first verification pass will be local and deterministic:

1. `nix flake show` or `nix eval` should expose the container packages.
2. `nix build .#<container>` should produce a rootfs tarball.
3. `nix build .#<container>-metadata` should produce the metadata tarball.
4. `containers/build.py --list` should enumerate discovered containers.
5. `containers/build.py --dry-run` should print the exact Incus and Nix commands it would run.

If an Incus daemon is available locally, a real import and relaunch smoke test can be done after the initial wiring is complete.

## Open Constraints

The repo currently does not contain actual container service definitions. That means the first implementation is framework-first:

- The flake and scripts will be ready for container modules.
- A concrete container image can be added once the desired service(s) are identified.

That is intentional. It keeps this change aligned with the reference pattern while avoiding a guess about what should actually run in the container.

