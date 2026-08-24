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

`bootstrap.sh` installs cross-platform dependencies (stow, zsh, neovim, gh, starship, mise, and Claude Code). On macOS it also installs the Coder CLI and brew casks. It then stows all packages, installs the locked Mise toolset (including the Fleetctl version matching the Fleet server), configures git hooks, and authorizes tailnet SSH between machines. Safe to re-run. macOS-only packages (cursor, duti, nightly-maintenance, teams-link, vscode, wallpapers) are skipped on Linux.

Codex portable defaults live in `codex/system/config.toml` and bootstrap installs them as `/etc/codex/config.toml`. Codex owns `~/.codex/config.toml` as host-local mutable state for project trust, UI preferences, local runtimes, connectors, and plugin metadata; dotfiles never links or edits it. Bootstrap updates the AWS and Tractorbeam plugin marketplaces, removes Tractorbeam plugins absent from `codex/system/plugins.txt`, and installs every plugin listed there for the ChatGPT desktop app and Codex CLI.

Tractorbeam read-only service credentials live in the macOS login Keychain. The
`fleetctl-readonly` launcher reads the API-only Observer token from the
`fleet-observer-api-token` service and builds a mode-0700 disposable runtime
directory for each invocation, containing both Fleet configuration and Mise
state; it never reads the ordinary `~/.fleet/config`. The
`codex-okta-mcp` launcher reads the base64-encoded Okta service app private key
from the `okta-mcp-private-key` service and exposes only the app's read-scoped
tools. The upstream server's OAuth access-token cache is redirected away from
the macOS Keychain into a mode-0600 disposable file that the launcher removes
on exit, avoiding Python Keychain authorization prompts. Credential values are
host-local and never stowed.

Add the Fleet token interactively so it does not enter shell history:

```sh
security add-generic-password \
  -a "$USER" \
  -s fleet-observer-api-token \
  -U \
  -w
```

Store the Okta PEM as one base64-encoded Keychain password. The value passed to
`security` is briefly present in that process's arguments, so perform this once
from a trusted local terminal and clear the shell variable immediately:

```sh
private_key_base64=$(base64 < /path/to/okta-mcp-private-key.pem | tr -d '\n')
security add-generic-password \
  -a "$USER" \
  -s okta-mcp-private-key \
  -U \
  -w "$private_key_base64"
unset private_key_base64
```

Register Okta in the host-local `~/.codex/config.toml`; this is a local runtime,
not a portable default:

```toml
[mcp_servers.okta]
command = "codex-okta-mcp"
args = []
default_tools_approval_mode = "approve"
startup_timeout_sec = 60
tool_timeout_sec = 60
```

To stow manually:

```sh
stow git zsh ghostty   # individual packages
stow */                # everything
```

## Deploying changes

Changes land on machines by merging to `main`, then pulling on each machine, restowing changed packages, and reloading affected services. The repo-committed Claude Code skill at `.claude/skills/deploy/SKILL.md` automates this across arrakis and corrino — ask Claude to "deploy dotfiles".

## Other scripts

**`check-brew-availability.sh`** — Lists apps installed in `/Applications` and `~/Applications` and searches Homebrew formulae/casks for matches, to find apps that could be managed by brew.
