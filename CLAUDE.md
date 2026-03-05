GNU Stow-based dotfiles for macOS. Each top-level directory is a stow package mirroring the target home directory structure. Run `stow <package>` from the repo root (or `stow-all.sh` for everything).

## Structure

```
<package>/          # stow package — contents symlinked into ~
  .config/<app>/    # XDG config (ghostty, git, nvim, starship, tmux, alacritty)
  .zshrc, .zshenv   # shell config (zsh/)
  .ssh/config       # ssh config (ssh/)
  Library/...       # macOS paths (cursor/, vscode/, nightly-maintenance/)
  .claude/          # claude code settings (claude/)
  .cargo/, .docker/ # tool config (cargo/, docker/)
.githooks/          # git hooks (core.hooksPath); post-merge updates submodules
bootstrap.sh        # installs stow, stows packages, sets up git hooks (macOS + Linux)
charlie.sh          # standalone bootstrap for new teammates (not stow-based)
fresh.sh            # legacy bootstrap (installs brew, nvm, brewfile)
ORGANIZATION.md     # rules for organizing ~/Documents and ~/Downloads
```

## Key files

- `zsh/.zshrc` — shell config, aliases (`ga`, `gc`, `gs`, `gp`, `gl`, `gq`), `stopall`, `automerge`
- `zsh/.zshenv` — lightweight PATH exports (brew, local bin)
- `claude/CLAUDE.md` — instructions for the claude stow package itself
- `charlie.sh` — opinionated full-machine bootstrap for new team members

## Conventions

- XDG paths (`.config/`) where the app supports it, macOS `Library/` paths otherwise.
- Every top-level directory is a stow package.
- The `claude/` package has a `.stow-local-ignore` — check it before adding files.
