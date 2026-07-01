# Factory Droid Configuration

Plugin configuration for [Factory Droid](https://factory.ai).

## Files

- `settings.json` - Factory settings (theme, `enabledPlugins` toggles)
- `plugins/known_marketplaces.json` - Registered plugin marketplaces

`plugins/installed_plugins.json` is intentionally **not** tracked (gitignored).
It pins per-machine plugin versions and cache paths that churn on `autoUpdate`,
so each machine manages its own real copy. `settings.json` (`enabledPlugins`) is
the shared source of truth for what's on.

## Installed Plugins

### Factory Official
- `core@factory-plugins` - Core review and simplify skills
- `droid-control@factory-plugins` - Terminal, browser, and desktop automation

### Tractorbeam Skills
- `git@skills` - Git workflows (commits, PRs, conflicts)
- `linear@skills` - Linear integration skill
- `code-style@skills` - Linting, formatting, testing, comments, and terraform
- `team-kit@skills` - Team collaboration tools
- `references@skills` - Reference documentation skill
- `mise@skills` - Puts pinned mise tools on PATH for shell tool sessions

## Enabled vs Disabled

`enabledPlugins` in `settings.json` is the on/off switch. Two enabled plugins
ship hooks:

- `mise@skills` — `SessionStart` hook puts the project's pinned mise tools on
  PATH (enabled).
- `references@skills` — `SessionStart` hook clones/updates reference repos and
  injects a version table (disabled).

`references@skills`, `reflect@skills`, and `documents@skills` are set to `false`
so their hooks don't run — mirroring the Claude Code config.

## Setup

`bootstrap.sh` stows this package, symlinking the tracked configs into
`~/.factory/`. The package mirrors the home layout under `.factory/`
so stow maps it correctly:
```bash
stow factory   # ~/.factory/settings.json + plugins/known_marketplaces.json -> here
```

## Adding New Plugins

```bash
# Add a marketplace
droid plugin marketplace add https://github.com/owner/repo

# Install a plugin
droid plugin install -s user plugin-name@marketplace
```

The tracked configs (`settings.json`, `known_marketplaces.json`) update in this
dotfiles directory via symlinks. `installed_plugins.json` stays machine-local.
