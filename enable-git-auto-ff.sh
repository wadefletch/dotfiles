#!/usr/bin/env bash
# Turn on git-auto-ff's daily timer on this Linux host. bootstrap.sh stows the
# units everywhere but never enables them; running this is the opt-in. Linger
# lets the per-user timer fire without an active login session.
set -euo pipefail

loginctl enable-linger "$USER" 2>/dev/null || sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now git-auto-ff.timer
systemctl --user list-timers git-auto-ff.timer
