#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# Ensure curl-installed tools (starship, mise) are findable later in this
# script. .zshenv adds this for interactive shells, but we run as bash.
export PATH="$HOME/.local/bin:$PATH"

# macOS-only stow packages (contain Library/ paths or macOS-only tools)
MACOS_ONLY="cursor duti nightly-maintenance teams-link vscode wallpapers"

# CLI packages to install (must exist in brew + apt/dnf/yum/pacman)
PACKAGES=(git jq neovim ripgrep stow zsh eza)

# macOS apps and fonts (brew casks)
CASKS=(cursor ghostty font-symbols-only-nerd-font)

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
  local app bin formula installed_casks pkg zsh_path

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
      pkg_install "$pkg"
      ok "$pkg"
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

    # macOS-only brew formulae
    for formula in duti tailscale; do
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

    # Pin target to $HOME. Stow's default target is the parent of the stow
    # dir, which works when this repo is cloned at ~/dotfiles but not when
    # it's elsewhere.
    if [[ "$pkg" == "agent-config" || "$pkg" == "codex" || "$pkg" == "cursor" ]]; then
      # Agent harnesses own mutable state alongside the managed files. Link
      # individual files without ever replacing those host-local directories.
      backup_conflicts "$pkg" --no-folding
      stow -t "$HOME" --restow --no-folding "$pkg"
    else
      backup_conflicts "$pkg"
      stow -t "$HOME" --restow "$pkg"
    fi
    ok "$pkg"
  done

)

# --- Agent harness configuration -------------------------------------------

# Harnesses write caches, account metadata, and UI preferences into their user
# settings files. Keep those files host-local and merge portable policy into
# them instead of symlinking the live files into this repository.
merge_json_policy() {
  local policy="$1"
  local target="$2"
  local merged

  [[ -r "$policy" ]] || fail "agent policy is not readable: $policy"
  jq -e 'type == "object"' "$policy" >/dev/null ||
    fail "agent policy must be a JSON object: $policy"

  install -d -m 0700 "$(dirname "$target")"
  merged="$(mktemp "${TMPDIR:-/tmp}/agent-settings.XXXXXX")"

  if [[ -r "$target" ]] && jq -e 'type == "object"' "$target" >/dev/null 2>&1; then
    jq -s '.[0] + .[1]' "$target" "$policy" >"$merged"
  else
    jq '.' "$policy" >"$merged"
  fi

  [[ -L "$target" ]] && rm "$target"
  install -m 0600 "$merged" "$target"
  rm -f "$merged"
}

reconcile_agent_settings() {
  local policies="$DOTFILES/agent-config/.config/agent-harnesses"
  local plugins="$policies/plugins.json"
  local claude_settings="$HOME/.claude/settings.json"
  local merged

  info "reconciling agent settings"
  merge_json_policy "$policies/claude-settings.json" "$claude_settings"

  # Plugin enablement is generated from the shared manifest. Replacing the
  # object also removes stale disabled entries for retired plugins.
  merged="$(mktemp "${TMPDIR:-/tmp}/claude-settings.XXXXXX")"
  jq --slurpfile manifest "$plugins" '
    del(.sshConfigs)
    | .enabledPlugins = (
        $manifest[0].plugins
        | map(select(.harnesses | index("claude")))
        | map({key: (.name + "@" + .marketplace), value: true})
        | from_entries
      )
  ' "$claude_settings" >"$merged"
  install -m 0600 "$merged" "$claude_settings"
  rm -f "$merged"

  # This was previously stowed even though Claude only supports local settings
  # at project scope. Remove the old managed link without touching an unmanaged
  # host file.
  if [[ -L "$HOME/.claude/settings.local.json" ]]; then
    rm "$HOME/.claude/settings.local.json"
  elif [[ -e "$HOME/.claude/settings.local.json" ]]; then
    warn "leaving unmanaged ~/.claude/settings.local.json in place"
  fi

  ok "agent settings"
}

# --- SSH host verification --------------------------------------------------

install_claude_ssh_host_keys() {
  local host_key
  local source="$DOTFILES/ssh/.ssh/known_hosts.private"
  local target="$HOME/.ssh/known_hosts"

  [[ "$OS" == "Darwin" ]] || return

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
  local plugins="$DOTFILES/agent-config/.config/agent-harnesses/plugins.json"

  if ! command -v codex &>/dev/null; then
    warn "codex not found; skipping plugin reconciliation"
    return
  fi

  [[ -r "$plugins" ]] || fail "agent plugin manifest is not readable: $plugins"

  info "updating codex plugin marketplaces"
  codex plugin marketplace add https://github.com/tractorbeamai/skills.git
  codex plugin marketplace add aws/agent-toolkit-for-aws
  codex plugin marketplace upgrade tractorbeam
  codex plugin marketplace upgrade agent-toolkit-for-aws

  if [[ -f "$config" ]]; then
    while IFS= read -r plugin; do
      if ! jq -e --arg plugin "$plugin" '
        any(.plugins[];
          (.harnesses | index("codex")) and
          ((.name + "@" + .marketplace) == $plugin)
        )
      ' "$plugins" >/dev/null; then
        codex plugin remove "$plugin"
      fi
    done < <(
      sed -nE 's/^\[plugins\."([^"]*@(tractorbeam|agent-toolkit-for-aws))"\]$/\1/p' "$config"
    )
  fi

  while IFS= read -r plugin; do
    codex plugin add "$plugin"
  done < <(
    jq -r '.plugins[]
      | select(.harnesses | index("codex"))
      | .name + "@" + .marketplace' "$plugins"
  )

  ok "codex plugins"
}

reconcile_claude_plugins() {
  local installed
  local marketplace
  local marketplaces
  local plugin
  local plugins="$DOTFILES/agent-config/.config/agent-harnesses/plugins.json"

  if ! command -v claude &>/dev/null; then
    warn "claude not found; skipping plugin reconciliation"
    return
  fi

  info "reconciling Claude plugins"
  marketplaces="$(claude plugin marketplace list --json)"

  while IFS=$'\t' read -r marketplace source; do
    if ! jq -e --arg marketplace "$marketplace" \
      'any(.[]; .name == $marketplace)' <<<"$marketplaces" >/dev/null; then
      claude plugin marketplace add "$source"
    fi
    claude plugin marketplace update "$marketplace"
  done < <(
    jq -r '. as $manifest
      | [.plugins[] | select(.harnesses | index("claude")) | .marketplace]
      | unique[] as $marketplace
      | select($marketplace != "claude-plugins-official")
      | [$marketplace, $manifest.marketplaces[$marketplace]]
      | @tsv
    ' "$plugins"
  )

  installed="$(claude plugin list --json)"

  # Remove user-scoped plugins from managed marketplaces when they are no
  # longer present in the desired-state manifest. Project installs are owned by
  # their repositories and are deliberately left alone.
  while IFS= read -r plugin; do
    if ! jq -e --arg plugin "$plugin" '
      any(.plugins[];
        (.harnesses | index("claude")) and
        ((.name + "@" + .marketplace) == $plugin)
      )
    ' "$plugins" >/dev/null; then
      claude plugin uninstall "$plugin" --scope user
    fi
  done < <(
    jq -r --slurpfile manifest "$plugins" '
      [$manifest[0].marketplaces | keys[]] as $managed
      | .[]
      | select(.scope == "user")
      | select((.id | split("@")[-1]) as $marketplace
        | $managed | index($marketplace))
      | .id
    ' <<<"$installed"
  )

  while IFS= read -r plugin; do
    if ! jq -e --arg plugin "$plugin" \
      'any(.[]; .scope == "user" and .id == $plugin)' \
      <<<"$installed" >/dev/null; then
      claude plugin install --scope user --yes "$plugin"
    fi
  done < <(
    jq -r '.plugins[]
      | select(.harnesses | index("claude"))
      | .name + "@" + .marketplace' "$plugins"
  )

  ok "Claude plugins"
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

# --- Main --------------------------------------------------------------------

main() {
  echo ""
  echo "  bootstrapping dotfiles ($OS)"
  echo ""

  if [[ "$OS" == "Darwin" ]] && ! command -v brew &>/dev/null; then
    fail "homebrew not found — install it first: https://brew.sh"
  fi

  install_deps
  "$DOTFILES/check-agent-config.sh"
  install_codex_system_config
  stow_packages
  reconcile_agent_settings
  install_claude_ssh_host_keys
  reconcile_codex_plugins
  reconcile_claude_plugins
  setup_hooks

  # Install everything declared in the stowed mise config (node, python, …).
  # Must run after stow_packages so the symlinked config is in place.
  if command -v mise &>/dev/null; then
    info "installing mise tools"
    mise install
    ok "mise tools"
  fi

  if [[ "$OS" == "Darwin" ]]; then
    info "installing Okta MCP server"
    "$DOTFILES/codex/.local/bin/install-okta-mcp-tool"
    ok "Okta MCP server"
  else
    info "skipping Keychain-backed Okta MCP server (macOS only)"
  fi

  install_teams_link_handler

  if [[ "$OS" == "Darwin" ]] && command -v duti &>/dev/null; then
    info "applying default app associations"
    duti "$HOME/.config/duti/default-apps" 2>/dev/null || true
    ok "default app associations"
  fi

  echo ""
  echo "  done"
}

main
