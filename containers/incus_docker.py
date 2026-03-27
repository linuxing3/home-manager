from __future__ import annotations

import os
import shutil
import subprocess
import time
from pathlib import Path


DOCKER_BIN = os.environ.get("DOCKER_BIN", "docker")
INCUS_CONTAINER_NAME = os.environ.get("INCUS_DOCKER_CONTAINER", "incus-docker")
INCUS_DOCKER_IMAGE = os.environ.get("INCUS_DOCKER_IMAGE", "ghcr.io/cmspam/incus-docker")
NIX_BIN = os.environ.get("NIX_BIN") or shutil.which("nix") or "/nix/var/nix/profiles/default/bin/nix"


def docker_base_cmd() -> list[str]:
    return [DOCKER_BIN]


def incus_docker_run_cmd(*args: str) -> list[str]:
    return [
        DOCKER_BIN,
        "run",
        "-d",
        "--name",
        INCUS_CONTAINER_NAME,
        "--privileged",
        "--network",
        "host",
        "-v",
        f"{INCUS_CONTAINER_NAME}-lib:/var/lib/incus",
        "-v",
        f"{INCUS_CONTAINER_NAME}-log:/var/log/incus",
        "-v",
        f"{INCUS_CONTAINER_NAME}-cache:/var/cache/incus",
        "-v",
        "/sys/fs/cgroup:/sys/fs/cgroup:rw",
        "-v",
        "/nix/store:/nix/store:ro",
        INCUS_DOCKER_IMAGE,
        *args,
    ]


def incus_exec_cmd(*args: str) -> list[str]:
    return [DOCKER_BIN, "exec", INCUS_CONTAINER_NAME, "incus", *args]


def nix_cmd(*args: str) -> list[str]:
    return [NIX_BIN, *args]


def run(cmd: list[str], *, capture: bool = False, check: bool = True, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=capture, check=check, cwd=cwd)


def _container_exists() -> bool:
    proc = subprocess.run(
        [DOCKER_BIN, "inspect", INCUS_CONTAINER_NAME],
        text=True,
        capture_output=True,
        check=False,
    )
    return proc.returncode == 0


def _container_running() -> bool:
    proc = subprocess.run(
        [DOCKER_BIN, "inspect", "-f", "{{.State.Running}}", INCUS_CONTAINER_NAME],
        text=True,
        capture_output=True,
        check=False,
    )
    return proc.returncode == 0 and proc.stdout.strip() == "true"


def ensure_incus_container_ready() -> None:
    if not _container_exists():
        run(incus_docker_run_cmd(), capture=False, check=True)
    elif not _container_running():
        run([DOCKER_BIN, "start", INCUS_CONTAINER_NAME], capture=False, check=True)

    for _ in range(30):
        probe = subprocess.run(
            incus_exec_cmd("info"),
            text=True,
            capture_output=True,
            check=False,
        )
        if probe.returncode == 0:
            break
        time.sleep(1)

    bootstrap = subprocess.run(
        incus_exec_cmd("admin", "init", "--auto"),
        text=True,
        capture_output=True,
        check=False,
    )
    if bootstrap.returncode not in (0, 1):
        raise RuntimeError(bootstrap.stderr.strip() or bootstrap.stdout.strip() or "failed to bootstrap incus")

    for _ in range(30):
        profile = subprocess.run(
            incus_exec_cmd("profile", "show", "default"),
            text=True,
            capture_output=True,
            check=False,
        )
        storage = subprocess.run(
            incus_exec_cmd("storage", "list"),
            text=True,
            capture_output=True,
            check=False,
        )
        if profile.returncode == 0 and "type: disk" in profile.stdout and "path: /" in profile.stdout and storage.returncode == 0 and "default" in storage.stdout:
            return
        time.sleep(1)

    subprocess.run(incus_exec_cmd("storage", "create", "default", "dir"), text=True, capture_output=True, check=False)
    subprocess.run(
        incus_exec_cmd("profile", "device", "add", "default", "root", "disk", "path=/", "pool=default"),
        text=True,
        capture_output=True,
        check=False,
    )

    for _ in range(15):
        profile = subprocess.run(
            incus_exec_cmd("profile", "show", "default"),
            text=True,
            capture_output=True,
            check=False,
        )
        if profile.returncode == 0 and "type: disk" in profile.stdout and "path: /" in profile.stdout:
            return
        time.sleep(1)

    raise RuntimeError(f"incus daemon in docker container '{INCUS_CONTAINER_NAME}' did not become ready")
