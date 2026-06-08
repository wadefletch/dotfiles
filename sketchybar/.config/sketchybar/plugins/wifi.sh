#!/usr/bin/env bash

# Current Wi-Fi SSID, or "off" when not connected.
#
# Recent macOS redacts the SSID (returns the literal "<redacted>") from
# networksetup/ipconfig unless the caller holds Location Services access.
# system_profiler still reports it in the clear, so read it from there. It is
# slower, but this item only refreshes every 60s.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

SSID=$(system_profiler SPAirPortDataType 2>/dev/null |
  awk '/Current Network Information:/{getline; gsub(/^[[:space:]]+|:[[:space:]]*$/, ""); print; exit}')

if [ -n "$SSID" ]; then
  sketchybar --set "$NAME" icon="$ICON_WIFI" label="$SSID" icon.color="$CYAN"
else
  sketchybar --set "$NAME" icon="$ICON_WIFI" label="off" icon.color="$GREY"
fi
