#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# Ensure curl-installed tools (starship, mise) are findable later in this
# script. .zshenv adds this for interactive shells, but we run as bash.
export PATH="$HOME/.local/bin:$PATH"

# macOS-only stow packages (contain Library/ paths or macOS-only tools)
MACOS_ONLY="cursor duti nightly-maintenance vscode wallpapers"

# CLI packages to install (must exist in brew + apt/dnf/yum/pacman)
PACKAGES=(git neovim stow zsh)

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
    for app in "${CASKS[@]}"; do
      if brew list --cask "$app" &>/dev/null; then
        ok "$app already installed"
      else
        info "installing $app"
        brew install --cask --adopt "$app"
        ok "$app"
      fi
    done

    # macOS-only brew formulae
    for formula in duti rtk; do
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

stow_packages() {
  cd "$DOTFILES"

  for dir in */; do
    pkg="${dir%/}"

    # skip macOS-only packages on Linux
    if [[ "$OS" != "Darwin" ]] && echo "$MACOS_ONLY" | grep -qw "$pkg"; then
      info "skipping $pkg (macOS only)"
      continue
    fi

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
