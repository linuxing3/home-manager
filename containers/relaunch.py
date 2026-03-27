#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
from pathlib import Path

from incus_docker import ensure_incus_container_ready, incus_exec_cmd, run


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_MAP = SCRIPT_DIR / "instance_map.json"

def print_cmd(cmd: list[str]) -> None:
    print(" ".join(shlex.quote(part) for part in cmd))


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
    cmd = incus_exec_cmd("list", "type=container", "status=running", "-c", "n", "--format", "csv")
    if dry_run:
        print_cmd(cmd)
        return []
    ensure_incus_container_ready()
    proc = run(cmd, capture=True)
    return [line.strip() for line in proc.stdout.splitlines() if line.strip()]


def get_instance_base_image(instance: str, dry_run: bool) -> str | None:
    cmd = incus_exec_cmd("config", "get", instance, "volatile.base_image")
    if dry_run:
        print_cmd(cmd)
        return None
    proc = run(cmd, capture=True)
    value = proc.stdout.strip()
    return value or None


def get_image_fingerprint(alias: str, dry_run: bool) -> str | None:
    cmd = incus_exec_cmd("image", "info", alias)
    if dry_run:
        print_cmd(cmd)
        return None
    proc = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if proc.returncode != 0:
        return None
    for line in proc.stdout.splitlines():
        if line.startswith("Fingerprint:"):
            return line.split(":", 1)[1].strip() or None
    return None


def profile_exists(profile: str, dry_run: bool) -> bool:
    cmd = incus_exec_cmd("profile", "show", profile)
    if dry_run:
        print_cmd(cmd)
        return True
    return subprocess.run(cmd, text=True, capture_output=True, check=False).returncode == 0


def stop_delete_launch(instance: str, image_alias: str, dry_run: bool) -> None:
    stop_cmd = incus_exec_cmd("stop", instance, "--timeout", "30")
    force_stop_cmd = incus_exec_cmd("stop", instance, "--force")
    delete_cmd = incus_exec_cmd("delete", instance)
    launch_cmd = incus_exec_cmd("launch", image_alias, instance, "--profile", instance)
    if dry_run:
        print_cmd(stop_cmd)
        print_cmd(force_stop_cmd)
        print_cmd(delete_cmd)
        print_cmd(launch_cmd)
        return

    ensure_incus_container_ready()
    stopped = subprocess.run(stop_cmd, text=True, capture_output=True, check=False).returncode == 0
    if not stopped:
        run(force_stop_cmd)
    run(delete_cmd)
    run(launch_cmd)


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
