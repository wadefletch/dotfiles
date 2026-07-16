# dotfiles

GNU Stow-based dotfiles for macOS (with Linux support for the CLI packages). Each top-level directory is a stow package whose contents are symlinked into `~`.

## Packages

| Package | What it configures |
|---------|--------------------|
| alacritty | Alacritty terminal |
| cargo | Cargo (Rust) |
| claude | Claude Code settings and permissions |
| codex | Codex global instructions, portable defaults, and core plugins |
| crowdcontrol | CrowdControl config |
| cursor | Cursor editor settings and keybindings |
| docker | Docker daemon config |
| duti | Default app associations (macOS) |
| factory | Factory settings and plugin marketplaces |
| gh | GitHub CLI config (XDG) |
| ghostty | Ghostty terminal |
| git | Git config (XDG) |
| mise | Mise tool versions (node, python, …) |
| nightly-maintenance | LaunchAgent for nightly maintenance script (macOS) |
| nvim | Neovim config and markdownlint |
| skhd-zig | skhd hotkeys — window focus/swap/resize, alt-num space switching (macOS) |
| ssh | SSH config |
| starship | Starship prompt |
| terraform | Terraform CLI config |
| vscode | VS Code settings |
| wallpapers | Desktop wallpaper images (macOS) |
| yabai | yabai tiling window manager rules and signals (macOS) |
| zsh | Shell config, aliases, functions |

## Setup

```sh
git clone https://github.com/wadefletch/dotfiles ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs cross-platform dependencies (stow, zsh, neovim, gh, starship, mise, and Claude Code). On macOS it also installs the Coder CLI, brew casks, and the yabai/skhd stack. It then stows all packages, configures git hooks, and authorizes tailnet SSH between machines. Safe to re-run. macOS-only packages (cursor, duti, nightly-maintenance, skhd-zig, vscode, wallpapers, yabai) are skipped on Linux.

Codex portable defaults live in `codex/system/config.toml` and bootstrap installs them as `/etc/codex/config.toml`. Codex owns `~/.codex/config.toml` as host-local mutable state for project trust, UI preferences, local runtimes, connectors, and plugin metadata; dotfiles never links or edits it. Bootstrap updates the Tractorbeam plugin marketplace and ensures the five plugins in `codex/system/plugins.txt` are installed and enabled.

To stow manually:

```sh
stow git zsh ghostty   # individual packages
stow */                # everything
```

## Deploying changes

Changes land on machines by merging to `main`, then pulling on each machine, restowing changed packages, and restarting affected services such as skhd and yabai. The repo-committed Claude Code skill at `.claude/skills/deploy/SKILL.md` automates this across arrakis and corrino — ask Claude to "deploy dotfiles".

## Other scripts

**`check-brew-availability.sh`** — Lists apps installed in `/Applications` and `~/Applications` and searches Homebrew formulae/casks for matches, to find apps that could be managed by brew.
