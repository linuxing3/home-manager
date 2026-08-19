#!/usr/bin/env python3
import json
import subprocess
import sys


manifest_path, herdr = sys.argv[1:3]

with open(manifest_path, encoding="utf-8") as handle:
    manifest = json.load(handle)

listed = subprocess.run(
    [herdr, "plugin", "list"],
    check=False,
    capture_output=True,
    text=True,
)
installed = listed.stdout if listed.returncode == 0 else ""
failed = []

for source in manifest.get("github", []):
    owner, repo, *_ = source.split("/")
    if f"{owner}/{repo}" in installed or source in installed:
        continue
    result = subprocess.run(
        [herdr, "plugin", "install", source, "--yes"],
        check=False,
    )
    if result.returncode != 0:
        failed.append(source)

if manifest.get("local"):
    print(
        "Local plugins are inventory-only and must be restored from their owning source: "
        + ", ".join(manifest["local"]),
        file=sys.stderr,
    )

if failed:
    print(
        "herdr-plugin-sync: skipped failed installs: " + ", ".join(failed),
        file=sys.stderr,
    )

sys.exit(0)
