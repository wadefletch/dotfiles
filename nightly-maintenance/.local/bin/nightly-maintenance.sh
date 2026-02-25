#!/bin/zsh
# Nightly macOS maintenance script

echo "=== Nightly Maintenance: $(date) ===" >> /tmp/nightly-maintenance.log

# Homebrew update and cleanup
echo "Updating Homebrew..." >> /tmp/nightly-maintenance.log
/opt/homebrew/bin/brew update >> /tmp/nightly-maintenance.log 2>&1
/opt/homebrew/bin/brew upgrade >> /tmp/nightly-maintenance.log 2>&1
/opt/homebrew/bin/brew cleanup --prune=all >> /tmp/nightly-maintenance.log 2>&1

# pnpm store prune
echo "Pruning pnpm store..." >> /tmp/nightly-maintenance.log
/opt/homebrew/bin/pnpm store prune >> /tmp/nightly-maintenance.log 2>&1

# Cargo sweep (remove Rust artifacts older than 30 days)
echo "Running cargo sweep..." >> /tmp/nightly-maintenance.log
/Users/wadefletcher/.cargo/bin/cargo-sweep sweep --time 30 --recursive /Users/wadefletcher/Developer >> /tmp/nightly-maintenance.log 2>&1

echo "=== Maintenance complete ===" >> /tmp/nightly-maintenance.log
