# dotfiles

GNU Stow-based dotfiles for macOS (with Linux support for the CLI packages). Each top-level directory is a stow package whose contents are symlinked into `~`.

## Packages

| Package | What it configures |
|---------|--------------------|
| agent-config | Shared personal agent skills and user-scoped instructions |
| alacritty | Alacritty terminal |
| aws | AWS CLI profiles and Identity Center session |
| claude | Claude Code settings and runtime helpers |
| codex | Codex portable defaults and service launchers |
| crowdcontrol | CrowdControl config |
| cursor | Cursor editor settings and keybindings (macOS) |
| docker | Docker daemon config |
| duti | Default app associations (macOS) |
| gh | GitHub CLI config (XDG) |
| ghostty | Ghostty terminal |
| git | Git config (XDG) |
| git-auto-ff | Fast-forwards chosen checkouts to origin/main daily at 05:00 when safe, via a systemd user timer (Linux) or LaunchAgent (macOS); enable per host with `./enable-git-auto-ff.sh REPO...` |
| mise | Mise tool versions (node, python, …) |
| nightly-maintenance | LaunchAgent for nightly maintenance script (macOS) |
| nvim | Neovim config and markdownlint |
| office-tv-relay | Fire TV relay and Cloudflare Tunnel LaunchAgents for beam's `office_tv` tool (arrakis only) |
| pi | Pi settings and MCP configuration |
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

`bootstrap.sh` installs cross-platform dependencies (stow, zsh, neovim, ripgrep, gh, starship, mise, and Claude Code), FFF's MCP server through Homebrew when available, and macOS brew casks. It then stows all packages, adds the portable Claude Code MCP servers when missing, reconciles Codex plugins, installs the locked Mise toolset (including the Fleetctl version matching the Fleet server), configures git hooks, and pins SSH host keys for WARP-reachable machines. Safe to re-run. macOS-only packages (cursor, duti, nightly-maintenance, teams-link, vscode, wallpapers) are skipped on Linux. `office-tv-relay` is stowed and enabled only on arrakis.

Each harness owns its settings in its conventional Stow package. Claude Code settings live at `claude/.claude/settings.json`; Cursor's CLI configuration is fully host-local and unmanaged. Pi's live `settings.json` is stowed deliberately, so preference and package changes made from Pi update the dotfiles checkout. Runtime caches, account metadata, UI state, credentials, Pi sessions, and installed package contents stay out of Git.

The `aws` package tracks the managed AWS CLI profiles. Bootstrap stows the package without folding so `~/.aws` stays a real directory (SSO cache and credentials are host-local), then `sync-aws-config` writes `~/.aws/config` as a regular file from the tracked profiles plus optional `~/.aws/config.local`. That overlay is where generated Tractorbeam agent profiles live — they must not be a symlink into the repo. Account IDs mirror the infra repo's `data/accounts.json`, which is their source of truth. `aws-login` (also in this package) refreshes the shared Identity Center session. Set `CARLYLE_EC2=1` before running bootstrap to skip this package entirely (and its config sync) on a host that manages its own `~/.aws/config` and `aws-login`.

FFF and the public, credential-free documentation index (`docs-index`, served by Mintlify) are configured for Claude Code, Cursor, Codex, and Pi, and so are Better Stack, Secureframe, WorkOS, Okta, Aikido, and the X API (`xapi`). Pi uses built-in MCP (`~/.pi/agent/mcp.json`) for its servers and the native `@ff-labs/pi-fff` package for FFF; Pi loads the Tractorbeam skills as a git package that tracks `tractorbeamai/skills` on `main`. Codemode is on so classifier models such as TypeSafe Jev can run from scripts once a Jev provider is authenticated (`CLOUDFLARE_API_KEY` + `CLOUDFLARE_ACCOUNT_ID`, or `TYPESAFE_API_KEY`). FFF inherits each harness's working directory and refuses to index the home or filesystem root by default. Better Stack, Secureframe, and Cloudflare are remote servers that each harness signs in to once. Aikido offers a browser sign-in on first use and keeps its token in the OS keychain. The X API server uses the app credentials and token that `xurl` keeps in `~/.xurl/auth.yml` (`npx -y @xdevplatform/xurl auth apps add` and `auth oauth2` once per machine). Okta needs the service-app key in the login Keychain on macOS, or in a private key file elsewhere (see below); without it that server fails to start on that machine.

The `aws-core`, `cloudflare`, and `workos` plugins come from their vendors' marketplaces, `aws/agent-toolkit-for-aws`, `cloudflare/skills`, and `workos/skills`, in both Claude Code and Codex; bootstrap installs them. Cloudflare's MCP server arrives with its plugin (Cursor and Pi list it directly); the WorkOS plugin carries only skills for Claude Code and Codex, so its server is registered alongside the other shared servers. Claude Code takes Aikido from its vendor marketplace too (`AikidoSec/aikido-claude-plugin`), which brings Aikido's MCP server and its setup, scan, and issues skills; Aikido publishes no Codex or Pi package, so Codex, Pi, and Cursor run `npx -y @aikidosec/mcp` directly. The `aws-core` plugin bundles an `aws-mcp` server that signs with whatever AWS credentials are in the environment, so no harness runs it. Instead every harness defines its own `aws-mcp`, which launches the `mcp-proxy-for-aws-cli` that bootstrap installs at a pinned version, restricted to the read-only `agent-read-*` profiles through `AWS_MCP_PROXY_PROFILES`. Claude Code registers that server at user scope, denies the plugin's copy (`deniedMcpServers`), and sets the profiles in its settings `env`; Codex's system config entry replaces the plugin's by name; Pi and Cursor list it in their `mcp.json`. The profile list mirrors the read profiles in the infra repo, which is the only place write profiles are exposed. The plugin's `signing-in-to-aws` skill contradicts Tractorbeam's `aws-access` rule that agents never authenticate, so it is turned off in Claude Code (`skillOverrides`) and Codex (`skills.config`).

On the Carlyle EC2 devbox (`CARLYLE_EC2=1`), Tractorbeam's AWS conventions don't apply: its `aws-access` skill and `agent-read-*` profiles target Tractorbeam's accounts, not Carlyle's. Claude Code has no user-scope `settings.local.json`, so bootstrap replaces the stowed `~/.claude/settings.json` symlink there with a real file: the shared settings deep-merged (`jq '*'`) with `claude/.claude/settings.carlyle-ec2.json`. That overlay turns off `tractorbeam:aws-access` and the `cloudflare` and `aikido` plugins, and pins the AWS MCP proxy to the host's `gpe-readonly` and `ais` profiles. Bootstrap also skips installing the Cloudflare and Aikido plugins there and registers only the `fff`, `docs-index`, and `aws-mcp` MCP servers, leaving out Tractorbeam's service accounts (Better Stack, Secureframe, WorkOS, Okta, X API). The other Tractorbeam plugins and skills stay on. Settings changes made from Claude Code on that host land in the generated file, not the repo, and the next bootstrap moves them to `settings.json.bak`; put lasting changes in the tracked files.

Repository instructions use `AGENTS.md`. Shared personal workflows live under `agent-config/.agents/skills/` and are stowed into the standard user skill directory.

User-scoped instructions for every harness live in one file, `agent-config/.agents/AGENTS.md`. Each harness reads it through a symlink at its own user-scope path: `~/.claude/CLAUDE.md` for Claude Code, `~/.codex/AGENTS.md` for Codex, and `~/.pi/agent/AGENTS.md` for Pi. Cursor has no file-based user instructions, so it is not covered.

Codex portable defaults live in `codex/system/config.toml` and bootstrap installs them as `/etc/codex/config.toml`. Codex owns `~/.codex/config.toml` as host-local mutable state for project trust, UI preferences, local runtimes, connectors, and plugin metadata; dotfiles never links or edits it. Bootstrap reconciles its managed marketplaces and plugins from `codex/system/plugins.txt`.

Tractorbeam read-only service credentials live in the macOS login Keychain. The
`fleetctl-readonly` launcher reads the API-only Observer token from the
`fleet-observer-api-token` service and builds a mode-0600 disposable Fleet
config for each invocation; it never reads the ordinary `~/.fleet/config`. The
`install-okta-mcp-tool` installs the pinned Okta MCP server into uv's persistent
tool environment. `codex-okta-mcp` launches that installed executable, reads the
Okta service app private key, and exposes only the app's read-scoped tools. On
macOS the key is base64-encoded in the `okta-mcp-private-key` Keychain service;
other hosts keep the PEM at `~/.config/okta-mcp/private-key.pem` (override with
`OKTA_MCP_PRIVATE_KEY_FILE`), and the launcher refuses a file that group or
other users can read. The upstream server's
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

On a host without a Keychain, install the PEM readable only by you:

```sh
install -d -m 0700 ~/.config/okta-mcp
install -m 0600 /path/to/okta-mcp-private-key.pem ~/.config/okta-mcp/private-key.pem
```

To stow manually:

```sh
stow git zsh ghostty   # individual packages
stow --no-folding agent-config aws claude codex cursor git-auto-ff office-tv-relay pi
sync-aws-config          # assemble ~/.aws/config (managed + config.local)
./bootstrap.sh         # everything
```

## Office TV relay

The `office-tv-relay` package runs on arrakis only: bootstrap stows it there, installs `cloudflared` and the `android-platform-tools` cask (adb), and loads its two LaunchAgents; every other host skips it. `com.wadefletcher.office-tv-relay` is a Bun (TypeScript) relay, `~/.local/share/office-tv-relay/relay.ts` run with mise's `bun`, that serves a fixed allowlist of Fire TV adb actions (status, screenshot, open the sign or a URL, remote keys) on `127.0.0.1:8765` and drives `/opt/homebrew/bin/adb`. The first time it starts, macOS asks whether bun may find devices on the local network; allow it (or turn bun on later under System Settings → Privacy & Security → Local Network). Without that permission the relay still answers but cannot reach the TV. `com.wadefletcher.office-tv-tunnel` runs the `office-tv` Cloudflare Tunnel (account tractorbeam-nonprod), which carries beam's Workers VPC Service to the relay.

Both read a secret from the login Keychain when they start. `office-tv-relay-secret` is the bearer secret beam sends as `OFFICE_TV_RELAY_SECRET`; `office-tv-tunnel-token` is the tunnel's run token. Add each interactively so it stays out of shell history:

```sh
security add-generic-password -a "$USER" -s office-tv-relay-secret -U -w
security add-generic-password -a "$USER" -s office-tv-tunnel-token -U -w
```

Bootstrap warns when either is missing and loads the agents anyway; launchd retries them every 30 seconds until the items exist. Logs go to `/tmp/office-tv-relay.log` and `/tmp/office-tv-tunnel.log`.

The other side lives in `tractorbeamai/beam`: the `office_tv` tool in `agents/beam/office-tv.ts`, and the Fire TV sign app in `firetv/`.

## Deploying changes

Changes land on machines by merging to `main`, then pulling on each machine, restowing changed packages, and reloading affected services. The repo-committed skill at `.agents/skills/deploy/SKILL.md` automates this across arrakis and corrino — ask an agent to "deploy dotfiles".

## Other scripts

**`check-brew-availability.sh`** — Lists apps installed in `/Applications` and `~/Applications` and searches Homebrew formulae/casks for matches, to find apps that could be managed by brew.
