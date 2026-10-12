source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# /etc/zprofile's path_helper reorders PATH after .zshenv. Re-apply brew so
# login shells keep Homebrew ahead of the system paths, then put mise's shims
# back in front so mise-managed tools win over Homebrew's, as in .zshenv.
if [[ -x "${HOMEBREW_PREFIX:-}/bin/brew" ]]; then
  eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
fi
_mise_shims="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
[[ -d "$_mise_shims" ]] && export PATH="$_mise_shims:$PATH"
unset _mise_shims

# Local macOS sessions load keychain keys into the agent .zshenv found.
if [[ "$OSTYPE" == darwin* && -z "${SSH_CONNECTION:-}" ]]; then
  ssh-add --apple-load-keychain 2>/dev/null
fi
