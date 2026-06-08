#!/usr/bin/env bash

# Open a Control Center popover by clicking the menu bar item whose description
# starts with $1 (e.g. "Wi" for Wi‑Fi, "Battery", or "Control" for the full
# Control Center). macOS renders "Wi‑Fi" with a non-breaking hyphen, so match
# on a prefix. The prefix is passed to AppleScript as an argument to avoid any
# quoting/interpolation issues.
#
# Requires sketchybar to have Accessibility + Automation (System Events)
# permission, since this drives the menu bar via Apple Events.
osascript - "$1" <<'EOF'
on run argv
  set prefix to item 1 of argv
  tell application "System Events"
    tell process "ControlCenter"
      click (first menu bar item of menu bar 1 whose description starts with prefix)
    end tell
  end tell
end run
EOF
