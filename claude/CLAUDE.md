# Claude Config Dotfiles

## Checking Claude Code Documentation

Do NOT rely on pretraining knowledge for Claude Code settings behavior, permission syntax, hook configuration, or any other Claude Code features. Your training data may be outdated or incorrect. Always use the `claude-code-guide` subagent to look up the current docs before making changes. Example: `Agent(subagent_type="claude-code-guide", prompt="How do permission wildcards work in settings.json?")`.

## Permissions

MCP tool permissions only support server-level wildcards (`mcp__server__*`), not partial name wildcards (e.g., `mcp__server__get_*`). To allow only read-only tools from an MCP server, each tool must be listed individually.

Bash permission wildcards: `:*` is deprecated, use ` *` (space-star) instead. You cannot combine a middle `*` with a trailing `:*` — use `Bash(git -C * show *)` not `Bash(git -C * show:*)`.

## RTK (Rust Token Killer)

The `rtk@tractorbeam` plugin registers a PreToolUse hook that transparently rewrites Bash commands (e.g., `git status` → `rtk git status`) for 60-90% token savings.
