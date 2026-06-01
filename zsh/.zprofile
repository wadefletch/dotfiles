source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# macOS: load SSH keys from the login Keychain into the agent so signed
# commits and pushes never prompt for a passphrase.
if [[ "$OSTYPE" == darwin* ]]; then
  ssh-add --apple-load-keychain --apple-use-keychain 2>/dev/null
fi
