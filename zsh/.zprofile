source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# /etc/zprofile's path_helper reorders PATH after .zshenv. Re-apply brew so
# login shells keep Homebrew ahead of the system paths.
if [[ -x "${HOMEBREW_PREFIX:-}/bin/brew" ]]; then
  eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
fi

# macOS shells keep a forwarded agent when one arrived and otherwise use
# launchd's current agent, including in incoming SSH sessions, so git's SSH
# commit signing reaches the key without a TTY. Only local sessions load
# keychain keys into the agent.
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ ! -S "${SSH_AUTH_SOCK:-}" ]]; then
    SSH_AUTH_SOCK=$(
      launchctl print "gui/$UID/com.openssh.ssh-agent" 2>/dev/null |
        awk '$1 == "SSH_AUTH_SOCK" && $2 == "=>" { print $3; exit }'
    )
    export SSH_AUTH_SOCK
  fi

  if [[ -z "${SSH_CONNECTION:-}" ]]; then
    ssh-add --apple-load-keychain 2>/dev/null
  fi
fi
