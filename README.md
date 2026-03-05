# dotfiles

GNU Stow-based dotfiles for macOS. Each top-level directory is a stow package whose contents are symlinked into `~`.

## Packages

| Package | What it configures |
|---------|--------------------|
| alacritty | Alacritty terminal |
| cargo | Cargo (Rust) |
| claude | Claude Code settings and permissions |
| crowdcontrol | CrowdControl config |
| cursor | Cursor editor settings and keybindings |
| docker | Docker daemon config |
| gh | GitHub CLI config (XDG) |
| ghostty | Ghostty terminal |
| git | Git config (XDG) |
| nightly-maintenance | LaunchAgent for nightly maintenance script |
| nvim | Neovim config and markdownlint |
| ssh | SSH config |
| starship | Starship prompt |
| tmux | tmux config |
| vscode | VS Code settings |
| zsh | Shell config, aliases, functions |

## Setup

```sh
git clone https://github.com/wadefletch/dotfiles ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs stow (via brew/apt/dnf/yum/pacman), stows all packages, and configures git hooks. Safe to re-run. macOS-only packages (cursor, vscode, nightly-maintenance) are skipped on Linux.

To stow manually:

```sh
stow git zsh ghostty   # individual packages
stow */                # everything
```

## Other scripts

**`charlie.sh`** — Full-machine bootstrap for new team members. Installs Homebrew, Cursor, Ghostty, Node (via nvm), and configures git/zsh/starship from scratch. Run on a fresh Mac.

**`fresh.sh`** — Legacy bootstrap (Homebrew, nvm, Brewfile).
