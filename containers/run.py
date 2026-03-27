#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_INCUS_RUNTIME = os.environ.get("INCUS_RUNTIME", "docker")
DEFAULT_INCUS_DOCKER_IMAGE = os.environ.get("INCUS_DOCKER_IMAGE", "ghcr.io/cmspam/incus-docker")


def print_cmd(cmd: Iterable[str]) -> None:
    print(" ".join(shlex.quote(part) for part in cmd))


def incus_cmd(*args: str) -> list[str]:
    if DEFAULT_INCUS_RUNTIME == "host":
        return ["incus", *args]
    return [
        "docker",
        "run",
        "--rm",
        "--privileged",
        "--network",
        "host",
        # Keep compatibility with Docker 18.09 on this host; it rejects --cgroupns.
        "-v",
        "incus-docker-lib:/var/lib/incus",
        "-v",
        "incus-docker-log:/var/log/incus",
        "-v",
        "incus-docker-cache:/var/cache/incus",
        "-v",
        "/sys/fs/cgroup:/sys/fs/cgroup:rw",
        "-v",
        "/nix/store:/nix/store:ro",
        DEFAULT_INCUS_DOCKER_IMAGE,
        "incus",
        *args,
    ]


def discover_containers() -> list[str]:
    return sorted(path.stem for path in SCRIPT_DIR.glob("*.nix") if path.is_file())


def run_checked(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=True)


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
        profile = args.profile or instance
        cmd = incus_cmd("launch", args.image, instance, "--profile", profile)
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
