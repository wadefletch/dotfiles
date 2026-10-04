# Homebrew - loaded here so it's available in non-interactive shells (e.g. SSH commands)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# PNPM (Node). pnpm 11 stores global binaries in $PNPM_HOME/bin; keep the
# legacy root on PATH until every pre-v11 global launcher has been refreshed.
if [[ -d "$HOME/Library/pnpm" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
elif [[ -d "$HOME/.local/share/pnpm" ]]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
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

# User-installed command-line tools
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

# Over SSH, open browsers on the Mac you are using rather than on this one,
# where nobody is at the screen. Claude Code's fullscreen UI and CLIs such as
# `aws sso login` launch $BROWSER on their own host; open-url sends the URL to
# whichever Mac has had recent input.
if [[ -n "$SSH_CONNECTION" ]]; then
  export BROWSER=open-url
fi

# macOS shells keep a forwarded agent when one arrived and otherwise use
# launchd's current agent, including in incoming SSH sessions, so git's SSH
# commit signing reaches the key without a TTY. This lives here rather than in
# .zprofile because non-login shells need it too: processes launchd starts
# without SSH_AUTH_SOCK (the Claude Code daemon, for one) spawn `zsh -c`
# shells that never read .zprofile.
if [[ "$OSTYPE" == darwin* && ! -S "${SSH_AUTH_SOCK:-}" ]]; then
  SSH_AUTH_SOCK=$(
    launchctl print "gui/$UID/com.openssh.ssh-agent" 2>/dev/null |
      awk '$1 == "SSH_AUTH_SOCK" && $2 == "=>" { print $3; exit }'
  )
  export SSH_AUTH_SOCK
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

# Vite+ bin
if [[ -f "$HOME/.vite-plus/env" ]]; then
  source "$HOME/.vite-plus/env"
fi
