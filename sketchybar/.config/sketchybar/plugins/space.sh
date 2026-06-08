#!/usr/bin/env bash

# Highlights the active space. $SELECTED is set by the space_change event.
source "$CONFIG_DIR/colors.sh"

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.color="$ACTIVE" icon.color="$BLACK"
else
  sketchybar --set "$NAME" background.color="$ITEM_BG" icon.color="$GREY"
fi
