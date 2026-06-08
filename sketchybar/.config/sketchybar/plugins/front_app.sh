#!/usr/bin/env bash

# Shows the focused application's name. On a front_app_switched event the name
# arrives in $INFO; on first paint we fall back to querying yabai.
if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
else
  APP=$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty')
  [ -n "$APP" ] && sketchybar --set "$NAME" label="$APP"
fi
