#!/usr/bin/env bash

# Volume level with a speaker icon. On a volume_change event the level is in
# $INFO; otherwise query the current output volume.
source "$CONFIG_DIR/icons.sh"

VOLUME="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"

case "$VOLUME" in
  [6-9][0-9] | 100) ICON="$ICON_VOL_HIGH" ;;
  [3-5][0-9]) ICON="$ICON_VOL_MID" ;;
  [1-9] | [1-2][0-9]) ICON="$ICON_VOL_LOW" ;;
  *) ICON="$ICON_VOL_LOW" ;;
esac

sketchybar --set "$NAME" icon="$ICON" label="${VOLUME}%"
