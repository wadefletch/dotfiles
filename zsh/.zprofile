source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# macOS: load Keychain identities only for local login shells. Incoming SSH
# sessions use the source agent when the tailnet host permits forwarding.
if [[ "$OSTYPE" == darwin* && -z "${SSH_CONNECTION:-}" ]]; then
  ssh-add --apple-load-keychain --apple-use-keychain 2>/dev/null
fi
