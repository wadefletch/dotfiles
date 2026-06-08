#!/usr/bin/env bash

# Open the Tailscale menu bar status menu (its dropdown lives in menu bar 2).
# Requires sketchybar to have Accessibility + Automation permission.
osascript <<'EOF'
tell application "System Events"
  tell process "Tailscale"
    click menu bar item 1 of menu bar 2
  end tell
end tell
EOF
