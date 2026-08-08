source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Local macOS shells use launchd's current agent; incoming SSH sessions keep
# their forwarded agent.
if [[ "$OSTYPE" == darwin* && -z "${SSH_CONNECTION:-}" ]]; then
  if [[ ! -S "${SSH_AUTH_SOCK:-}" ]]; then
    SSH_AUTH_SOCK=$(
      launchctl print "gui/$UID/com.openssh.ssh-agent" 2>/dev/null |
        awk '$1 == "SSH_AUTH_SOCK" && $2 == "=>" { print $3; exit }'
    )
    export SSH_AUTH_SOCK
  fi

  ssh-add --apple-load-keychain 2>/dev/null
fi
