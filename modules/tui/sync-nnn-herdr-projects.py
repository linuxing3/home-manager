#!/usr/bin/env python3
"""Synchronize nnn bookmark symlinks into Herdr Plus project templates."""

import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
import time
import unicodedata
from pathlib import Path


MANIFEST_NAME = ".nnn-herdr-sync-manifest.json"
MANAGED_GROUP = "nnn bookmarks"


def toml_string(value):
    """JSON strings are valid TOML basic strings for the values used here."""
    return json.dumps(value, ensure_ascii=False)


def slugify(name):
    ascii_name = (
        unicodedata.normalize("NFKD", name)
        .encode("ascii", "ignore")
        .decode("ascii")
        .lower()
    )
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_name).strip("-")
    digest = hashlib.sha256(name.encode("utf-8")).hexdigest()[:8]
    if not slug:
        return "bookmark-{}".format(digest)
    if len(slug) > 120:
        return "{}-{}".format(slug[:111].rstrip("-"), digest)
    return slug


def project_filenames(names):
    candidates = {}
    for name in names:
        if name == "nnn":
            filename = "nnn.toml"
        else:
            filename = "nnn-{}.toml".format(slugify(name))
        candidates[name] = filename

    by_filename = {}
    for name, filename in candidates.items():
        by_filename.setdefault(filename.casefold(), []).append(name)

    for colliding_names in by_filename.values():
        if len(colliding_names) < 2:
            continue
        for name in colliding_names:
            filename = candidates[name]
            digest = hashlib.sha256(name.encode("utf-8")).hexdigest()[:8]
            candidates[name] = "{}-{}.toml".format(filename[:-5], digest)

    return candidates


def render_project(name, working_dir):
    return """# Managed by nnn-herdr-sync. Changes will be overwritten.
name = {name}
description = {description}
group = {group}
working_dir = {working_dir}

[[tabs]]
name = "codex"
command = "codex"

[[tabs]]
name = "helix"
command = "hx"

[[tabs]]
name = "nnn"
command = "nnn"

[[tabs]]
name = "terminal"
""".format(
        name=toml_string(name),
        description=toml_string("nnn bookmark: {}".format(name)),
        group=toml_string(MANAGED_GROUP),
        working_dir=toml_string(str(working_dir)),
    )


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(
        dir=str(path.parent), prefix=".{}-".format(path.name)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary_name, 0o644)
        os.replace(temporary_name, str(path))
    except BaseException:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def is_safe_project_filename(filename):
    return (
        Path(filename).name == filename
        and filename.endswith(".toml")
        and (filename == "nnn.toml" or filename.startswith("nnn-"))
    )


def legacy_owned_projects(projects_dir):
    owned = set()
    for path in projects_dir.glob("nnn*.toml"):
        if not is_safe_project_filename(path.name) or not path.is_file():
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except OSError:
            continue
        if re.search(
            r'^group\s*=\s*"{}"\s*$'.format(re.escape(MANAGED_GROUP)),
            content,
            re.MULTILINE,
        ):
            owned.add(path.name)
    return owned


def load_owned_projects(projects_dir):
    manifest_path = projects_dir / MANIFEST_NAME
    if not manifest_path.exists():
        return legacy_owned_projects(projects_dir)

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    if data.get("version") != 1 or not isinstance(data.get("files"), list):
        raise ValueError("unsupported manifest format: {}".format(manifest_path))

    filenames = set(data["files"])
    if not all(isinstance(name, str) and is_safe_project_filename(name) for name in filenames):
        raise ValueError("unsafe project filename in manifest: {}".format(manifest_path))
    return filenames


def load_bookmarks(bookmarks_dir):
    if not bookmarks_dir.is_dir():
        raise FileNotFoundError("bookmark directory does not exist: {}".format(bookmarks_dir))

    bookmarks = {}
    skipped = 0
    for entry in sorted(bookmarks_dir.iterdir(), key=lambda path: path.name.casefold()):
        if not entry.is_symlink():
            continue
        try:
            target = entry.resolve(strict=True)
        except (FileNotFoundError, RuntimeError) as error:
            print("warning: skipping {}: {}".format(entry, error), file=sys.stderr)
            skipped += 1
            continue
        if not target.is_dir():
            print("warning: skipping non-directory bookmark {} -> {}".format(entry, target), file=sys.stderr)
            skipped += 1
            continue
        folded_name = entry.name.casefold()
        if any(existing.casefold() == folded_name for existing in bookmarks):
            raise ValueError("bookmark names differ only by case: {}".format(entry.name))
        bookmarks[entry.name] = target
    return bookmarks, skipped


def synchronize_snapshot(bookmarks, projects_dir):
    previously_owned = load_owned_projects(projects_dir)
    filenames = project_filenames(bookmarks)

    expected_files = set()
    changed = 0
    for name, working_dir in bookmarks.items():
        filename = filenames[name]
        expected_files.add(filename)
        path = projects_dir / filename
        content = render_project(name, working_dir)
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            atomic_write(path, content)
            changed += 1

    removed = 0
    for filename in sorted(previously_owned - expected_files):
        path = projects_dir / filename
        if path.exists() or path.is_symlink():
            path.unlink()
            removed += 1

    manifest = json.dumps(
        {"version": 1, "files": sorted(expected_files)},
        ensure_ascii=False,
        indent=2,
    ) + "\n"
    atomic_write(projects_dir / MANIFEST_NAME, manifest)
    return len(expected_files), changed, removed


def synchronize(bookmarks_dir, projects_dir, settle_seconds):
    projects_dir.mkdir(parents=True, exist_ok=True)
    bookmarks, skipped = load_bookmarks(bookmarks_dir)
    total_changed = 0
    total_removed = 0
    rounds = 0

    while True:
        project_count, changed, removed = synchronize_snapshot(bookmarks, projects_dir)
        total_changed += changed
        total_removed += removed
        rounds += 1

        if settle_seconds <= 0:
            break
        time.sleep(settle_seconds)
        next_bookmarks, next_skipped = load_bookmarks(bookmarks_dir)
        skipped = max(skipped, next_skipped)
        if next_bookmarks == bookmarks:
            break
        bookmarks = next_bookmarks

    print(
        "nnn-herdr-sync: projects={} changed={} removed={} skipped={} rounds={}".format(
            project_count, total_changed, total_removed, skipped, rounds
        )
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--bookmarks-dir",
        type=Path,
        default=Path.home() / ".config" / "nnn" / "bookmarks",
    )
    parser.add_argument(
        "--projects-dir",
        type=Path,
        default=(
            Path.home()
            / ".config"
            / "herdr"
            / "plugins"
            / "config"
            / "cloudmanic.herdr-plus"
            / "projects"
        ),
    )
    parser.add_argument(
        "--settle-seconds",
        type=float,
        default=0.25,
        help="rescan after this quiet period so rapid changes converge",
    )
    args = parser.parse_args()
    if args.settle_seconds < 0:
        parser.error("--settle-seconds must be non-negative")
    synchronize(args.bookmarks_dir, args.projects_dir, args.settle_seconds)


if __name__ == "__main__":
    main()
