#!/usr/bin/env python3
import json
import os
import subprocess
import sys


manifest_path, herdr = sys.argv[1:3]
if os.environ.get("HERDR_ENV") != "1":
    raise SystemExit("herdr-plugin-sync must run inside a Herdr-managed pane")

with open(manifest_path, encoding="utf-8") as handle:
    manifest = json.load(handle)

result = subprocess.run(
    [herdr, "plugin", "list"],
    check=True,
    capture_output=True,
    text=True,
)
for source in manifest["github"]:
    owner, repo, *_ = source.split("/")
    if f"{owner}/{repo}" in result.stdout or source in result.stdout:
        continue
    subprocess.run([herdr, "plugin", "install", source, "--yes"], check=True)

if manifest.get("local"):
    print(
        "Local plugins are inventory-only and must be restored from their owning source: "
        + ", ".join(manifest["local"]),
        file=sys.stderr,
    )
