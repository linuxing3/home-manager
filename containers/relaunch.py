#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_MAP = SCRIPT_DIR / "instance_map.json"
DEFAULT_INCUS_RUNTIME = os.environ.get("INCUS_RUNTIME", "docker")
DEFAULT_INCUS_DOCKER_IMAGE = os.environ.get("INCUS_DOCKER_IMAGE", "ghcr.io/cmspam/incus-docker")


def print_cmd(cmd: list[str]) -> None:
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
        "--cgroupns",
        "host",
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


def run_checked(cmd: list[str], capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        text=True,
        capture_output=capture,
        check=True,
    )


def run_optional(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        text=True,
        capture_output=True,
        check=False,
    )


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
    cmd = incus_cmd("list", "type=container", "status=running", "-c", "n", "--format", "csv")
    if dry_run:
        print_cmd(cmd)
        return []
    proc = run_checked(cmd, capture=True)
    return [line.strip() for line in proc.stdout.splitlines() if line.strip()]


def get_instance_base_image(instance: str, dry_run: bool) -> str | None:
    cmd = incus_cmd("config", "get", instance, "volatile.base_image")
    if dry_run:
        print_cmd(cmd)
        return None
    proc = run_checked(cmd, capture=True)
    value = proc.stdout.strip()
    return value or None


def get_image_fingerprint(alias: str, dry_run: bool) -> str | None:
    cmd = incus_cmd("image", "info", alias)
    if dry_run:
        print_cmd(cmd)
        return None
    proc = run_optional(cmd)
    if proc.returncode != 0:
        return None
    for line in proc.stdout.splitlines():
        if line.startswith("Fingerprint:"):
            return line.split(":", 1)[1].strip() or None
    return None


def profile_exists(profile: str, dry_run: bool) -> bool:
    cmd = incus_cmd("profile", "show", profile)
    if dry_run:
        print_cmd(cmd)
        return True
    return run_optional(cmd).returncode == 0


def stop_delete_launch(instance: str, image_alias: str, dry_run: bool) -> None:
    stop_cmd = incus_cmd("stop", instance, "--timeout", "30")
    force_stop_cmd = incus_cmd("stop", instance, "--force")
    delete_cmd = incus_cmd("delete", instance)
    launch_cmd = incus_cmd("launch", image_alias, instance, "--profile", instance)
    if dry_run:
        print_cmd(stop_cmd)
        print_cmd(force_stop_cmd)
        print_cmd(delete_cmd)
        print_cmd(launch_cmd)
        return

    stopped = run_optional(stop_cmd).returncode == 0
    if not stopped:
        run_checked(force_stop_cmd)
    run_checked(delete_cmd)
    run_checked(launch_cmd)


def main() -> int:
    parser = argparse.ArgumentParser(description="Relaunch stale running Incus instances from updated image aliases")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing them")
    parser.add_argument(
        "--instance-map",
        default=str(DEFAULT_MAP),
        help="JSON file mapping instance name -> image alias (default: containers/instance_map.json)",
    )
    args = parser.parse_args()

    try:
        instance_map = load_instance_map(Path(args.instance_map))
        running = get_running_instances(dry_run=args.dry_run)
        if not running:
            print("No running instances.")
            return 0

        for instance in running:
            alias = instance_map.get(instance, instance)
            if not profile_exists(instance, dry_run=args.dry_run):
                print(f"Skipping {instance}: missing profile '{instance}'.")
                continue
            current = get_image_fingerprint(alias, dry_run=args.dry_run)
            if current is None and not args.dry_run:
                print(f"Skipping {instance}: image alias '{alias}' not found.")
                continue
            base = get_instance_base_image(instance, dry_run=args.dry_run)
            if not args.dry_run and base == current:
                print(f"{instance}: up-to-date.")
                continue
            print(f"{instance}: relaunching from '{alias}'.")
            stop_delete_launch(instance, alias, dry_run=args.dry_run)
        return 0
    except (ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
