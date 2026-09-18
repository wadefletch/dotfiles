---
name: audit-agent-config
description: Audit personal and repository agent configuration for duplicate instructions, stale vendor references, mutable files under dotfile management, and cross-platform path assumptions. Use when checking agent harness consistency or dotfiles drift.
---

# Audit agent configuration

Run a read-only audit. Do not rewrite configuration as part of the audit.

1. Search `$HOME/.dotfiles` and `$HOME/Developer` with `rg --files --hidden`. Exclude `.git`, dependency directories, build output, caches, and agent-created worktrees.
2. Inventory `AGENTS.md`, agent skills, harness settings, plugin manifests, and MCP files.
3. Report any `CLAUDE.md`, duplicated instruction file at the same scope, deprecated `Bash(...:*)` permission, empty MCP file, retired-vendor reference, or absolute home-directory path in portable configuration.
4. Confirm `~/.claude/settings.json` is managed by the Claude Stow package and `~/.cursor/cli-config.json` is a regular host-local file.
5. Compare installed or enabled plugins with `~/.config/agent-harnesses/plugins.json` when the relevant harness CLI is available.
6. Return findings ranked by impact. Do not generate or commit a static inventory file.
