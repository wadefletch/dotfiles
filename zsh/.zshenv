# Homebrew - loaded here so it's available in non-interactive shells (e.g. SSH commands)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# PNPM (Node)
if [[ -d "$HOME/Library/pnpm" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi

# Cargo-installed Binaries (Rust)
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Postgres 17
if [[ -d "/opt/homebrew/opt/postgresql@17/bin" ]]; then
  export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
fi

# LLVM (probably Rust, tbh not sure why i have this)
if [[ -d "/opt/homebrew/opt/llvm/bin" ]]; then
  export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
fi

# Bun global binaries (bun link)
if [[ -d "$HOME/.bun/bin" ]]; then
  export PATH="$HOME/.bun/bin:$PATH"
fi

# Path addition required by factory.ai droid
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Force OSC 8 terminal hyperlinks in Ghostty. Claude Code (and other
# supports-hyperlinks-based CLIs) gate clickable links on TERM_PROGRAM, which
# Ghostty doesn't reliably set, so markdown/PR links render as dead plain text.
# Keyed off $TERM (reliably xterm-ghostty) rather than the missing TERM_PROGRAM.
# See anthropics/claude-code#70423.
if [[ "$TERM" == "xterm-ghostty" ]]; then
  export FORCE_HYPERLINK=1
fi

if [[ -r ~/.zshenv.local ]]; then
  # shellcheck disable=SC1090
  source ~/.zshenv.local
fi

# >>> mise shims (tractorbeam mise plugin) >>>
# Keep this block last in this file: the shims dir must land ahead of every
# other PATH prepend so repo-pinned tools shadow globals. Shims re-resolve
# the version pinned for the working directory at exec time, so every shell
# — interactive, agent tool, script, SSH command — gets pinned tools even
# when nothing else runs. Layers that do run (an interactive `mise activate
# zsh` in .zshrc, an agent env-file hook) prepend ahead of these and win.
# A literal prepend, not `eval "$(mise activate zsh --shims)"`: identical
# output, without forking mise at every shell spawn. Unconditional, because
# an inherited PATH may already carry the shims dir buried behind stale
# tool-version dirs — prepending moves it back in front.
_mise_shims="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
[ -d "$_mise_shims" ] && export PATH="$_mise_shims:$PATH"
unset _mise_shims
# <<< mise shims (tractorbeam mise plugin) <<<
