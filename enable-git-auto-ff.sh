#!/usr/bin/env bash
# Turn on git-auto-ff's daily run on this host, for the given repos. bootstrap.sh
# stows the systemd units and LaunchAgent everywhere but never enables them;
# running this is the opt-in.
#
# Usage: ./enable-git-auto-ff.sh [REPO ...]
# Adds each REPO to ~/.config/git-auto-ff/repos (host-local, untracked).
set -euo pipefail

list="${XDG_CONFIG_HOME:-$HOME/.config}/git-auto-ff/repos"
mkdir -p "$(dirname "$list")"
touch "$list"
for repo in "$@"; do
  repo="$(cd "$repo" && pwd)"
  grep -qxF "$repo" "$list" || echo "$repo" >>"$list"
done
[[ -s "$list" ]] || {
  echo "no repos listed in $list; pass at least one REPO" >&2
  exit 1
}

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
echo "repos ($list):"
cat "$list"
