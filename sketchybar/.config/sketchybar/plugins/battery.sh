#!/usr/bin/env bash

# Battery percentage with a charge-level icon; bolt while on AC power.
# Icon is tinted green/yellow/red by charge (Xcode Dark HC palette).
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

PERCENT=$(pmset -g batt | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
# Desktops report no battery percentage. Hide the item entirely so it doesn't
# render as an empty rounded box between volume and the clock.
if [ -z "$PERCENT" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if pmset -g batt | grep -q 'AC Power'; then
  ICON="$ICON_BATT_CHARGING"
else
  case "$PERCENT" in
    100 | 9[0-9]) ICON="$ICON_BATT_FULL" ;;
    [6-8][0-9]) ICON="$ICON_BATT_75" ;;
    [3-5][0-9]) ICON="$ICON_BATT_50" ;;
    [1-2][0-9]) ICON="$ICON_BATT_25" ;;
    *) ICON="$ICON_BATT_EMPTY" ;;
  esac
fi

if [ "$PERCENT" -le 20 ]; then
  COLOR="$RED"
elif [ "$PERCENT" -le 40 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color="$COLOR" label="${PERCENT}%"
