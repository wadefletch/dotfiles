#!/bin/bash
# Refresh Claude plugins by clearing cache and reinstalling

set -e

echo "Clearing plugin cache..."
rm -rf ~/.claude/plugins/cache

echo "Adding marketplaces..."
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add tractorbeamai/claude

echo "Installing plugins..."
# Official marketplace plugins
claude plugin install context7@claude-plugins-official
claude plugin install plugin-dev@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install code-simplifier@claude-plugins-official

# Tractorbeam plugins
claude plugin install core@tractorbeam
claude plugin install git@tractorbeam
claude plugin install linear@tractorbeam

echo "Done!"
