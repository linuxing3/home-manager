#!/usr/bin/env python3
import configparser
import os
import stat
import sys
import tempfile


path = sys.argv[1]
parser = configparser.RawConfigParser()
parser.read(path, encoding="utf-8")
if not parser.has_section("core"):
    parser.add_section("core")

# Account and project identifiers are deliberately preserved from the local
# writable profile. This module only establishes stable non-secret defaults.
parser.set("core", "disable_usage_reporting", "true")

mode = stat.S_IMODE(os.stat(path).st_mode)
directory = os.path.dirname(path)
fd, temporary = tempfile.mkstemp(prefix=".config_default.", dir=directory, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        parser.write(handle, space_around_delimiters=False)
    os.chmod(temporary, mode)
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
