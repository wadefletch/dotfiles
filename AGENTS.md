GNU Stow-based dotfiles for macOS. Each top-level directory is a stow package mirroring the target home directory structure. Run `stow <package>` from the repo root (or `bootstrap.sh` for everything).

## Structure

```
<package>/          # stow package — contents symlinked into ~
  .config/<app>/    # XDG config (ghostty, git, nvim, starship, alacritty)
  .zshrc, .zshenv   # shell config (zsh/)
  .ssh/config       # ssh config (ssh/)
  Library/...       # macOS paths (cursor/, vscode/, nightly-maintenance/)
  .cursor/          # Cursor CLI config (cursor/; --no-folding so ~/.cursor stays host-local)
  .claude/          # Claude Code runtime files (claude/)
  .pi/agent/        # Pi settings and MCP servers (pi/; --no-folding so ~/.pi stays host-local)
  .docker/           # tool config (docker/)
  .aws/config       # aws cli profiles (aws/) — live ~/.aws/config is assembled; credentials, SSO cache, config.local untracked
.githooks/          # git hooks (core.hooksPath); post-merge updates submodules
.agents/skills/     # repo-scoped skills shared by agent harnesses
.retired/           # reference-only packages (yabai, skhd-zig); dot-dirs aren't stowed
bootstrap.sh        # installs deps, stows packages, git hooks, WARP SSH host keys, macOS defaults (macOS + Linux)
```

## Key files

- `zsh/.zshrc` — shell config, aliases (`ga`, `gc`, `gs`, `gp`, `gl`, `gq`), `stopall`, `automerge`
- `zsh/.zshenv` — lightweight PATH exports (brew, local bin)
- `claude/AGENTS.md` — instructions for the Claude stow package itself
- `agent-config/.agents/AGENTS.md` — user-scoped agent instructions. `claude/.claude/CLAUDE.md`, `codex/.codex/AGENTS.md`, and `pi/.pi/agent/AGENTS.md` are symlinks to it, so edit this file, not the links.

## Conventions

- XDG paths (`.config/`) where the app supports it, macOS `Library/` paths otherwise.
- Every top-level directory is a stow package.
- The `claude/` package has a `.stow-local-ignore` — check it before adding files.
- Packages listed in `bootstrap.sh`'s `NO_FOLDING` (`agent-config`, `aws`, `claude`, `codex`, `cursor`, `pi`) target directories that also hold host-local state; stow links their files individually so the directory itself is never replaced.
