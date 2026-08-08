source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# macOS: use the launchd-managed agent for local login shells. Long-running
# applications can preserve an SSH_AUTH_SOCK after its temporary agent exits,
# so recover the active launchd socket before loading Keychain identities.
# Incoming SSH sessions keep the forwarded source agent.
if [[ "$OSTYPE" == darwin* && -z "${SSH_CONNECTION:-}" ]]; then
  if [[ ! -S "${SSH_AUTH_SOCK:-}" ]]; then
    tb_ssh_auth_sock=$(
      launchctl print "gui/$(id -u)/com.openssh.ssh-agent" 2>/dev/null |
        awk '/SSH_AUTH_SOCK =>/ { print $3; exit }'
    )
    if [[ -S "$tb_ssh_auth_sock" ]]; then
      export SSH_AUTH_SOCK="$tb_ssh_auth_sock"
    fi
    unset tb_ssh_auth_sock
  fi
  ssh-add --apple-load-keychain 2>/dev/null
fi
