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

# arrakis and corrino reach each other with SSH and mosh over Cloudflare Mesh.
MESH_HOST=""
[[ "$HOST_NAME" == "arrakis" || "$HOST_NAME" == "corrino" ]] && MESH_HOST=1

# Packages this host opts out of, driven by env. The Carlyle EC2 devbox manages
# its own host-local ~/.aws/config and aws-login, so CARLYLE_EC2=1 skips the aws
# package (and its config sync) to leave that host-local setup untouched.
SKIP_PACKAGES=""
[[ -n "${CARLYLE_EC2:-}" ]] && SKIP_PACKAGES+=" aws"
# The ssh package serves only the Mesh Macs, and its authorized_keys admits
# only personal keys, so stowing it anywhere else (the Carlyle EC2 devbox)
# would replace that host's own keys.
[[ -n "$MESH_HOST" ]] || SKIP_PACKAGES+=" ssh"

# Stow packages whose target directory also holds host-local state, so the
# tracked files must be linked individually rather than by folding the
# directory itself into a symlink.
NO_FOLDING="agent-config aws claude codex cursor gh git-auto-ff office-tv-relay pi"

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
  local app bin formula formulae installed_casks pkg zsh_path index_updated=""

  for pkg in "${PACKAGES[@]}"; do
    # Map package name -> binary name where they differ (e.g. neovim -> nvim).
    case "$pkg" in
    neovim) bin="nvim" ;;
    *) bin="$pkg" ;;
    esac
    if command -v "$bin" &>/dev/null; then
      ok "$pkg already installed"
    else
      # Refresh the index only when something needs installing, so a run on a
      # provisioned machine never needs sudo here.
      if [[ -z "$index_updated" ]]; then
        info "updating package index"
        pkg_update
        ok "package index updated"
        index_updated=1
      fi
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
  # Every OS uses the upstream installer, which lands at ~/.local/bin/mise, so
  # macOS and Linux run the same release and `mise self-update` keeps it
  # current (here, and nightly on macOS).
  if [[ -x "$HOME/.local/bin/mise" ]]; then
    info "updating mise"
    if "$HOME/.local/bin/mise" self-update --yes; then
      ok "mise"
    else
      warn "mise self-update failed; keeping $("$HOME/.local/bin/mise" --version)"
    fi
  else
    info "installing mise"
    curl -fsSL https://mise.run | sh
    ok "mise"
  fi
  hash -r
  # Regenerate shims now so they point at this mise even when `mise install`
  # below has nothing to install and so never rewrites them.
  if ! "$HOME/.local/bin/mise" reshim >/dev/null 2>&1; then
    warn "mise reshim failed"
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
    formulae=(duti mosh)
    [[ "$HOST_NAME" == "arrakis" ]] && formulae+=(cloudflared)
    for formula in "${formulae[@]}"; do
      if command -v "$formula" &>/dev/null; then
        ok "$formula already installed"
      else
        info "installing $formula"
        brew install "$formula"
        ok "$formula"
      fi
    done

    # arrakis and corrino accept SSH and mosh over Cloudflare Mesh only.
    if [[ -n "$MESH_HOST" ]]; then
      info "configuring Mesh-only sshd (sudo)"
      sudo "$DOTFILES/ssh/.local/bin/setup-mesh-sshd"
      ok "Mesh-only sshd"
    fi
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
      # earlier bootstraps stowed ssh on every host; remove those links
      [[ "$pkg" == "ssh" ]] && stow -t "$HOME" -D "$pkg"
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

# --- Machine-local entry points ----------------------------------------------

# Installers append to the shell and git entry points in $HOME: Aikido's
# endpoint agent adds CA blocks to ~/.zshrc and ~/.zprofile (restoring them if
# they go missing) and sets http.sslCAInfo with `git config --global`, and the
# tractorbeam mise plugin adds its shims block to ~/.zshenv and ~/.zprofile.
# Those files stay machine-local so the appends never land in the repo: each
# zsh file sources its tracked counterpart from ~/.config/zsh first, and
# ~/.gitconfig exists so git writes global settings there instead of the
# stowed XDG config. The pre-commit hook rejects installer blocks staged in
# tracked config.
install_local_entrypoints() {
  local content entry header name script source_line target
  local -a scripts
  # name|first line of a new file|line that loads the tracked config (if any)
  # shellcheck disable=SC2016 # $HOME expands when zsh reads the line
  local -a entries=(
    'zshenv|# Machine-local; installers may append below.|source "$HOME/.config/zsh/zshenv"'
    'zprofile|# Machine-local; installers may append below.|source "$HOME/.config/zsh/zprofile"'
    'zshrc|# Machine-local; installers may append below.|source "$HOME/.config/zsh/zshrc"'
    'gitconfig|# Machine-local git config; `git config --global` writes here.|'
  )

  for entry in "${entries[@]}"; do
    IFS='|' read -r name header source_line <<<"$entry"
    target="$HOME/.$name"
    # Writing through a broken link would create its target, possibly in the repo.
    if [[ -L "$target" && ! -e "$target" ]]; then
      rm "$target"
    fi
    if [[ ! -e "$target" ]]; then
      printf '%s\n' "$header" ${source_line:+"$source_line"} >"$target"
      ok ".$name created"
    elif [[ -z "$source_line" ]] || grep -qxF "$source_line" "$target"; then
      ok ".$name is machine-local"
    else
      content="$(<"$target")"
      printf '%s\n%s\n' "$source_line" "$content" >"$target"
      ok ".$name now loads the tracked config"
    fi
  done

  # The tractorbeam mise plugin's setup script appends its shims block to
  # ~/.zshenv and ~/.zprofile where missing; it must run after the source
  # lines above so the shims stay first on PATH. The plugin is installed later
  # in a first bootstrap, so a new machine gets the blocks on the next run.
  scripts=("$HOME"/.claude/plugins/cache/tractorbeam/mise/*/scripts/setup-shell.sh)
  script="$(printf '%s\n' "${scripts[@]}" | sort -V | tail -n 1)"
  if [[ -f "$script" ]]; then
    if ZDOTDIR="$HOME" sh "$script" >/dev/null; then
      ok "mise shims blocks"
    else
      warn "mise plugin setup-shell.sh failed; re-run $script"
    fi
  fi
}

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
# missing and leave all other registrations alone. The Cloudflare server comes
# from its plugin instead, and Context7 and WorkOS from claude.ai connectors.
# Okta and Tractorbeam's AWS MCP are scoped to the infra repository, and
# Secureframe to infra and the handbook, whose .mcp.json files define them, so
# they stay out of every other project's context.
configure_claude_mcp() {
  if ! command -v claude &>/dev/null; then
    warn "claude not found; skipping MCP configuration"
    return
  fi

  add_claude_mcp fff -- fff-mcp --no-update-check

  # The Carlyle devbox has no infra checkout, so its AWS MCP is registered
  # here, pinned to the host's profiles by the Carlyle overlay's settings env;
  # settings.json denies the aws-core plugin's copy. Tractorbeam's service
  # accounts stay off that host.
  if [[ -n "${CARLYLE_EC2:-}" ]]; then
    add_claude_mcp aws-mcp -- mcp-proxy-for-aws-cli https://aws-mcp.us-east-1.api.aws/mcp
    return
  fi
  add_claude_mcp betterstack --transport http -- https://mcp.betterstack.com
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

# aws-core, cloudflare, and workos come straight from their vendors' marketplaces, the
# sources Codex uses, so both harnesses run the same plugins. The settings
# file already declares the marketplaces and the plugins; this makes the
# installed copies match it.
configure_claude_plugins() {
  if ! command -v claude &>/dev/null; then
    warn "claude not found; skipping vendor plugins"
    return
  fi

  info "updating Claude Code vendor plugins"
  claude plugin marketplace add aws/agent-toolkit-for-aws
  claude plugin marketplace update agent-toolkit-for-aws
  claude plugin install aws-core@agent-toolkit-for-aws
  claude plugin update aws-core@agent-toolkit-for-aws
  # Cloudflare and WorkOS are Tractorbeam's accounts; the Carlyle overlay
  # disables both.
  if [[ -z "${CARLYLE_EC2:-}" ]]; then
    claude plugin marketplace add cloudflare/skills
    claude plugin marketplace add workos/skills
    claude plugin marketplace update cloudflare
    claude plugin marketplace update workos
    claude plugin install cloudflare@cloudflare
    claude plugin install workos@workos
    claude plugin update cloudflare@cloudflare
    claude plugin update workos@workos
  fi
  ok "Claude Code vendor plugins"
}

# Agent Skills from their upstream repos, installed with the open `skills`
# installer: it keeps the skill in ~/.agents/skills (which Codex and Pi read),
# links it into ~/.claude/skills, and records the source in
# ~/.agents/.skill-lock.json. Codex and Cursor also get context7-mcp from
# Context7's plugins. Bump the installer pin deliberately, and only to a
# release at least a week old: Aikido's npm protection on some machines hides
# newer versions. Node comes from the mise toolset, so this runs after
# `mise install`.
SKILLS_INSTALLER_VERSION=1.7.0
install_agent_skills() {
  if ! command -v npx &>/dev/null; then
    warn "npx not found; skipping agent skills"
    return
  fi

  if npx -y "skills@$SKILLS_INSTALLER_VERSION" add upstash/context7 --skill context7-mcp \
    --global --agent claude-code pi --yes >/dev/null 2>&1; then
    ok "context7-mcp skill"
  else
    warn "context7-mcp skill install failed"
  fi
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

# Codex reads host-wide defaults only from this fixed path and doesn't check
# its owner on Unix, so a link into the checkout picks up every pull. Only the
# first run on a machine needs sudo.
install_codex_system_config() {
  local source="$DOTFILES/codex/system/config.toml"
  local target="/etc/codex/config.toml"

  if [[ "$(readlink "$target" 2>/dev/null)" == "$source" ]]; then
    ok "codex portable defaults already linked"
    return
  fi

  info "linking codex portable defaults (sudo, once per machine)"
  sudo install -d -m 0755 /etc/codex
  sudo ln -sfn "$source" "$target"
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
  codex plugin marketplace add upstash/context7
  codex plugin marketplace upgrade tractorbeam
  codex plugin marketplace upgrade agent-toolkit-for-aws
  codex plugin marketplace upgrade cloudflare
  codex plugin marketplace upgrade workos
  codex plugin marketplace upgrade context7-marketplace

  if [[ -f "$config" ]]; then
    while IFS= read -r plugin; do
      if ! grep -Fxq "$plugin" "$plugins"; then
        codex plugin remove "$plugin"
      fi
    done < <(
      sed -nE 's/^\[plugins\."([^"]*@(tractorbeam|agent-toolkit-for-aws|cloudflare|workos|context7-marketplace))"\]$/\1/p' "$config"
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

# (Re)load a stowed LaunchAgent so launchd picks up its current plist. Setting
# DOTFILES_SKIP_SERVICES=1 skips it, for test runs against a throwaway $HOME.
reload_launch_agent() {
  local label="$1"
  local domain attempt

  if [[ -n "${DOTFILES_SKIP_SERVICES:-}" ]]; then
    info "skipping $label reload (DOTFILES_SKIP_SERVICES)"
    return 0
  fi

  domain="gui/$(id -u)"
  launchctl bootout "$domain/$label" 2>/dev/null || true
  # bootout returns before launchd finishes removing the service, and a
  # bootstrap in that window fails with "5: Input/output error". Wait out
  # launchd's default 20s exit timeout.
  for attempt in {1..200}; do
    launchctl print "$domain/$label" &>/dev/null || break
    sleep 0.1
  done
  launchctl bootstrap "$domain" "$HOME/Library/LaunchAgents/$label.plist"
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
    reload_launch_agent "$label"
  done
  ok "office TV relay and tunnel"
}

# nightly-maintenance runs on every Mac; launchd loads it from the stowed plist
# at login, and this reloads it so a changed plist takes effect now.
reload_nightly_maintenance() {
  [[ "$OS" == "Darwin" ]] || return 0
  reload_launch_agent com.wadefletcher.nightly-maintenance
  ok "nightly maintenance agent"
}

# git-auto-ff is opt-in per host (./enable-git-auto-ff.sh), so reload it only
# where it is already running.
reload_git_auto_ff() {
  local label=com.wadefletcher.git-auto-ff

  [[ -z "${DOTFILES_SKIP_SERVICES:-}" ]] || return 0

  if [[ "$OS" == "Darwin" ]]; then
    launchctl print "gui/$(id -u)/$label" &>/dev/null || return 0
    reload_launch_agent "$label"
  else
    systemctl --user is-enabled git-auto-ff.timer &>/dev/null || return 0
    systemctl --user daemon-reload
  fi
  ok "git-auto-ff"
}

apply_default_apps() {
  if [[ "$OS" != "Darwin" ]] || ! command -v duti &>/dev/null; then
    return 0
  fi
  if [[ -n "${DOTFILES_SKIP_SERVICES:-}" ]]; then
    info "skipping default app associations (DOTFILES_SKIP_SERVICES)"
    return 0
  fi
  info "applying default app associations"
  duti "$HOME/.config/duti/default-apps" 2>/dev/null || true
  ok "default app associations"
}

sync_aws_config() {
  if [[ " $SKIP_PACKAGES " == *" aws "* ]]; then
    info "skipping AWS CLI config (aws disabled on this host)"
    return 0
  fi
  info "installing AWS CLI config"
  "$DOTFILES/aws/.local/bin/sync-aws-config"
  ok "AWS CLI config"
}

# Claude Code has no user-scope settings.local.json, so the Carlyle overlay is
# merged into a real ~/.claude/settings.json in place of the stowed symlink,
# which would otherwise turn the merge into a git change. Restowing replaces
# the merged file with the link again, so this runs after every stow.
apply_carlyle_claude_settings() {
  local tmp

  [[ -n "${CARLYLE_EC2:-}" ]] || return 0

  info "applying Carlyle EC2 Claude Code overrides"
  tmp="$(mktemp "$HOME/.claude/settings.json.XXXXXX")"
  jq -s '.[0] * .[1]' "$DOTFILES/claude/.claude/settings.json" \
    "$DOTFILES/claude/.claude/settings.carlyle-ec2.json" >"$tmp" || {
    rm -f "$tmp"
    fail "merging Carlyle Claude Code settings (is jq installed?)"
  }
  chmod 644 "$tmp"
  mv -f "$tmp" "$HOME/.claude/settings.json"
  ok "Claude Code settings (Carlyle EC2)"
}

# Remove symlinks in $HOME that point into this checkout but no longer resolve,
# left behind when a tracked file is deleted or moved. Stow writes relative
# targets (../../.dotfiles/...), so match on the checkout's directory name.
remove_dangling_links() {
  local link removed=0
  local name
  name="$(basename "$DOTFILES")"

  while IFS= read -r -d '' link; do
    rm "$link"
    info "removed dangling link $link"
    removed=$((removed + 1))
  done < <(
    find "$HOME" -maxdepth 5 -path "$DOTFILES" -prune -o \
      -type l -lname "*$name/*" ! -exec test -e {} \; -print0 2>/dev/null || true
  )
  ok "dangling links ($removed removed)"
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
  install_local_entrypoints
  sync_aws_config
  apply_carlyle_claude_settings
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

  install_agent_skills
  install_aws_mcp_proxy

  install_teams_link_handler
  enable_office_tv_relay
  apply_default_apps

  echo ""
  echo "  done"
}

# Apply a pulled checkout to this machine: relink every package, refresh the
# files assembled from tracked sources, and reload the background agents whose
# plists are stowed here. Installs nothing and never needs sudo.
deploy() {
  echo ""
  echo "  deploying dotfiles ($OS)"
  echo ""

  command -v stow &>/dev/null || fail "stow not found — run ./bootstrap.sh first"

  stow_packages
  install_local_entrypoints
  sync_aws_config
  apply_carlyle_claude_settings
  install_claude_ssh_host_keys
  remove_dangling_links
  reload_nightly_maintenance
  enable_office_tv_relay
  reload_git_auto_ff
  apply_default_apps

  echo ""
  echo "  done"
}

case "${1:-}" in
"") main ;;
deploy) deploy ;;
*) fail "usage: $0 [deploy]" ;;
esac
