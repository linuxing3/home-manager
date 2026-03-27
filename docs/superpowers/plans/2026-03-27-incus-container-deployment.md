# Incus Container Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an Incus-only container workflow that mirrors `r6t/nixos-r6t`: discoverable `containers/*.nix` images, `nixos-generators` flake outputs, and local build/relaunch helpers.

**Architecture:** Keep the flake as the source of truth for image generation, but factor container discovery into a pure Nix helper so the package export is testable in isolation. Use one minimal base container module to prove the workflow end-to-end, then add Python helpers that discover, build, import, and relaunch Incus containers from the repo root.

**Tech Stack:** Nix flakes, `nixos-generators`, NixOS modules, Python 3, Incus CLI, `just`

---

### Task 1: Add container discovery and flake outputs

**Files:**
- Create: `nix/container-discovery.nix`
- Create: `containers/base.nix`
- Modify: `flake.nix`
- Modify: `flake.lock` if `nixos-generators` needs to be pinned by the lock update

- [ ] **Step 1: Write the failing test**

Run:

```bash
nix eval --raw --expr '
let
  discover = import ./nix/container-discovery.nix;
in builtins.concatStringsSep "," (discover {
  "base.nix" = "regular";
  "README.md" = "regular";
  "lib" = "directory";
})
'
```

Expected: failure because `nix/container-discovery.nix` does not exist yet.

Also run:

```bash
nix build .#base
```

Expected: failure because `base` is not exported from the flake yet.

- [ ] **Step 2: Write minimal implementation**

Create `nix/container-discovery.nix` as a pure function that returns the stems of top-level regular `.nix` files only:

```nix
entries:
let
  names = builtins.attrNames entries;
  isContainerFile = name:
    builtins.match ".*\\.nix" name != null
    && entries.${name} == "regular";
in
builtins.sort builtins.lessThan (
  map (name: builtins.replaceStrings [ ".nix" ] [ "" ] name)
    (builtins.filter isContainerFile names)
)
```

Add `nixos-generators` to `flake.nix` inputs, import the helper, and generate two outputs per discovered container:

```nix
packages.${system} = let
  containerDir = ./containers;
  containerFiles = import ./nix/container-discovery.nix (builtins.readDir containerDir);
  mkContainer = name: {
    inherit name;
    value = nixos-generators.nixosGenerate {
      system = system;
      format = "lxc";
      modules = [ (containerDir + "/${name}.nix") ];
      specialArgs = args;
    };
  };
  mkMetadata = name: {
    name = "${name}-metadata";
    value = nixos-generators.nixosGenerate {
      system = system;
      format = "lxc-metadata";
      modules = [ (containerDir + "/${name}.nix") ];
      specialArgs = args;
    };
  };
in builtins.listToAttrs (builtins.concatMap (name: [ (mkContainer name) (mkMetadata name) ]) containerFiles);
```

Add `containers/base.nix` as a minimal Incus/LXC container module so the workflow is concrete and testable. Keep it small: no desktop assumptions, no host bootloader settings, no unrelated service setup.

- [ ] **Step 3: Run the test to verify it fails correctly**

Run the same `nix eval` commands again after each partial edit. The pure helper command should return `base` once the helper exists, and the package listing should show `base` and `base-metadata` once the flake export is wired.

- [ ] **Step 4: Verify the flake output**

Run:

```bash
nix flake show
nix build .#base
nix build .#base-metadata
```

Expected: the flake lists the new container outputs, and both builds produce tarball-style artifacts.

- [ ] **Step 5: Commit**

```bash
git add nix/container-discovery.nix containers/base.nix flake.nix flake.lock
git commit -m "feat: add incus container outputs"
```

### Task 2: Add Incus build and relaunch helpers

**Files:**
- Create: `containers/build.py`
- Create: `containers/relaunch.py`
- Create: `containers/README.md`

- [ ] **Step 1: Write the failing test**

Run:

```bash
python3 containers/build.py --list
```

Expected: failure because the script does not exist yet.

Run:

```bash
python3 containers/build.py --dry-run base
```

Expected: failure because the build helper does not exist yet.

- [ ] **Step 2: Write minimal implementation**

Implement `containers/build.py` as a standalone Python 3 script that:

```python
def discover_containers() -> list[str]:
    # top-level *.nix only, sorted, stems only

def resolve_targets(args, available):
    # no args => all
    # explicit names => subset
    # --nightly => running Incus instances only

def build_and_import(name: str, dry_run: bool = False) -> None:
    # nix build .#name
    # nix build .#name-metadata
    # incus image import metadata rootfs --alias name

def main() -> None:
    # argparse for --list, --dry-run, --nightly, and positional names
```

Implement `containers/relaunch.py` as a standalone Python 3 script that:

```python
def get_running_instances() -> list[str]:
    # incus list type=container status=running -c n --format csv

def get_image_fingerprint(alias: str) -> str | None:
    # incus image list alias --format csv -c F,l

def get_instance_base_image(name: str) -> str | None:
    # incus config get name volatile.base_image

def stop_delete_launch(name: str, image_alias: str) -> str:
    # profile check, graceful stop, force if needed, delete, launch

def main() -> None:
    # compare running instances against current image aliases and relaunch when stale
```

Use a JSON mapping file for non-matching instance/image names:

```json
{
  "instance-name": "image-alias"
}
```

Document the workflow in `containers/README.md`:

- How to add a new `containers/*.nix` file
- How `base` and `base-metadata` are generated
- How to use `containers/build.py --list`
- How to use `containers/relaunch.py --dry-run`

- [ ] **Step 3: Run the test to verify it fails correctly**

Run:

```bash
python3 containers/build.py --list
python3 containers/build.py --dry-run base
python3 containers/relaunch.py --dry-run
```

Expected: after the scripts exist, `--list` should print the discovered container names, and the dry-run paths should print the exact `nix` and `incus` commands without modifying the system.

- [ ] **Step 4: Verify with a local smoke test**

Run:

```bash
python3 containers/build.py --list
python3 containers/build.py --dry-run base
```

Then, if Incus is available on the machine:

```bash
python3 containers/build.py base
python3 containers/relaunch.py --dry-run
```

Expected: the scripts complete cleanly and the dry-run relaunch logic reports whether the current instance is already on the latest image.

- [ ] **Step 5: Commit**

```bash
git add containers/build.py containers/relaunch.py containers/README.md
git commit -m "feat: add incus container scripts"
```

### Task 3: Add developer entry points and repo-level verification

**Files:**
- Modify: `justfile`
- Modify: `flake.nix` if a `checks` output is added for container discovery or build validation

- [ ] **Step 1: Write the failing test**

Run:

```bash
just containers-build
```

Expected: failure because there is no dedicated Incus container shortcut yet.

Run:

```bash
nix flake check
```

Expected: if checks are added, this should exercise the new container wiring; before the change, it has no container-specific coverage.

- [ ] **Step 2: Write minimal implementation**

Add concise shortcuts to `justfile` so the new workflow is easy to invoke from the repo root:

```just
containers-build:
    python3 containers/build.py

containers-relaunch:
    python3 containers/relaunch.py
```

If the flake gets a `checks` output, keep it narrow and deterministic. A good check is a pure discovery assertion plus a package-exposure assertion that does not require Incus to be installed.

- [ ] **Step 3: Run the test to verify it fails correctly**

Run:

```bash
just containers-build
nix flake check
```

Expected: `just containers-build` should call the helper script, and `nix flake check` should complete without container-related regressions once the outputs are wired.

- [ ] **Step 4: Verify the final state**

Run:

```bash
nix flake show
nix build .#base
nix build .#base-metadata
python3 containers/build.py --list
python3 containers/relaunch.py --dry-run
```

Expected: the flake exposes the container outputs, the base image builds, and both helper scripts behave deterministically in dry-run mode.

- [ ] **Step 5: Commit**

```bash
git add justfile flake.nix
git commit -m "feat: add container workflow shortcuts"
```

## Coverage Check

- Spec goal 1: covered by Task 1 and Task 2.
- Spec goal 2: covered by Task 1.
- Spec goal 3: covered by Task 2.
- Spec goal 4: covered by Task 1 and Task 2.
- Spec goal 5: covered by the explicit Incus-only scope in Task 1 and Task 2.

## Notes for implementers

- Keep `containers/*.nix` as the only discovery surface. Do not recurse into helper directories.
- Do not add Podman, Docker, or VM-specific branches.
- Preserve the current dirty worktree; do not revert unrelated user changes.
- Use `nix build` and `nix eval` as the primary verification path. Only reach for Incus runtime commands when a local daemon is available.
