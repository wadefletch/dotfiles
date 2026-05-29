#!/bin/zsh
# Nightly macOS maintenance script

# launchd starts us with a bare PATH; put mise shims, Homebrew, and the
# cargo bindir up front so brew/pnpm/cargo-sweep/git all resolve.
export PATH="$HOME/.local/share/mise/shims:/opt/homebrew/bin:$HOME/.cargo/bin:$PATH"

LOG=/tmp/nightly-maintenance.log
CARGO_SWEEP="$HOME/.cargo/bin/cargo-sweep"
DEVELOPER="$HOME/Developer"
CONSTELLATION="$DEVELOPER/Tractorbeam/constellation"

echo "=== Nightly Maintenance: $(date) ===" >> "$LOG"

# Homebrew update and cleanup
echo "Updating Homebrew..." >> "$LOG"
brew update >> "$LOG" 2>&1
brew upgrade >> "$LOG" 2>&1
brew cleanup --prune=all >> "$LOG" 2>&1

# pnpm store prune (pnpm is mise-managed; skip cleanly if no global shim)
echo "Pruning pnpm store..." >> "$LOG"
if command -v pnpm >/dev/null 2>&1; then
  pnpm store prune >> "$LOG" 2>&1
else
  echo "pnpm not on PATH, skipping store prune" >> "$LOG"
fi

# Drop the rust/target of any constellation worktree whose branch is fully
# merged into main. Two-dot `origin/main..<branch>` is empty only when the
# branch carries nothing main lacks; squash-merges past which main has moved
# read as non-empty, so this never deletes an unmerged worktree's artifacts
# (the time-based sweep below reclaims those).
echo "Reclaiming merged constellation worktree targets..." >> "$LOG"
if [ -d "$CONSTELLATION" ]; then
  (
    cd "$CONSTELLATION" || exit 0
    git fetch --quiet origin main 2>/dev/null
    git worktree list --porcelain | awk '/^worktree /{print $2}' | while read -r wt; do
      [ -d "$wt/rust/target" ] || continue
      br=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null)
      { [ -z "$br" ] || [ "$br" = "main" ]; } && continue
      if [ -z "$(git -C "$wt" diff --name-only "origin/main..$br" 2>/dev/null)" ]; then
        echo "  merged: removing $wt/rust/target" >> "$LOG"
        rm -rf "$wt/rust/target"
      fi
    done
  )
fi

# Sweep rust artifacts unused for 14 days across every project under Developer.
# --hidden is load-bearing: worktrees live under .claude/worktrees, and the
# recursive walk skips dot-directories without it.
echo "Running cargo sweep..." >> "$LOG"
"$CARGO_SWEEP" sweep --time 14 --recursive --hidden "$DEVELOPER" >> "$LOG" 2>&1

echo "=== Maintenance complete ===" >> "$LOG"
