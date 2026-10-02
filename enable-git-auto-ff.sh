#!/usr/bin/env bash
# Turn on git-auto-ff's daily run on this host. bootstrap.sh stows the systemd
# units and LaunchAgent everywhere but never enables them; running this is the
# opt-in.
set -euo pipefail

if [[ "$(uname -s)" == "Darwin" ]]; then
  label=com.wadefletcher.git-auto-ff
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$label.plist"
  echo "loaded $label (daily 05:00 local; log: /tmp/git-auto-ff.log)"
else
  # Linger lets the per-user timer fire without an active login session.
  loginctl enable-linger "$USER" 2>/dev/null || sudo loginctl enable-linger "$USER"
  systemctl --user daemon-reload
  systemctl --user enable --now git-auto-ff.timer
  systemctl --user list-timers git-auto-ff.timer
fi
