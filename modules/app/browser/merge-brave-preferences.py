#!/usr/bin/env python3
import json
import os
import stat
import sys
import tempfile

if len(sys.argv) < 3:
    print(f"Usage: {sys.argv[0]} <preferences_path> <keybindings_json_path>", file=sys.stderr)
    sys.exit(1)

prefs_path = sys.argv[1]
keybindings_path = sys.argv[2]

if not os.path.isfile(prefs_path) or not os.path.isfile(keybindings_path):
    sys.exit(0)

try:
    with open(keybindings_path, "r", encoding="utf-8") as f:
        kb_data = json.load(f)
except Exception as e:
    print(f"Error loading keybindings JSON: {e}", file=sys.stderr)
    sys.exit(1)

try:
    with open(prefs_path, "r", encoding="utf-8") as f:
        prefs = json.load(f)
except Exception as e:
    print(f"Error loading Brave Preferences: {e}", file=sys.stderr)
    sys.exit(1)

# Ensure sections exist
if "brave" not in prefs or not isinstance(prefs["brave"], dict):
    prefs["brave"] = {}
if "extensions" not in prefs or not isinstance(prefs["extensions"], dict):
    prefs["extensions"] = {}

# Merge accelerators
managed_accelerators = kb_data.get("accelerators", {})
if managed_accelerators:
    if "accelerators" not in prefs["brave"] or not isinstance(prefs["brave"]["accelerators"], dict):
        prefs["brave"]["accelerators"] = {}
    prefs["brave"]["accelerators"].update(managed_accelerators)

# Merge extension commands
managed_commands = kb_data.get("extension_commands", {})
if managed_commands:
    if "commands" not in prefs["extensions"] or not isinstance(prefs["extensions"]["commands"], dict):
        prefs["extensions"]["commands"] = {}
    prefs["extensions"]["commands"].update(managed_commands)

# Atomically replace preferences file preserving permissions
mode = stat.S_IMODE(os.stat(prefs_path).st_mode)
directory = os.path.dirname(prefs_path)
fd, temporary = tempfile.mkstemp(prefix=".Preferences.", dir=directory, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(prefs, handle, ensure_ascii=False, separators=(",", ":"))
    os.chmod(temporary, mode)
    os.replace(temporary, prefs_path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
