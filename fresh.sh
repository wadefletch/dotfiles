#!/bin/zsh

# https://github.com/driesvints/dotfiles

echo "== Setting up your Mac..."

echo "== Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo "== Updating Homebrew and Formulae"
brew update

echo "== Installing from Brewfile"
brew tap homebrew/bundle
brew bundle

echo "== Cleaning up"
brew cleanup

echo "== Installing Xcode Command Line Tools"
xcode-select --install

echo "== Setting up pyenv"
pyenv update
pyenv install 3.8.6
pyenv global 3.8.6

echo "== Setting up nvm"
nvm install node

echo "== Removing existing .zshrc"
rm -rf $HOME/.zshrc

echo "== Setting up yabai"
sudo yabai --install-sa
echo "$USER ALL = (root) NOPASSWD: /usr/local/bin/yabai --load-sa" >>/private/etc/sudoers.d/yabai

echo "== Starting services"
brew services start skhd
brew services start yabai
open -a MeetingBar

echo "== Setting macOS settings"
source .macos

echo "== Updating macOS App Store apps"
mas upgrade

echo "== Stowing dotfiles"
sh stow_all.sh

echo "== Installing vscode extensions"
sh vscode_extensions.sh

echo "===== DONE ====="
echo "Enjoy! -Wade"
