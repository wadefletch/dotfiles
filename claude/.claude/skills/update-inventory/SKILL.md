# Skill: Update Claude Code Config Inventory

Update the inventory of Claude Code configuration files across ~/Developer.

## Step 1: Search for config files

Run three Glob searches in parallel:

```
pattern: "**/CLAUDE.md"         path: "/Users/wadefletcher/Developer"
pattern: "**/.claude/settings.json"       path: "/Users/wadefletcher/Developer"
pattern: "**/.claude/settings.local.json" path: "/Users/wadefletcher/Developer"
```

Filter out any results containing these path segments: `node_modules`, `.git`, `vendor`, `dist`, `build`, `target`, `.next`, `__pycache__`, `.turbo`, `.cache`, `.claude/references`.

## Step 2: Organize results into projects

Separate results into two groups:

- **Tractorbeam**: projects under `~/Developer/Tractorbeam/`
- **Personal**: projects directly under `~/Developer/` (not under Tractorbeam)

For each project, determine:

- **Project name**: the path relative to the group root (e.g., `client-carlyle/carlyle-monorepo`)
- **CLAUDE.md locations**: list where CLAUDE.md files exist relative to the project root. Use `root` for a CLAUDE.md at the project root, or the subdirectory path (e.g., `tests/`, `infra/terraform/`). Use `-` if none.
- **settings.json**: `yes` if `.claude/settings.json` exists at the project root, `-` otherwise.
- **settings.local.json**: `yes` if `.claude/settings.local.json` exists at the project root, `-` otherwise.

A "project root" is the first directory level under the group root (one or two levels deep for nested orgs like `client-carlyle/`). CLAUDE.md files may exist at the project root or in subdirectories — list all locations comma-separated.

## Step 3: Write the inventory file

Use the Write tool to write the updated inventory to `/Users/wadefletcher/.dotfiles/claude/inventory.md` in this exact format:

```markdown
# Claude Code Config Inventory

Tracked Claude Code configuration files across ~/Developer.

## Active Projects

### Tractorbeam

| Project | CLAUDE.md | settings.json | settings.local.json |
|---------|-----------|---------------|---------------------|
| <project> | <locations or -> | <yes or -> | <yes or -> |

### Personal

| Project | CLAUDE.md | settings.json | settings.local.json |
|---------|-----------|---------------|---------------------|
| <project> | <locations or -> | <yes or -> | <yes or -> |
```

Sort projects alphabetically within each group.

## Notes

- The inventory file is excluded from stow via `.stow-local-ignore`.
- This skill requires no user input. Run it to completion without prompting.
