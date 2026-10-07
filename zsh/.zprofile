source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# /etc/zprofile's path_helper reorders PATH after .zshenv. Re-apply brew so
# login shells keep Homebrew ahead of the system paths.
if [[ -x "${HOMEBREW_PREFIX:-}/bin/brew" ]]; then
  eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
fi

# Local macOS sessions load keychain keys into the agent .zshenv found.
if [[ "$OSTYPE" == darwin* && -z "${SSH_CONNECTION:-}" ]]; then
  ssh-add --apple-load-keychain 2>/dev/null
fi
