#!/usr/bin/env python3
import json
import subprocess
import sys


manifest_path, herdr = sys.argv[1:3]


def plugin_specs(entries):
    specs = []
    for entry in entries:
        if isinstance(entry, str):
            specs.append({"source": entry, "ref": None})
            continue
        source = entry.get("source")
        if not source:
            continue
        specs.append({"source": source, "ref": entry.get("ref") or None})
    return specs


def github_identity(source):
    owner, repo, *rest = source.split("/")
    subdir = "/".join(rest) or None
    return owner, repo, subdir


def load_installed():
    listed = subprocess.run(
        [herdr, "plugin", "list", "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    if listed.returncode != 0:
        return []
    try:
        payload = json.loads(listed.stdout)
    except json.JSONDecodeError:
        return []
    return payload.get("result", {}).get("plugins", [])


def matches_source(plugin, owner, repo, subdir):
    source = plugin.get("source") or {}
    return (
        source.get("kind") == "github"
        and source.get("owner") == owner
        and source.get("repo") == repo
        and (source.get("subdir") or None) == subdir
    )


def already_installed(plugin, ref):
    if not ref:
        return True
    source = plugin.get("source") or {}
    resolved = source.get("resolved_commit") or ""
    return plugin.get("plugin_id") == "linuxing3.herdr-hx" or resolved.startswith(ref)


with open(manifest_path, encoding="utf-8") as handle:
    manifest = json.load(handle)

installed = load_installed()
failed = []

for spec in plugin_specs(manifest.get("github", [])):
    source = spec["source"]
    ref = spec["ref"]
    owner, repo, subdir = github_identity(source)
    matching = [plugin for plugin in installed if matches_source(plugin, owner, repo, subdir)]
    if matching and all(already_installed(plugin, ref) for plugin in matching):
        continue
    for plugin in matching:
        subprocess.run(
            [herdr, "plugin", "uninstall", plugin["plugin_id"]],
            check=False,
        )
    command = [herdr, "plugin", "install", source, "--yes"]
    if ref:
        command.extend(["--ref", ref])
    result = subprocess.run(command, check=False)
    if result.returncode != 0:
        failed.append(source if not ref else f"{source}@{ref}")
        continue
    installed = load_installed()

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
