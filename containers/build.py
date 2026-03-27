#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
DEFAULT_MAP = SCRIPT_DIR / "instance_map.json"


def run_checked(cmd: list[str], cwd: Path = REPO_ROOT, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        capture_output=capture,
        check=True,
    )


def print_cmd(cmd: Iterable[str]) -> None:
    print(" ".join(shlex.quote(part) for part in cmd))


def discover_containers() -> list[str]:
    names: list[str] = []
    for path in sorted(SCRIPT_DIR.glob("*.nix")):
        if path.is_file():
            names.append(path.stem)
    return names


def find_tarball(output_dir: Path) -> Path:
    tarball_dir = output_dir / "tarball"
    if not tarball_dir.is_dir():
        raise RuntimeError(f"missing tarball directory: {tarball_dir}")
    tarballs = sorted(tarball_dir.glob("*.tar.xz"))
    if len(tarballs) != 1:
        raise RuntimeError(f"expected exactly one tarball in {tarball_dir}, found {len(tarballs)}")
    return tarballs[0]


def load_instance_map(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text())
    if not isinstance(data, dict):
        raise ValueError(f"instance map must be a JSON object: {path}")
    result: dict[str, str] = {}
    for key, value in data.items():
        if not isinstance(key, str) or not isinstance(value, str):
            raise ValueError(f"instance map keys and values must be strings: {path}")
        result[key] = value
    return result


def get_running_instances(dry_run: bool) -> list[str]:
    cmd = ["incus", "list", "type=container", "status=running", "-c", "n", "--format", "csv"]
    if dry_run:
        print_cmd(cmd)
        return []
    proc = run_checked(cmd, capture=True)
    lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    return lines


def resolve_targets(
    *,
    requested: list[str],
    nightly: bool,
    dry_run: bool,
    available: list[str],
    instance_map: dict[str, str],
) -> list[str]:
    if not available:
        raise ValueError("no containers discovered in containers/*.nix")
    if requested and nightly:
        raise ValueError("cannot use explicit container names with --nightly")
    if requested:
        unknown = sorted(set(requested) - set(available))
        if unknown:
            joined = ", ".join(unknown)
            raise ValueError(f"unknown containers: {joined}")
        return sorted(dict.fromkeys(requested))
    if nightly:
        instances = get_running_instances(dry_run=dry_run)
        aliases = {instance_map.get(instance, instance) for instance in instances}
        targets = sorted(alias for alias in aliases if alias in set(available))
        return targets
    return available


def build_one(name: str, dry_run: bool) -> tuple[Path, Path]:
    build_cmd = ["nix", "build", f".#{name}", "--no-link", "--print-out-paths"]
    metadata_cmd = ["nix", "build", f".#{name}-metadata", "--no-link", "--print-out-paths"]
    if dry_run:
        print_cmd(build_cmd)
        print_cmd(metadata_cmd)
        return (
            Path(f"/nix/store/{name}-metadata-output/tarball/<metadata>.tar.xz"),
            Path(f"/nix/store/{name}-output/tarball/<rootfs>.tar.xz"),
        )
    metadata_out = run_checked(metadata_cmd, capture=True).stdout.strip()
    rootfs_out = run_checked(build_cmd, capture=True).stdout.strip()
    if not metadata_out or not rootfs_out:
        raise RuntimeError(f"failed to obtain build outputs for {name}")
    metadata_tarball = find_tarball(Path(metadata_out))
    rootfs_tarball = find_tarball(Path(rootfs_out))
    return (metadata_tarball, rootfs_tarball)


def import_one(name: str, metadata_path: Path, rootfs_path: Path, dry_run: bool) -> None:
    cmd = ["incus", "image", "import", str(metadata_path), str(rootfs_path), "--alias", name]
    if dry_run:
        print_cmd(cmd)
        return
    run_checked(cmd)


def main() -> int:
    parser = argparse.ArgumentParser(description="Build and import NixOS LXC images into Incus")
    parser.add_argument("names", nargs="*", help="Container names to build")
    parser.add_argument("--list", action="store_true", help="List discovered container names and exit")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing them")
    parser.add_argument("--nightly", action="store_true", help="Build only images used by running Incus instances")
    parser.add_argument(
        "--instance-map",
        default=str(DEFAULT_MAP),
        help="JSON file mapping instance name -> image alias (default: containers/instance_map.json)",
    )
    args = parser.parse_args()

    try:
        available = discover_containers()
        if args.list:
            for name in available:
                print(name)
            return 0

        instance_map = load_instance_map(Path(args.instance_map))
        targets = resolve_targets(
            requested=args.names,
            nightly=args.nightly,
            dry_run=args.dry_run,
            available=available,
            instance_map=instance_map,
        )
        if not targets:
            print("No matching containers to build.")
            return 0
        for name in targets:
            metadata_path, rootfs_path = build_one(name, dry_run=args.dry_run)
            import_one(name, metadata_path, rootfs_path, dry_run=args.dry_run)
        return 0
    except (ValueError, RuntimeError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
