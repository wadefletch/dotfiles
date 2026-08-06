# dotfiles

GNU Stow-based dotfiles for macOS (with Linux support for the CLI packages). Each top-level directory is a stow package whose contents are symlinked into `~`.

## Packages

| Package | What it configures |
|---------|--------------------|
| alacritty | Alacritty terminal |
| aws | AWS CLI profiles and Identity Center session |
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
| ssh | SSH config |
| starship | Starship prompt |
| terraform | Terraform CLI config |
| vscode | VS Code settings |
| wallpapers | Desktop wallpaper images (macOS) |
| zsh | Shell config, aliases, functions |

Window management is Raycast's, configured in the app itself.

`.retired/` holds packages kept only for reference — `yabai/` and `skhd-zig/`, whose configs document the workarounds they needed (yabai's scripting addition, the PAC ABI loader patch, the Ghostty native-tab relayout signal). Dot-directories aren't stow packages, so nothing in there is deployed.

## Setup

```sh
git clone https://github.com/wadefletch/dotfiles ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs cross-platform dependencies (stow, zsh, neovim, gh, starship, mise, and Claude Code). On macOS it also installs the Coder CLI and brew casks. It then stows all packages, configures git hooks, and authorizes tailnet SSH between machines. Safe to re-run. macOS-only packages (cursor, duti, nightly-maintenance, teams-link, vscode, wallpapers) are skipped on Linux.

The `aws` package tracks only `~/.aws/config`. Credentials and the Identity Center token cache stay host-local and untracked, so bootstrap stows this package without folding, like `codex`. Account IDs mirror the infra repo's `data/accounts.json`, which is their source of truth.

Codex portable defaults live in `codex/system/config.toml` and bootstrap installs them as `/etc/codex/config.toml`. Codex owns `~/.codex/config.toml` as host-local mutable state for project trust, UI preferences, local runtimes, connectors, and plugin metadata; dotfiles never links or edits it. Bootstrap updates the AWS and Tractorbeam plugin marketplaces, removes Tractorbeam plugins absent from `codex/system/plugins.txt`, and installs every plugin listed there for the ChatGPT desktop app and Codex CLI.

To stow manually:

```sh
stow git zsh ghostty   # individual packages
stow */                # everything
```

## Deploying changes

Changes land on machines by merging to `main`, then pulling on each machine, restowing changed packages, and reloading affected services. The repo-committed Claude Code skill at `.claude/skills/deploy/SKILL.md` automates this across arrakis and corrino — ask Claude to "deploy dotfiles".

## Other scripts

**`check-brew-availability.sh`** — Lists apps installed in `/Applications` and `~/Applications` and searches Homebrew formulae/casks for matches, to find apps that could be managed by brew.
