#!/bin/bash
# Refresh Claude plugins by clearing cache and reinstalling

set -e

echo "==> Clearing plugin cache"
rm -rf ~/.claude/plugins/cache

echo "==> Refreshing marketplaces"
claude plugin marketplace remove claude-plugins-official 2>/dev/null || true
claude plugin marketplace remove tractorbeam 2>/dev/null || true
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add tractorbeamai/claude

echo "==> Installing plugins"
echo "  - context7"
claude plugin install context7@claude-plugins-official
echo "  - plugin-dev"
claude plugin install plugin-dev@claude-plugins-official
echo "  - frontend-design"
claude plugin install frontend-design@claude-plugins-official
echo "  - code-simplifier"
claude plugin install code-simplifier@claude-plugins-official
echo "  - core"
claude plugin install core@tractorbeam
echo "  - git"
claude plugin install git@tractorbeam
echo "  - linear"
claude plugin install linear@tractorbeam

echo "==> Done"
