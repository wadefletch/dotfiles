# dotfiles

GNU Stow-based dotfiles for macOS (with Linux support for the CLI packages). Each top-level directory is a stow package whose contents are symlinked into `~`.

## Packages

| Package | What it configures |
|---------|--------------------|
| agent-config | Shared plugin intent and personal agent skills |
| alacritty | Alacritty terminal |
| cargo | Cargo (Rust) |
| claude | Claude Code settings and runtime helpers |
| codex | Codex portable defaults and service launchers |
| crowdcontrol | CrowdControl config |
| cursor | Cursor editor settings and keybindings (macOS) |
| docker | Docker daemon config |
| duti | Default app associations (macOS) |
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

`bootstrap.sh` installs cross-platform dependencies (stow, zsh, neovim, ripgrep, gh, jq, starship, mise, and Claude Code) and macOS brew casks. It then stows all packages, reconciles agent plugins, installs the locked Mise toolset (including the Fleetctl version matching the Fleet server), configures git hooks, and pins SSH host keys for WARP-reachable machines. Safe to re-run. macOS-only packages (cursor, duti, nightly-maintenance, teams-link, vscode, wallpapers) are skipped on Linux.

Each harness owns its settings in its conventional Stow package. Claude Code settings live at `claude/.claude/settings.json`; Cursor's CLI configuration is fully host-local and unmanaged. Runtime caches, account metadata, UI state, and credentials stay out of Git. `agent-config/.config/agent-harnesses/plugins.json` is shared only because it describes desired plugins for both Claude and Codex.

Repository instructions use `AGENTS.md`. Shared personal workflows live under `agent-config/.agents/skills/` and are stowed into the standard user skill directory.

Codex portable defaults live in `codex/system/config.toml` and bootstrap installs them as `/etc/codex/config.toml`. Codex owns `~/.codex/config.toml` as host-local mutable state for project trust, UI preferences, local runtimes, connectors, and plugin metadata; dotfiles never links or edits it. Bootstrap reconciles its managed marketplaces and plugins from the shared manifest.

Tractorbeam read-only service credentials live in the macOS login Keychain. The
`fleetctl-readonly` launcher reads the API-only Observer token from the
`fleet-observer-api-token` service and builds a mode-0600 disposable Fleet
config for each invocation; it never reads the ordinary `~/.fleet/config`. The
`install-okta-mcp-tool` installs the pinned Okta MCP server into uv's persistent
tool environment. `codex-okta-mcp` launches that installed executable, reads the
base64-encoded Okta service app private key from the `okta-mcp-private-key`
service, and exposes only the app's read-scoped tools. The upstream server's
OAuth access-token cache is redirected away from the macOS Keychain into a
mode-0600 disposable file that the launcher removes on exit, avoiding Python
Keychain authorization prompts. Credential values are host-local and never
stowed.

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
stow --no-folding agent-config codex cursor
./bootstrap.sh         # everything, including host-local policy reconciliation
```

## Deploying changes

Changes land on machines by merging to `main`, then pulling on each machine, restowing changed packages, and reloading affected services. The repo-committed skill at `.agents/skills/deploy/SKILL.md` automates this across arrakis and corrino — ask an agent to "deploy dotfiles".

## Other scripts

**`check-brew-availability.sh`** — Lists apps installed in `/Applications` and `~/Applications` and searches Homebrew formulae/casks for matches, to find apps that could be managed by brew.

**`check-agent-config.sh`** — Validates the shared agent policies, canonical instruction filename, permission syntax, portability, and mutable-file boundary. Bootstrap runs it before changing the host.
