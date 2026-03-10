#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# macOS-only stow packages (contain Library/ paths)
MACOS_ONLY="cursor nightly-maintenance vscode"

# CLI packages to install (must exist in brew + apt/dnf/yum/pacman)
PACKAGES=(git neovim tmux stow)

# macOS GUI apps (brew casks)
CASKS=(cursor ghostty docker)

info()  { printf '  [ .. ] %s\n' "$1"; }
ok()    { printf '  [ OK ] %s\n' "$1"; }
fail()  { printf '  [FAIL] %s\n' "$1" >&2; exit 1; }

# --- Package manager helpers -------------------------------------------------

pkg_install() {
  case "$OS" in
    Darwin) brew install "$@" ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq "$@"
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
        sudo apt-get update -qq
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
        sudo apt-get update -qq
        sudo apt-get install -y -qq gh
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
  info "updating package index"
  pkg_update
  ok "package index updated"

  for pkg in "${PACKAGES[@]}"; do
    if command -v "$pkg" &>/dev/null; then
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
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "starship"
  fi

  # macOS GUI apps
  if [[ "$OS" == "Darwin" ]]; then
    for app in "${CASKS[@]}"; do
      if brew list --cask "$app" &>/dev/null; then
        ok "$app already installed"
      else
        info "installing $app"
        brew install --cask "$app"
        ok "$app"
      fi
    done

    # macOS-only brew formulae
    if command -v rtk &>/dev/null; then
      ok "rtk already installed"
    else
      info "installing rtk"
      brew install rtk
      ok "rtk"
    fi
  fi
}

# --- Stow packages ----------------------------------------------------------

stow_packages() {
  cd "$DOTFILES"

  for dir in */; do
    pkg="${dir%/}"

    # skip macOS-only packages on Linux
    if [[ "$OS" != "Darwin" ]] && echo "$MACOS_ONLY" | grep -qw "$pkg"; then
      info "skipping $pkg (macOS only)"
      continue
    fi

    stow --restow "$pkg"
    ok "$pkg"
  done
}

# --- Git hooks ---------------------------------------------------------------

setup_hooks() {
  cd "$DOTFILES"
  git config core.hooksPath .githooks
  ok "git hooks configured"
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

  echo ""
  echo "  done"
}

main
