#!/usr/bin/env bash

# Paints the app icons of each space's windows into that space's label, using
# the sketchybar-app-font ligatures (":ghostty:" etc.). Spaces with no windows
# hide their label so they stay a clean, centered number.
source "$CONFIG_DIR/icon_map.sh"

args=()
for sid in $(yabai -m query --spaces | jq -r '.[].index'); do
  # Only real, standard app windows — excludes background/menu-bar apps
  # (Granola, Tailscale, etc.) whose helper windows have a non-standard subrole.
  apps=$(yabai -m query --windows --space "$sid" \
    | jq -r '.[]
        | select(.["is-minimized"]==false)
        | select(.subrole=="AXStandardWindow")
        | .app')

  if [ -n "$apps" ]; then
    strip=""
    while IFS= read -r app; do
      __icon_map "$app"
      # Local overrides for apps whose default glyph we don't want.
      case "$app" in
        "Ghostty") icon_result=":terminal:" ;;
      esac
      strip+=" ${icon_result}"
    done <<<"$apps"
    strip="${strip# }" # drop the leading space so the gap to the number is even
    args+=(--set space."$sid" label="$strip" label.drawing=on)
  else
    args+=(--set space."$sid" label.drawing=off)
  fi
done

sketchybar -m "${args[@]}" >/dev/null 2>&1
