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

Install [GNU Stow](https://www.gnu.org/software/stow/), then from the repo root:

```sh
# stow individual packages
stow git zsh ghostty

# or stow everything
stow */
```

After cloning, symlink the git hooks:

```sh
git config core.hooksPath .githooks
```

## Bootstrap

**`charlie.sh`** — Full-machine bootstrap for new team members. Installs Homebrew, Cursor, Ghostty, Node (via nvm), and configures git/zsh/starship from scratch. Run on a fresh Mac.

**`fresh.sh`** — Legacy bootstrap (Homebrew, nvm, Brewfile).
