#!/usr/bin/env python3
"""Recover the current SSID from configd's cached scan record.

Reads `scutil` output for State:/Network/Interface/<dev>/AirPort on stdin.
That dictionary's SSID_STR field is blanked by the same Location Services
redaction that hits every stock CLI, but (as of macOS 15.7) the raw
CachedScanRecord blob — an NSKeyedArchiver plist of the network the machine
is currently associated to — still carries the name in the clear.

Prints the SSID, or nothing (exit 1) if it can't be recovered.
"""

import plistlib
import re
import sys

match = re.search(r"CachedScanRecord : <data> 0x([0-9a-f]+)", sys.stdin.read())
if not match:
    sys.exit(1)

archive = plistlib.loads(bytes.fromhex(match.group(1)))
objects = archive["$objects"]


def deref(ref):
    return objects[ref.data] if isinstance(ref, plistlib.UID) else ref


try:
    record = deref(archive["$top"]["root"])
    keys = [deref(k) for k in record["NS.keys"]]
    ssid = deref(dict(zip(keys, record["NS.objects"]))["SSID_STR"])
except (KeyError, IndexError, TypeError):
    sys.exit(1)

if not isinstance(ssid, str) or not ssid:
    sys.exit(1)
print(ssid)
