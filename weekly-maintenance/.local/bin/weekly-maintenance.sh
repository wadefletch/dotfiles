#!/bin/zsh
# Weekly macOS maintenance script

echo "=== Weekly Maintenance: $(date) ===" >> /tmp/weekly-maintenance.log

# Homebrew update and cleanup
echo "Updating Homebrew..." >> /tmp/weekly-maintenance.log
/opt/homebrew/bin/brew update >> /tmp/weekly-maintenance.log 2>&1
/opt/homebrew/bin/brew upgrade >> /tmp/weekly-maintenance.log 2>&1
/opt/homebrew/bin/brew cleanup --prune=all >> /tmp/weekly-maintenance.log 2>&1

# pnpm store prune
echo "Pruning pnpm store..." >> /tmp/weekly-maintenance.log
/opt/homebrew/bin/pnpm store prune >> /tmp/weekly-maintenance.log 2>&1

# Cargo sweep (remove Rust artifacts older than 30 days)
echo "Running cargo sweep..." >> /tmp/weekly-maintenance.log
/Users/wadefletcher/.cargo/bin/cargo-sweep sweep --time 30 --recursive /Users/wadefletcher/Developer >> /tmp/weekly-maintenance.log 2>&1

echo "=== Maintenance complete ===" >> /tmp/weekly-maintenance.log
