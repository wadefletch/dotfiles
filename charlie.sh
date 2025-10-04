# install homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# update homebrew
echo "Updating Homebrew Recipes..."
brew update

# install xcode command line tools
echo "Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || echo "Xcode Command Line Tools already installed"

# accept xcode license
echo "Accepting Xcode license..."
sudo xcodebuild -license accept 2>/dev/null || echo "Xcode license already accepted"

# install a bunch of brew formulae and casks
echo "Installing applications via Homebrew..."
brew install --cask cursor ghostty google-chrome spotify docker granola
brew install git gh starship font-jetbrains-mono-nerd-font uv

# making finder show hidden files
echo "Making Finder show hidden files..."
defaults write com.apple.finder AppleShowAllFiles TRUE
killall Finder

# increase file descriptor limits for development
echo "Increasing file descriptor limits..."
sudo launchctl limit maxfiles 65536 200000

# configure git
echo "Configuring Git..."
mkdir -p ~/.config/git
cat <<EOF > ~/.config/git/config
[user]
name = Charlie Brizz
email = cbrizz00@gmail.com

[core]
editor = cursor --wait
autocrlf = input

[init]
defaultBranch = main

[pull]
rebase = false

[push]
default = current
autoSetupRemote = true
EOF

# configure zsh
echo "Configuring Zsh..."
cat <<EOF > ~/.zshrc
# History
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # save timestamp
setopt HIST_EXPIRE_DUPS_FIRST    # expire duplicates first
setopt HIST_IGNORE_DUPS          # ignore duplicated commands
setopt HIST_IGNORE_SPACE         # ignore commands starting with space
setopt HIST_VERIFY               # show command before executing from history

# Keybinds
bindkey -e  # Use emacs key bindings (readline compatible)

# History search with up/down arrows
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Standard readline word movement (Alt+f/b)
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Alt+arrow for word movement (multiple terminal escape sequences)
bindkey "^[[1;3C" forward-word     # Alt+Right
bindkey "^[[1;3D" backward-word    # Alt+Left
bindkey "^[^[[C" forward-word      # Alt+Right (older terminals)
bindkey "^[^[[D" backward-word     # Alt+Left (older terminals)

# Additional readline-compatible bindings
bindkey "^[d" kill-word            # Alt+d (delete word forward)
bindkey "^[^?" backward-kill-word  # Alt+Backspace
bindkey "^[." insert-last-word     # Alt+. (insert last argument)
bindkey "^[<" beginning-of-buffer-or-history  # Alt+< (beginning)
bindkey "^[>" end-of-buffer-or-history        # Alt+> (end)

# Aliases - git
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit"
alias gcd="git commit -m '$(date -u +\'%Y-%m-%dT%H:%M:%S\')'"
alias gbo="git checkout"
alias gbb="git checkout -b"
alias gs="git status -sb"
alias gp="git push"
alias gl="git log --oneline -10"

# git quick
gq() {
  git add .
  git commit -m "$(date -u +'%Y-%m-%dT%H:%M:%S')"
  git push
}

# init starship
eval "$(starship init zsh)"
EOF

# configure starship
echo "Configuring Starship..."
mkdir -p ~/.config/starship
curl -o ~/.config/starship.toml https://raw.githubusercontent.com/wadefletch/dotfiles/main/starship/.config/starship.toml

# configure ghostty
echo "Configuring Ghostty..."
mkdir -p ~/.config/ghostty
curl -o ~/.config/ghostty/config https://raw.githubusercontent.com/wadefletch/dotfiles/main/ghostty/.config/ghostty/config

# configure cursor
echo "Configuring Cursor..."
mkdir -p ~/Library/Application\ Support/Cursor/User
cat > ~/Library/Application\ Support/Cursor/User/settings.json <<'EOF'
{
  "[css][html][json][jsonc][mdx][markdown][javascript][javascriptreact][typescript][typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "[dockerfile]": {
    "editor.defaultFormatter": "ms-azuretools.vscode-containers",
    "editor.formatOnSave": true
  },
  "[python]": {
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    },
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "breadcrumbs.enabled": false,
  "cSpell.enabled": false,
  "cSpell.userWords": ["Tractorbeam"],
  "cursor.aipreview.enabled": true,
  "cursor.cmdk.useThemedDiffBackground": true,
  "cursor.composer.shouldChimeAfterChatFinishes": true,
  "cursor.cpp.disabledLanguages": ["scminput"],
  "cursor.general.enableShadowWorkspace": true,
  "editor.bracketPairColorization.enabled": false,
  "editor.codeActionsOnSave": {
    "source.fixAll": "always"
  },
  "editor.cursorBlinking": "smooth",
  "editor.fontFamily": "'IosevkaTerm Nerd Font Mono', 'Courier New'",
  "editor.formatOnSave": true,
  "editor.renderWhitespace": "trailing",
  "editor.rulers": [80, 120],
  "editor.scrollbar.verticalScrollbarSize": 4,
  "editor.smoothScrolling": true,
  "eslint.codeActionsOnSave.mode": "all",
  "explorer.confirmDragAndDrop": false,
  "files.exclude": {
    "**/__pycache__/**": true,
    "**/.pytest_cache/**": true
  },
  "githubPullRequests.terminalLinksHandler": "github",
  "javascript.updateImportsOnFileMove.enabled": "always",
  "json.schemaDownload.enable": true,
  "material-icon-theme.folders.theme": "classic",
  "material-icon-theme.hidesExplorerArrows": true,
  "material-icon-theme.saturation": 0,
  "python.analysis.autoImportCompletions": true,
  "python.analysis.importFormat": "relative",
  "ruff.nativeServer": "auto",
  "rust-analyzer.check.workspace": false,
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.scrollback": 8000,
  "terminal.integrated.shellIntegration.enabled": true,
  "typescript.updateImportsOnFileMove.enabled": "always",
  "update.releaseTrack": "prerelease",
  "window.autoDetectColorScheme": true,
  "workbench.fontAliasing": "antialiased",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.list.smoothScrolling": true,
  "workbench.preferredDarkColorTheme": "Tokyo Night Storm",
  "workbench.preferredLightColorTheme": "Tokyo Night Light",
  "cursor.enable_agent_window_setting": true,
  "claude-code.selectedModel": "default"
}
EOF

# install cursor shell command
echo "Installing Cursor shell command..."
echo "Please follow these steps:"
echo "1. Cursor should open automatically"
echo "2. Press Command+Shift+P to open the command palette"
echo "3. Type 'Shell Command: Install 'cursor' command'"
echo "4. Press Enter to install"
echo "5. Close Cursor when done"
echo ""
echo "Press Enter when you've completed these steps..."
open -a Cursor
read

# install cursor plugins
echo "Installing Cursor plugins..."
cursor --install-extension esbenp.prettier-vscode
cursor --install-extension ms-azuretools.vscode-containers
cursor --install-extension charliermarsh.ruff
cursor --install-extension enkia.tokyo-night
cursor --install-extension pkief.material-icon-theme
cursor --install-extension anthropic.claude-code

# install nvm
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# source nvm for current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# install node
echo "Installing Node.js..."
nvm install 22

# install corepack
echo "Installing Corepack..."
npm i -g corepack

# login to github
echo "Logging in to GitHub..."
gh auth login

# opening ghostty
echo "Opening Ghostty..."
open -a Ghostty

# opening cursor
echo "Opening Cursor..."
open -a Cursor

echo ""
echo "Setup complete! Additional recommendations:"
echo "- Set up Bitwarden as a better replacement for the built-in Passwords app"
echo "- Set up Time Machine backups"
echo "- Enable FileVault for disk encryption (System Settings > Privacy & Security)"
echo "- Configure Firewall (System Settings > Network > Firewall)"