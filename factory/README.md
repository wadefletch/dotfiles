# Factory Droid Configuration

Plugin configuration for [Factory Droid](https://factory.ai).

## Files

- `plugins/installed_plugins.json` - Installed plugins and their versions
- `plugins/known_marketplaces.json` - Registered plugin marketplaces

## Installed Plugins

### Factory Official
- `core@factory-plugins` - Core review and simplify skills
- `droid-control@factory-plugins` - Terminal, browser, and desktop automation

### Tractorbeam Skills
- `code-style@skills` - Linting, formatting, testing, and comment conventions
- `git@skills` - Git workflows (commits, PRs, conflicts)
- `linear@skills` - Linear integration skill
- `references@skills` - Reference documentation skill
- `reflect@skills` - Session reflection and improvement
- `documents@skills` - Document management skill
- `mise@skills` - Mise tool version management
- `team-kit@skills` - Team collaboration tools
- `legal-docs@skills` - Legal document organization

## Setup

`bootstrap.sh` stows this package, symlinking the plugin configs into
`~/.factory/plugins/`. The package mirrors the home layout under `.factory/`
so stow maps it correctly:
```bash
stow factory   # ~/.factory/plugins/{installed_plugins,known_marketplaces}.json -> here
```

## Adding New Plugins

```bash
# Add a marketplace
droid plugin marketplace add https://github.com/owner/repo

# Install a plugin
droid plugin install -s user plugin-name@marketplace
```

The plugin configs will automatically update in this dotfiles directory via symlinks.
