#!/usr/bin/env python3
"""Repoint DT_VERDEF after patchelf grows .dynamic on bun --compile ELFs.

patchelf rewrites DT_SYMTAB/STRTAB/VERSYM/VERNEED but leaves DT_VERDEF stale;
glibc then SIGSEGVs in _dl_check_map_versions (oh-my-pi #9881). ELF64 LE only.
"""

from __future__ import annotations

import struct
import sys

SHT_DYNAMIC = 6
SHT_GNU_VERDEF = 0x6FFFFFFD
DT_NULL = 0
DT_VERDEF = 0x6FFFFFFC


def repair(path: str) -> None:
    with open(path, "r+b") as fh:
        data = bytearray(fh.read())

    if data[:4] != b"\x7fELF":
        raise SystemExit(f"{path}: not ELF")
    if data[4] != 2 or data[5] != 1:
        raise SystemExit(f"{path}: only ELF64 little-endian supported")

    e_shoff = struct.unpack_from("<Q", data, 40)[0]
    e_shentsize = struct.unpack_from("<H", data, 58)[0]
    e_shnum = struct.unpack_from("<H", data, 60)[0]

    dyn_off = dyn_size = None
    verdef_addr = None
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type = struct.unpack_from("<I", data, off + 4)[0]
        sh_addr = struct.unpack_from("<Q", data, off + 16)[0]
        sh_offset = struct.unpack_from("<Q", data, off + 24)[0]
        sh_size = struct.unpack_from("<Q", data, off + 32)[0]
        if sh_type == SHT_DYNAMIC:
            dyn_off, dyn_size = sh_offset, sh_size
        elif sh_type == SHT_GNU_VERDEF:
            verdef_addr = sh_addr

    if verdef_addr is None:
        print(f"{path}: no .gnu.version_d; skip", file=sys.stderr)
        return
    if dyn_off is None:
        raise SystemExit(f"{path}: missing SHT_DYNAMIC")

    pos = dyn_off
    end = dyn_off + dyn_size
    found = False
    while pos + 16 <= end:
        tag, val = struct.unpack_from("<QQ", data, pos)
        if tag == DT_NULL:
            break
        if tag == DT_VERDEF:
            print(f"{path}: DT_VERDEF {val:#x} -> {verdef_addr:#x}", file=sys.stderr)
            struct.pack_into("<Q", data, pos + 8, verdef_addr)
            found = True
            break
        pos += 16

    if not found:
        raise SystemExit(f"{path}: .gnu.version_d present but DT_VERDEF missing")

    with open(path, "wb") as fh:
        fh.write(data)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(f"usage: {sys.argv[0]} <elf>...")
    for target in sys.argv[1:]:
        repair(target)
