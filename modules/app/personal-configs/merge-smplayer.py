#!/usr/bin/env python3
import configparser
import os
import stat
import sys
import tempfile


path = sys.argv[1]
settings = {
    "%General": {
        "disable_screensaver": "true",
        "remember_media_settings": "true",
        "remember_stream_settings": "false",
        "remember_time_pos": "true",
        "screenshot_format": "jpg",
        "use_hwac3": "false",
    },
    "advanced": {
        "prefer_ipv4": "true",
        "use_mpris2": "true",
        "use_native_open_dialog": "true",
    },
    "gui": {
        "iconset": "H2O",
    },
    "subtitles": {
        "enca_lang": "zh",
        "use_ass_subtitles": "true",
    },
}

parser = configparser.RawConfigParser(strict=False)
parser.optionxform = str
parser.read(path, encoding="utf-8")
for section, values in settings.items():
    if not parser.has_section(section):
        parser.add_section(section)
    for key, value in values.items():
        parser.set(section, key, value)

mode = stat.S_IMODE(os.stat(path).st_mode)
directory = os.path.dirname(path)
fd, temporary = tempfile.mkstemp(prefix=".smplayer.ini.", dir=directory, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        parser.write(handle, space_around_delimiters=False)
    os.chmod(temporary, mode)
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
