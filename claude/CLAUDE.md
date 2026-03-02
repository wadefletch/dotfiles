# Claude Config Dotfiles

## Checking Claude Code Documentation

Do NOT rely on pretraining knowledge for Claude Code settings behavior, permission syntax, hook configuration, or any other Claude Code features. Your training data may be outdated or incorrect. Always use the `claude-code-guide` subagent to look up the current docs before making changes. Example: `Agent(subagent_type="claude-code-guide", prompt="How do permission wildcards work in settings.json?")`.

## Permissions

MCP tool permissions only support server-level wildcards (`mcp__server__*`), not partial name wildcards (e.g., `mcp__server__get_*`). To allow only read-only tools from an MCP server, each tool must be listed individually.

`mcp__claude_ai_*` tools are user-level only. Never include them in project-scoped settings (`.claude/settings.json` or `.claude/settings.local.json`).
