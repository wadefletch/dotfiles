#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# Ensure curl-installed tools (starship, mise) are findable later in this
# script. .zshenv adds this for interactive shells, but we run as bash.
export PATH="$HOME/.local/bin:$PATH"

# macOS-only stow packages (contain Library/ paths or macOS-only tools)
MACOS_ONLY="cursor duti nightly-maintenance teams-link vscode wallpapers"

# Packages for one machine, matched on its lowercased LocalHostName (empty on
# Linux, so none of them apply there).
HOST_NAME=""
[[ "$OS" == "Darwin" ]] && HOST_NAME="$(scutil --get LocalHostName | tr '[:upper:]' '[:lower:]')"
ARRAKIS_ONLY="office-tv-relay"

# Packages this host opts out of, driven by env. The Carlyle EC2 devbox manages
# its own host-local ~/.aws/config and aws-login, so CARLYLE_EC2=1 skips the aws
# package (and its config sync) to leave that host-local setup untouched.
SKIP_PACKAGES=""
[[ -n "${CARLYLE_EC2:-}" ]] && SKIP_PACKAGES+=" aws"

# Stow packages whose target directory also holds host-local state, so the
# tracked files must be linked individually rather than by folding the
# directory itself into a symlink.
NO_FOLDING="agent-config aws claude codex cursor git-auto-ff office-tv-relay pi"

# CLI packages to install (must exist in brew + apt/dnf/yum/pacman)
PACKAGES=(git neovim ripgrep stow zsh eza)

# macOS apps and fonts (brew casks)
CASKS=(cursor ghostty)
# adb, which the office TV relay drives
[[ "$HOST_NAME" == "arrakis" ]] && CASKS+=(android-platform-tools)

info() { printf '  [ .. ] %s\n' "$1"; }
ok() { printf '  [ OK ] %s\n' "$1"; }
warn() { printf '  [WARN] %s\n' "$1" >&2; }
fail() {
  printf '  [FAIL] %s\n' "$1" >&2
  exit 1
}

# --- Package manager helpers -------------------------------------------------

apt_get() {
  local attempt
  local output
  local status=0

  for ((attempt = 1; attempt <= 60; attempt++)); do
    if output="$(sudo apt-get "$@" 2>&1)"; then
      [[ -z "$output" ]] || printf '%s\n' "$output"
      return 0
    else
      status=$?
    fi

    if [[ "$output" != *"Could not get lock"* && "$output" != *"Unable to lock"* ]]; then
      printf '%s\n' "$output" >&2
      return "$status"
    fi

    if ((attempt == 1)); then
      info "waiting for another apt process"
    fi
    sleep 2
  done

  printf '%s\n' "$output" >&2
  return "$status"
}

pkg_install() {
  case "$OS" in
  Darwin) brew install "$@" ;;
  Linux)
    if command -v apt-get &>/dev/null; then
      apt_get install -y -qq "$@"
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y "$@"
    elif command -v yum &>/dev/null; then
      sudo yum install -y "$@"
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm "$@"
    else
      fail "unsupported package manager"
    fi
    ;;
  esac
}

pkg_update() {
  case "$OS" in
  Darwin) brew update ;;
  Linux)
    if command -v apt-get &>/dev/null; then
      apt_get update -qq
    elif command -v dnf &>/dev/null; then
      sudo dnf check-update -q || true
    elif command -v yum &>/dev/null; then
      sudo yum check-update -q || true
    fi
    ;;
  esac
}

# --- gh (GitHub CLI) ---------------------------------------------------------
# Needs its own repo on Linux — not in default apt/dnf/yum repos.
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md

install_gh() {
  if command -v gh &>/dev/null; then
    ok "gh already installed"
    return
  fi

  info "installing gh"

  case "$OS" in
  Darwin)
    brew install gh
    ;;
  Linux)
    if command -v apt-get &>/dev/null; then
      sudo mkdir -p -m 755 /etc/apt/keyrings
      wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg |
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      apt_get update -qq
      apt_get install -y -qq gh
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y 'dnf-command(config-manager)'
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo dnf install -y gh --repo gh-cli
    elif command -v yum &>/dev/null; then
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo yum install -y gh
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm github-cli
    fi
    ;;
  esac

  ok "gh"
}

# --- Install dependencies ----------------------------------------------------

install_deps() {
  local app bin formula formulae installed_casks pkg zsh_path

  info "updating package index"
  pkg_update
  ok "package index updated"

  for pkg in "${PACKAGES[@]}"; do
    # Map package name -> binary name where they differ (e.g. neovim -> nvim).
    case "$pkg" in
    neovim) bin="nvim" ;;
    *) bin="$pkg" ;;
    esac
    if command -v "$bin" &>/dev/null; then
      ok "$pkg already installed"
    else
      info "installing $pkg"
      # Not every distro packages everything (Amazon Linux 2023 has neither
      # neovim nor eza), so a missing package is a warning, not a failure.
      if pkg_install "$pkg"; then
        ok "$pkg"
      else
        warn "$pkg not available from the package manager; skipping"
      fi
    fi
  done

  install_gh

  # starship (curl installer — not reliably packaged across distros)
  if command -v starship &>/dev/null; then
    ok "starship already installed"
  else
    info "installing starship"
    # Install into a user-writable bin dir so the upstream installer skips
    # its `sudo -v` priming step. `sudo -v` requires a real password even
    # under NOPASSWD: ALL because validation has no target command for the
    # rule to match.
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    ok "starship"
  fi

  # claude code (native installer — auto-updates)
  if command -v claude &>/dev/null; then
    ok "claude code already installed"
  else
    info "installing claude code"
    curl -fsSL https://claude.ai/install.sh | bash
    ok "claude code"
  fi

  # mise (manages node/python/etc. per the stowed ~/.config/mise/config.toml).
  # Linux distros don't reliably package it, so use the upstream installer
  # which lands at ~/.local/bin/mise.
  if command -v mise &>/dev/null; then
    ok "mise already installed"
  else
    info "installing mise"
    case "$OS" in
    Darwin) brew install mise ;;
    Linux) curl -fsSL https://mise.run | sh ;;
    esac
    ok "mise"
  fi

  # Switch login shell to zsh. Stowed config only loads if zsh is the
  # actual login shell, but apt/brew installing zsh doesn't change that.
  # Linux package installs do not normally change the login shell.
  if command -v zsh &>/dev/null && [[ "${SHELL:-}" != *"/zsh" ]]; then
    zsh_path="$(command -v zsh)"
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    sudo chsh -s "$zsh_path" "$USER"
    ok "default shell -> zsh (relog to take effect)"
  fi

  # macOS GUI apps
  if [[ "$OS" == "Darwin" ]]; then
    installed_casks="$(brew list --cask -1 2>/dev/null)"
    for app in "${CASKS[@]}"; do
      # Match the cask itself or any variant tap (e.g. ghostty@tip satisfies
      # ghostty). Without this, brew errors on conflicting variants.
      if grep -qE "^${app}(@|$)" <<<"$installed_casks"; then
        ok "$app already installed"
      else
        info "installing $app"
        # --adopt takes ownership of an existing /Applications/<App>.app
        # rather than erroring (e.g. app installed manually before bootstrap).
        brew install --cask --adopt "$app"
        ok "$app"
      fi
    done

    # macOS-only brew formulae. arrakis also runs the office-tv tunnel, which
    # needs cloudflared 2025.7+ for Workers VPC; Homebrew's is current.
    formulae=(duti tailscale)
    [[ "$HOST_NAME" == "arrakis" ]] && formulae+=(cloudflared)
    for formula in "${formulae[@]}"; do
      if command -v "$formula" &>/dev/null ||
        [[ "$formula" == "tailscale" && -d "/Applications/Tailscale.app" ]]; then
        ok "$formula already installed"
      else
        info "installing $formula"
        brew install "$formula"
        ok "$formula"
      fi
    done
  fi

  # FFF publishes its MCP server as a Homebrew formula for macOS and Linux.
  # Keep its installation separate from distro packages, where it is not
  # available.
  if command -v fff-mcp &>/dev/null; then
    ok "fff-mcp already installed"
  elif command -v brew &>/dev/null; then
    info "installing fff-mcp"
    brew install dmtrKovalenko/fff/fff-mcp
    ok "fff-mcp"
  else
    warn "Homebrew not found; install fff-mcp before using the FFF MCP server"
  fi
}

# --- Stow packages ----------------------------------------------------------

# Use stow's dry-run to discover real-file conflicts in $HOME, then move them
# aside to <file>.bak so the actual stow can replace them with symlinks. This
# defers to stow's own ignore rules (.stow-local-ignore) instead of walking
# the package tree manually.
backup_conflicts() {
  local pkg="$1"
  shift
  local out

  out="$(stow -n -t "$HOME" --restow "$@" "$pkg" 2>&1 || true)"

  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    local tgt="$HOME/$rel"
    if [[ -e "$tgt" && ! -L "$tgt" && ! -d "$tgt" ]]; then
      info "backing up $tgt -> $tgt.bak"
      mv "$tgt" "$tgt.bak"
    fi
  done < <(
    sed -nE \
      -e 's/.*existing target (.+) since neither a link.*/\1/p' \
      -e 's/.*existing target is neither a link nor a directory: (.+)$/\1/p' \
      -e 's/.*existing target is not owned by stow: (.+)$/\1/p' \
      <<<"$out"
  )
}

stow_packages() (
  local pkg

  cd "$DOTFILES"

  for dir in */; do
    pkg="${dir%/}"

    # skip macOS-only packages on Linux
    if [[ "$OS" != "Darwin" && " $MACOS_ONLY " == *" $pkg "* ]]; then
      info "skipping $pkg (macOS only)"
      continue
    fi

    # skip arrakis-only packages everywhere else
    if [[ "$HOST_NAME" != "arrakis" && " $ARRAKIS_ONLY " == *" $pkg "* ]]; then
      info "skipping $pkg (arrakis only)"
      continue
    fi

    # skip packages this host opts out of (e.g. CARLYLE_EC2 disables aws)
    if [[ " $SKIP_PACKAGES " == *" $pkg "* ]]; then
      info "skipping $pkg (disabled on this host)"
      continue
    fi

    # Pin target to $HOME. Stow's default target is the parent of the stow
    # dir, which works when this repo is cloned at ~/dotfiles but not when
    # it's elsewhere.
    if [[ " $NO_FOLDING " == *" $pkg "* ]]; then
      # These packages sit beside mutable host state — agent harnesses under
      # ~/.claude, ~/.codex, ~/.cursor, and ~/.pi, the AWS CLI's SSO token
      # cache and credentials under ~/.aws, the timers.target.wants link
      # that systemctl --user enable writes beside git-auto-ff's units, and
      # other apps' agents in ~/Library/LaunchAgents. Link the tracked files
      # individually so stow never replaces the host-local directory with a
      # symlink.
      backup_conflicts "$pkg" --no-folding
      stow -t "$HOME" --restow --no-folding "$pkg"
    else
      backup_conflicts "$pkg"
      stow -t "$HOME" --restow "$pkg"
    fi
    ok "$pkg"
  done

)

# --- SSH host verification --------------------------------------------------

install_claude_ssh_host_keys() {
  local host_key
  local source="$DOTFILES/ssh/.ssh/known_hosts.private"
  local target="$HOME/.ssh/known_hosts"

  [[ "$OS" == "Darwin" ]] || return 0

  install -d -m 700 "$HOME/.ssh"
  touch "$target"
  chmod 600 "$target"

  # Claude Desktop's embedded SSH client resolves Host aliases but reads only
  # the default known_hosts file, so mirror any managed pins missing from it.
  while IFS= read -r host_key; do
    grep -Fxq "$host_key" "$target" || printf '%s\n' "$host_key" >>"$target"
  done <"$source"

  ok "Claude Desktop SSH host keys"
}

# Claude Code stores user-scoped MCP registrations in mutable host state rather
# than a standalone stowable file. Add the portable servers when they are
# missing and leave all other registrations alone. The Cloudflare and Aikido
# servers come from their plugins instead.
configure_claude_mcp() {
  if ! command -v claude &>/dev/null; then
    warn "claude not found; skipping MCP configuration"
    return
  fi

  # Earlier bootstraps registered Aikido at user scope; it would load beside
  # the plugin's server.
  if claude mcp get aikido &>/dev/null; then
    claude mcp remove --scope user aikido
    ok "removed the user-scope Aikido MCP in favor of its plugin"
  fi

  add_claude_mcp fff -- fff-mcp --no-update-check
  add_claude_mcp docs-index --transport http -- https://index.mintlify.com/mcp
  # The same installed proxy Codex, Pi, and Cursor run; settings.json denies the
  # aws-core plugin's copy. The profiles come from AWS_MCP_PROXY_PROFILES in the
  # settings env, which the Carlyle overlay replaces with that host's own.
  add_claude_mcp aws-mcp -- mcp-proxy-for-aws-cli https://aws-mcp.us-east-1.api.aws/mcp

  # The rest are Tractorbeam's service accounts, which the Carlyle devbox
  # has no business reaching.
  if [[ -n "${CARLYLE_EC2:-}" ]]; then
    return
  fi
  add_claude_mcp betterstack --transport http -- https://mcp.betterstack.com
  add_claude_mcp secureframe --transport http -- https://mcp.secureframe.com/
  add_claude_mcp workos --transport http -- https://mcp.workos.com/mcp
  add_claude_mcp okta -- codex-okta-mcp
  add_claude_mcp xapi -- npx -y @xdevplatform/xurl mcp https://api.x.com/mcp
}

# add_claude_mcp <name> [claude mcp add options] -- <command or url> [args]
add_claude_mcp() {
  local name="$1"
  shift
  if claude mcp get "$name" &>/dev/null; then
    ok "Claude Code $name MCP already configured"
  else
    claude mcp add --scope user "$name" "$@"
    ok "Claude Code $name MCP"
  fi
}

# Vendor plugins come straight from their vendors' marketplaces. aws-core,
# cloudflare, and workos are the ones Codex installs too; Aikido publishes no
# Codex plugin. The settings file already declares the marketplaces and the
# plugins; this makes the installed copies match it.
configure_claude_plugins() {
  if ! command -v claude &>/dev/null; then
    warn "claude not found; skipping vendor plugins"
    return
  fi

  info "updating Claude Code vendor plugins"
  claude plugin marketplace add aws/agent-toolkit-for-aws
  claude plugin marketplace add workos/skills
  claude plugin marketplace update agent-toolkit-for-aws
  claude plugin marketplace update workos
  claude plugin install aws-core@agent-toolkit-for-aws
  claude plugin install workos@workos
  claude plugin update aws-core@agent-toolkit-for-aws
  claude plugin update workos@workos
  # Cloudflare and Aikido are Tractorbeam's accounts; the Carlyle overlay
  # disables them.
  if [[ -z "${CARLYLE_EC2:-}" ]]; then
    claude plugin marketplace add cloudflare/skills
    claude plugin marketplace add AikidoSec/aikido-claude-plugin
    claude plugin marketplace update cloudflare
    claude plugin marketplace update aikido-plugins
    claude plugin install cloudflare@cloudflare
    claude plugin install aikido@aikido-plugins
    claude plugin update cloudflare@cloudflare
    claude plugin update aikido@aikido-plugins
  fi
  ok "Claude Code vendor plugins"
}

# Every harness's aws-mcp server launches this executable directly instead of
# resolving it through uvx on every start. Bump the pin deliberately; uv comes
# from the mise toolset, so this runs after `mise install`.
AWS_MCP_PROXY_VERSION=1.7.0
install_aws_mcp_proxy() {
  if ! command -v uv &>/dev/null; then
    warn "uv not found; install mcp-proxy-for-aws-cli before using the AWS MCP server"
    return
  fi
  # Captured first: grep -q closing the pipe early would fail it under pipefail.
  local installed
  installed="$(uv tool list --color never 2>/dev/null)"
  if grep -qxF "mcp-proxy-for-aws-cli v$AWS_MCP_PROXY_VERSION" <<<"$installed"; then
    ok "AWS MCP proxy $AWS_MCP_PROXY_VERSION already installed"
  else
    info "installing AWS MCP proxy $AWS_MCP_PROXY_VERSION"
    uv tool install --force "mcp-proxy-for-aws-cli==$AWS_MCP_PROXY_VERSION"
    ok "AWS MCP proxy"
  fi
}

# --- Codex configuration ----------------------------------------------------

install_codex_system_config() {
  local source="$DOTFILES/codex/system/config.toml"
  local target="/etc/codex/config.toml"

  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    ok "codex portable defaults already installed"
    return
  fi

  info "installing codex portable defaults"
  sudo install -d -m 0755 /etc/codex
  sudo install -m 0644 "$source" "$target"
  ok "codex portable defaults"
}

reconcile_codex_plugins() {
  local config="$HOME/.codex/config.toml"
  local plugin
  local plugins="$DOTFILES/codex/system/plugins.txt"

  if ! command -v codex &>/dev/null; then
    warn "codex not found; skipping plugin reconciliation"
    return
  fi

  [[ -r "$plugins" ]] || fail "codex plugin list is not readable: $plugins"

  info "updating codex plugin marketplaces"
  codex plugin marketplace add https://github.com/tractorbeamai/skills.git
  codex plugin marketplace add aws/agent-toolkit-for-aws
  codex plugin marketplace add cloudflare/skills
  codex plugin marketplace add workos/skills
  codex plugin marketplace upgrade tractorbeam
  codex plugin marketplace upgrade agent-toolkit-for-aws
  codex plugin marketplace upgrade cloudflare
  codex plugin marketplace upgrade workos

  if [[ -f "$config" ]]; then
    while IFS= read -r plugin; do
      if ! grep -Fxq "$plugin" "$plugins"; then
        codex plugin remove "$plugin"
      fi
    done < <(
      sed -nE 's/^\[plugins\."([^"]*@(tractorbeam|agent-toolkit-for-aws|cloudflare|workos))"\]$/\1/p' "$config"
    )
  fi

  while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    codex plugin add "$plugin"
  done <"$plugins"

  ok "codex plugins"
}

# --- Git hooks ---------------------------------------------------------------

setup_hooks() {
  git -C "$DOTFILES" config core.hooksPath .githooks
  ok "git hooks configured"
}

# A URL scheme handler has to be an app bundle, so build the thinnest possible
# one — it just forwards the URL to teams-link-open. duti points the msteams:
# scheme at it (see .config/duti/default-apps).
install_teams_link_handler() {
  [[ "$OS" == "Darwin" ]] || return 0

  local app="${HOME:?}/Applications/Teams Link Redirect.app"
  local plist="$app/Contents/Info.plist"

  info "building Teams link handler"
  mkdir -p "$HOME/Applications"

  # Rebuilt from scratch each run: PlistBuddy's Add fails on keys that already
  # exist, so the plist has to be the one osacompile just generated.
  rm -rf "$app"
  osacompile -o "$app" \
    -e 'on open location this_URL' \
    -e '  set helper to POSIX path of (path to home folder) & ".local/bin/teams-link-open"' \
    -e '  do shell script quoted form of helper & " " & quoted form of this_URL' \
    -e 'end open location'

  /usr/libexec/PlistBuddy \
    -c "Add :CFBundleIdentifier string com.wadefletcher.teams-link" \
    -c "Add :LSUIElement bool true" \
    -c "Add :CFBundleURLTypes array" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLName string Microsoft Teams" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string msteams" \
    "$plist" >/dev/null

  # Editing Info.plist invalidates osacompile's ad-hoc signature.
  codesign --force --sign - "$app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"

  # lsregister returns before the bundle is bindable, and duti reports success
  # either way — so without a settle the duti pass below leaves msteams: on
  # whatever handled it before, silently.
  sleep 2
  ok "Teams link handler"
}

# The office TV relay and its Cloudflare Tunnel run as LaunchAgents on arrakis
# only. Each reads its secret from the login Keychain when it starts, and an
# agent that exits is retried every 30s, so a missing item is a warning and
# the agents load anyway. The relay runs on Bun, so this follows `mise install`.
enable_office_tv_relay() {
  local label service

  [[ "$HOST_NAME" == "arrakis" ]] || return 0

  for service in office-tv-relay-secret office-tv-tunnel-token; do
    if ! security find-generic-password -a "$USER" -s "$service" &>/dev/null; then
      warn "Keychain item $service missing; add it with: security add-generic-password -a \"\$USER\" -s $service -U -w"
    fi
  done

  for label in com.wadefletcher.office-tv-relay com.wadefletcher.office-tv-tunnel; do
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$label.plist"
  done
  ok "office TV relay and tunnel"
}

# --- Main --------------------------------------------------------------------

main() {
  echo ""
  echo "  bootstrapping dotfiles ($OS)"
  echo ""

  if [[ "$OS" == "Darwin" ]] && ! command -v brew &>/dev/null; then
    fail "homebrew not found — install it first: https://brew.sh"
  fi

  install_deps
  install_codex_system_config
  stow_packages
  if [[ " $SKIP_PACKAGES " == *" aws "* ]]; then
    info "skipping AWS CLI config (aws disabled on this host)"
  else
    info "installing AWS CLI config"
    "$DOTFILES/aws/.local/bin/sync-aws-config"
    ok "AWS CLI config"
  fi
  # Claude Code has no user-scope settings.local.json, so the Carlyle overlay
  # is merged into a real ~/.claude/settings.json in place of the stowed
  # symlink, which would otherwise turn the merge into a git change.
  if [[ -n "${CARLYLE_EC2:-}" ]]; then
    info "applying Carlyle EC2 Claude Code overrides"
    local tmp
    tmp="$(mktemp "$HOME/.claude/settings.json.XXXXXX")"
    jq -s '.[0] * .[1]' "$DOTFILES/claude/.claude/settings.json" \
      "$DOTFILES/claude/.claude/settings.carlyle-ec2.json" >"$tmp" || {
      rm -f "$tmp"
      fail "merging Carlyle Claude Code settings (is jq installed?)"
    }
    chmod 644 "$tmp"
    mv -f "$tmp" "$HOME/.claude/settings.json"
    ok "Claude Code settings (Carlyle EC2)"
  fi
  configure_claude_mcp
  configure_claude_plugins
  install_claude_ssh_host_keys
  reconcile_codex_plugins
  setup_hooks

  # Install everything declared in the stowed mise config (node, python, …).
  # Must run after stow_packages so the symlinked config is in place.
  if command -v mise &>/dev/null; then
    info "installing mise tools"
    mise install
    ok "mise tools"
  fi

  install_aws_mcp_proxy

  info "installing Okta MCP server"
  "$DOTFILES/codex/.local/bin/install-okta-mcp-tool"
  ok "Okta MCP server"

  install_teams_link_handler
  enable_office_tv_relay

  if [[ "$OS" == "Darwin" ]] && command -v duti &>/dev/null; then
    info "applying default app associations"
    duti "$HOME/.config/duti/default-apps" 2>/dev/null || true
    ok "default app associations"
  fi

  echo ""
  echo "  done"
}

main
