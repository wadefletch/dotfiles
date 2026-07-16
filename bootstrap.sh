#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# Ensure curl-installed tools (starship, mise) are findable later in this
# script. .zshenv adds this for interactive shells, but we run as bash.
export PATH="$HOME/.local/bin:$PATH"

# macOS-only stow packages (contain Library/ paths or macOS-only tools)
MACOS_ONLY="cursor duti nightly-maintenance sketchybar skhd-zig vscode wallpapers yabai"

# macOS-only Homebrew taps
MACOS_TAPS=(felixkratz/formulae koekeishiya/formulae)

# CLI packages to install (must exist in brew + apt/dnf/yum/pacman)
PACKAGES=(git neovim stow zsh)

# macOS apps and fonts (brew casks)
# font-sketchybar-app-font renders SketchyBar's per-app icons; font-symbols-only-nerd-font
# (family "Symbols Nerd Font") supplies the status glyphs (clock, wifi, battery, volume).
CASKS=(cursor ghostty font-sketchybar-app-font font-symbols-only-nerd-font)

info()  { printf '  [ .. ] %s\n' "$1"; }
ok()    { printf '  [ OK ] %s\n' "$1"; }
fail()  { printf '  [FAIL] %s\n' "$1" >&2; exit 1; }

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
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
          | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
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

# Codex desktop discovers Coder workspaces through concrete OpenSSH aliases.
# Feature detection keeps the CLI new enough to generate those aliases without
# pinning bootstrap to a release number.
install_coder() {
  if command -v coder &>/dev/null \
    && coder config-ssh --help 2>&1 | grep -q -- "--no-wildcard"; then
    ok "coder already installed"
    return
  fi

  info "installing coder"
  curl -fsSL https://coder.com/install.sh \
    | sh -s -- --mainline --method standalone --prefix "$HOME/.local"
  ok "coder"
}

install_rustup() {
  if [[ "$OS" == "Linux" ]]; then
    if command -v apt-get &>/dev/null; then
      apt_get install -y -qq build-essential libssl-dev pkg-config
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y gcc gcc-c++ make openssl-devel pkgconf-pkg-config
    elif command -v yum &>/dev/null; then
      sudo yum install -y gcc gcc-c++ make openssl-devel pkgconfig
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --needed --noconfirm base-devel openssl pkgconf
    fi
  fi

  if ! command -v rustup &>/dev/null; then
    info "installing rustup"
    case "$OS" in
      Darwin) brew install rustup ;;
      Linux)
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
          | sh -s -- -y --no-modify-path
        ;;
    esac
  fi

  export PATH="$HOME/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH"

  if ! rustup toolchain list | grep -q '^stable'; then
    rustup toolchain install stable
  fi
  rustup default stable
  ok "rustup stable toolchain"
}

# --- Install dependencies ----------------------------------------------------

install_deps() {
  info "updating package index"
  pkg_update
  ok "package index updated"

  for pkg in "${PACKAGES[@]}"; do
    # Map package name -> binary name where they differ (e.g. neovim -> nvim).
    case "$pkg" in
      neovim) bin="nvim" ;;
      *)      bin="$pkg" ;;
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
  install_rustup

  if [[ "$OS" == "Darwin" ]]; then
    install_coder
  fi

  # starship (curl installer — not reliably packaged across distros)
  if command -v starship &>/dev/null; then
    ok "starship already installed"
  else
    info "installing starship"
    # Install into a user-writable bin dir so the upstream installer skips
    # its `sudo -v` priming step. `sudo -v` requires a real password even
    # under NOPASSWD: ALL (validation has no target command for the rule
    # to match), and Coder's `coder` user has a locked account, so the
    # default install path hangs on an unanswerable prompt.
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
      Linux)  curl -fsSL https://mise.run | sh ;;
    esac
    ok "mise"
  fi

  # Switch login shell to zsh. Stowed config only loads if zsh is the
  # actual login shell, but apt/brew installing zsh doesn't change that.
  # On Coder workspaces `coder`'s password is locked, so chsh needs sudo.
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
    for tap in "${MACOS_TAPS[@]}"; do
      if brew tap | grep -qx "$tap"; then
        ok "$tap already tapped"
      else
        info "tapping $tap"
        brew tap "$tap"
        ok "$tap"
      fi
    done

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
    for formula in duti sketchybar skhd yabai; do
      if command -v "$formula" &>/dev/null; then
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
  local out

  out="$(stow -n -t "$HOME" --restow "$pkg" 2>&1 || true)"

  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    local tgt="$HOME/$rel"
    if [[ -e "$tgt" && ! -L "$tgt" && ! -d "$tgt" ]]; then
      info "backing up $tgt -> $tgt.bak"
      mv "$tgt" "$tgt.bak"
    fi
  done < <(sed -nE 's/.*existing target (.+) since neither a link.*/\1/p' <<<"$out")
}

stow_packages() {
  cd "$DOTFILES"

  for dir in */; do
    pkg="${dir%/}"

    # skip macOS-only packages on Linux
    if [[ "$OS" != "Darwin" ]] && echo "$MACOS_ONLY" | grep -qw "$pkg"; then
      info "skipping $pkg (macOS only)"
      continue
    fi

    backup_conflicts "$pkg"

    # Pin target to $HOME. Stow's default target is the parent of the stow
    # dir, which works when this repo is cloned at ~/dotfiles but not when
    # it's elsewhere — e.g. Coder's dotfiles module clones to
    # ~/.config/coderv2/dotfiles, which would dump symlinks into
    # ~/.config/coderv2/ instead of $HOME.
    stow -t "$HOME" --restow "$pkg"
    ok "$pkg"
  done
}

# --- Git hooks ---------------------------------------------------------------

setup_hooks() {
  cd "$DOTFILES"
  git config core.hooksPath .githooks
  ok "git hooks configured"
}

# --- Tailnet SSH -------------------------------------------------------------

# Authorize this machine's GitHub key for passwordless host-to-host SSH across
# the tailnet (corrino <-> arrakis). Both machines carry the same
# id_github_wadefletch keypair, so appending its pubkey to authorized_keys lets
# each accept the other. The keypair is intentionally not tracked in this repo,
# so on a fresh machine it may be absent — skip gracefully rather than fail.
setup_tailnet_ssh() {
  local pub="$HOME/.ssh/id_github_wadefletch.pub"
  local ak="$HOME/.ssh/authorized_keys"

  if [[ ! -f "$pub" ]]; then
    info "skipping tailnet ssh (no $pub)"
    return 0
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Append only if absent so repeated runs don't duplicate the entry. grep over
  # a missing authorized_keys returns non-zero, which correctly triggers the
  # first append.
  if ! grep -qF "$(cat "$pub")" "$ak" 2>/dev/null; then
    cat "$pub" >> "$ak"
    ok "tailnet ssh key authorized"
  else
    ok "tailnet ssh key already authorized"
  fi
  chmod 600 "$ak"

  # macOS needs Remote Login on to accept inbound SSH. Don't enable it here —
  # that needs sudo and an interactive prompt — just flag it if it's off.
  # Reading the status also needs admin: run non-root, systemsetup prints an
  # "administrator access" error to stderr and nothing to stdout, so match the
  # explicit "Remote Login: Off" on combined output rather than the absence of
  # "On" (which false-positives on the permission error).
  if [[ "$OS" == "Darwin" ]] && command -v systemsetup &>/dev/null; then
    if [[ "$(systemsetup -getremotelogin 2>&1)" == *"Remote Login: Off"* ]]; then
      info "remote login is off — enable with: sudo systemsetup -setremotelogin on"
    fi
  fi
}

# --- SketchyBar wifi helper ---------------------------------------------------

# macOS redacts the Wi-Fi SSID from every plain CLI unless the caller holds a
# Location Services grant, so the sketchybar wifi item reads it through a tiny
# CoreWLAN helper app that carries its own grant. Its first run pops a
# one-time Location permission prompt — approve it and the grant persists.
build_wifi_helper() {
  [[ "$OS" == "Darwin" ]] || return 0

  if ! command -v swiftc &>/dev/null; then
    info "skipping wifi-ssid helper (swiftc not found — install Xcode CLT)"
    return 0
  fi

  "$DOTFILES/sketchybar/.config/sketchybar/helpers/wifi-ssid/build.sh"
  ok "wifi-ssid helper"
}

# --- macOS defaults ----------------------------------------------------------

# Preferences that can't be stowed because they live in OS-managed plists.
# Idempotent: re-running just re-asserts the values.
setup_macos_defaults() {
  [[ "$OS" == "Darwin" ]] || return 0

  # Always show Sound in the menu bar so the sketchybar volume item can open its
  # Control Center popover (see sketchybar/.config/sketchybar/plugins/cc_click.sh).
  defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
  defaults write com.apple.controlcenter Sound -int 18
  killall ControlCenter 2>/dev/null || true
  ok "macOS defaults applied"
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
  stow_packages
  setup_hooks
  setup_tailnet_ssh
  build_wifi_helper
  setup_macos_defaults

  # Install everything declared in the stowed mise config (node, python, …).
  # Must run after stow_packages so the symlinked config is in place.
  if command -v mise &>/dev/null; then
    info "installing mise tools"
    mise install
    ok "mise tools"
  fi

  if [[ "$OS" == "Darwin" ]] && command -v duti &>/dev/null; then
    info "applying default app associations"
    duti "$HOME/.config/duti/default-apps" 2>/dev/null || true
    ok "default app associations"
  fi

  echo ""
  echo "  done"
}

main
