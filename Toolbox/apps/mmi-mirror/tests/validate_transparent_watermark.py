#!/usr/bin/env python3
"""Validate V2.4.1 transparent runtime watermark asset, preserving original ELF."""
import base64
import hashlib
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[3]
FILE = "Toolbox/apps/mmi-mirror/mmi-mirror-display"
data = (ROOT / FILE).read_bytes()
original = subprocess.check_output(["git", "show", "bf0b99f1d26f3f69b0ba490ca0e9793be9b64bb1:" + FILE], cwd=ROOT)
expected = "27dc33941146e2b3775569b8aefc7b344dd1815c390b43eb24d0349d6ddf7135"
assert len(data) == len(original) == 105187
assert hashlib.sha256(data).hexdigest() == expected
assert data[:4] == b"\x7fELF"
# All bytes beyond the encoded runtime-watermark C string must remain byte-for-byte unchanged.
start, end = 93348, 93348 + 1960
assert data[:start] == original[:start]
assert data[end:] == original[end:]
assert data[start:end] != original[start:end]
# QNX startup logo stored as a distinct C string remains unchanged.
assert data[76232:76232 + 17112] == original[76232:76232 + 17112]
encoded = data[start:end]
decoded = base64.b64decode(encoded, validate=True)
assert len(decoded) == 1468
decoded = bytes(x ^ ((i * 73 + 0x5B) & 0xFF) for i, x in enumerate(decoded))
unpacked = bytearray()
i = 0
while i < len(decoded):
    ctrl = decoded[i]; i += 1
    count = (ctrl & 127) + 1
    if ctrl & 128:
        assert i < len(decoded)
        unpacked.extend([decoded[i]] * count)
        i += 1
    else:
        unpacked.extend(decoded[i:i + count])
        i += count
assert i == len(decoded)
assert len(unpacked) == 3136
assert all(x == 0 for x in unpacked)
print("PASS: only transparent runtime-watermark data changed; startup/logo/code preserved.")
