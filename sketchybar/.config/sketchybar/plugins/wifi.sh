#!/usr/bin/env bash

# Current Wi-Fi SSID, or "off" when disconnected.
#
# macOS treats the SSID as location data: since 14.4 every stock CLI
# (networksetup, ipconfig, wdutil, and as of 15.x system_profiler too)
# returns the literal "<redacted>" unless the caller holds a Location
# Services grant. The durable source is helpers/wifi-ssid — a CoreWLAN
# helper app with its own grant, built by bootstrap.sh into ~/.local/libexec.
# Until it's built and authorized on a machine, fall back to the SSID still
# readable in configd's cached scan record, then to a generic "connected".
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

HELPER="$HOME/.local/libexec/wifi-ssid.app/Contents/MacOS/wifi-ssid"

if [ -x "$HELPER" ] && SSID=$("$HELPER" 2>/dev/null); then
  : # authorized answer is definitive: the SSID, or empty when disconnected
else
  DEV=$(networksetup -listallhardwareports | awk '/^Hardware Port: Wi-Fi/{getline; print $2; exit}')
  SSID=$(ipconfig getsummary "${DEV:-en0}" 2>/dev/null |
    awk -F ' SSID : ' '/ SSID : /{print $2; exit}')
  if [ "$SSID" = "<redacted>" ]; then
    SSID=$(scutil <<<"show State:/Network/Interface/${DEV:-en0}/AirPort" 2>/dev/null |
      "$CONFIG_DIR/helpers/scan-record-ssid.py" 2>/dev/null)
    SSID=${SSID:-connected}
  fi
fi

if [ -n "$SSID" ]; then
  sketchybar --set "$NAME" icon="$ICON_WIFI" label="$SSID" icon.color="$CYAN"
else
  sketchybar --set "$NAME" icon="$ICON_WIFI" label="off" icon.color="$GREY"
fi
