#!/bin/sh

echo "Setting up your Mac..."

# Check for Homebrew and install it if we don't have it
echo "Checking if Homebrew is installed..."
if test ! $(which brew); then
  echo "Installing Homebrew!"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew is already installed."
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
echo "Symlinking .zshrc..."
rm -rf $HOME/.zshrc
ln -s zsh/.zshrc $HOME/.zshrc

# Update Homebrew recipes
echo "Running 'brew update'..."
brew update

# Install all our dependencies with bundle (See Brewfile)
echo "Installing everything from Brewfile..."
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Install NVM
echo "Install NVM..."
PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
