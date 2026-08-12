#!/usr/bin/env python3
import subprocess
import sys


claude = sys.argv[1]
source = "anthropics/claude-plugins-official"
result = subprocess.run(
    [claude, "plugin", "marketplace", "list"],
    check=True,
    capture_output=True,
    text=True,
)
if source not in result.stdout and "claude-plugins-official" not in result.stdout:
    subprocess.run(
        [claude, "plugin", "marketplace", "add", "--scope", "user", source],
        check=True,
    )
