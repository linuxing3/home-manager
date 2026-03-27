#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from typing import Iterable

from build import build_one, discover_containers as discover_build_containers, import_one
from incus_docker import ensure_incus_container_ready, incus_exec_cmd


def print_cmd(cmd: Iterable[str]) -> None:
    print(" ".join(shlex.quote(part) for part in cmd))


def discover_containers() -> list[str]:
    return discover_build_containers()


def run_checked(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=True)


def image_exists(image: str) -> bool:
    proc = subprocess.run(incus_exec_cmd("image", "info", image), text=True, capture_output=True, check=False)
    return proc.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Launch a built Incus image through the Docker-backed Incus wrapper")
    parser.add_argument("image", nargs="?", help="Image alias to launch")
    parser.add_argument("instance", nargs="?", help="Instance name to create (defaults to the image alias)")
    parser.add_argument("--profile", help="Incus profile to attach (defaults to the instance name)")
    parser.add_argument("--dry-run", action="store_true", help="Print the docker/incus command without executing it")
    parser.add_argument("--list", action="store_true", help="List discoverable container aliases and exit")
    args = parser.parse_args()

    try:
        if args.list:
            for name in discover_containers():
                print(name)
            return 0

        if not args.image:
            parser.error("the following arguments are required: image")

        instance = args.instance or args.image
        profile = args.profile or "default"

        if args.dry_run:
            metadata_path, rootfs_path = build_one(args.image, dry_run=args.dry_run)
            import_one(args.image, metadata_path, rootfs_path, dry_run=args.dry_run)
        else:
            ensure_incus_container_ready()
            if not image_exists(args.image):
                metadata_path, rootfs_path = build_one(args.image, dry_run=args.dry_run)
                import_one(args.image, metadata_path, rootfs_path, dry_run=args.dry_run)

        cmd = incus_exec_cmd("launch", args.image, instance, "--profile", profile)
        if args.dry_run:
            print_cmd(cmd)
            return 0
        run_checked(cmd)
        return 0
    except (subprocess.CalledProcessError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
