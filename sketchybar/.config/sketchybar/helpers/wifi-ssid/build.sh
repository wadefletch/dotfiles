#!/usr/bin/env bash
set -euo pipefail

# Build the wifi-ssid helper app into ~/.local/libexec (outside the stowed
# tree so build artifacts never dirty the repo).
#
# Skips when the built binary is newer than the sources: rebuilding re-signs
# the app ad hoc, which changes its code hash and would invalidate the
# Location Services grant — forcing the permission prompt again — on every
# bootstrap run.

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-$HOME/.local/libexec/wifi-ssid.app}"
BIN="$APP/Contents/MacOS/wifi-ssid"

if [[ -x "$BIN" && "$BIN" -nt "$SRC/wifi-ssid.swift" && "$BIN" -nt "$SRC/Info.plist" ]]; then
  exit 0
fi

if ! command -v swiftc &>/dev/null; then
  echo "wifi-ssid: swiftc not found — install the Xcode Command Line Tools" >&2
  exit 1
fi

mkdir -p "$APP/Contents/MacOS"
cp "$SRC/Info.plist" "$APP/Contents/Info.plist"
swiftc -O -o "$BIN" "$SRC/wifi-ssid.swift" -framework CoreWLAN -framework CoreLocation
codesign --force --sign - "$APP"
