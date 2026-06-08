#!/usr/bin/env bash

# Tailscale status. When the backend is running: green logo + the tailnet name
# (the network, not this machine), with a leading ↗ when an exit node is active
# (mirrors Tailscale's own menu bar). Grey "off" when not running.
source "$CONFIG_DIR/colors.sh"

TS="/usr/local/bin/tailscale"
[ -x "$TS" ] || TS="$(command -v tailscale 2>/dev/null)"
[ -x "$TS" ] || {
  sketchybar --set "$NAME" icon=":tailscale:" label="n/a" icon.color="$GREY"
  exit 0
}

json=$("$TS" status --json 2>/dev/null)
state=$(printf '%s' "$json" | jq -r '.BackendState // "Stopped"')
tailnet=$(printf '%s' "$json" | jq -r '.CurrentTailnet.Name // empty')
exit_active=$(printf '%s' "$json" |
  jq -r 'if (.ExitNodeStatus != null) or (any(.Peer[]?; .ExitNode == true)) then "1" else "" end')

if [ "$state" = "Running" ]; then
  label="${tailnet:-on}"
  [ -n "$exit_active" ] && label="↗ $label"
  color="$GREEN"
else
  label="off"
  color="$GREY"
fi

sketchybar --set "$NAME" icon=":tailscale:" label="$label" icon.color="$color"
