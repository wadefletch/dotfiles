#!/bin/bash

# Simple script to stow all dotfiles directories

directories=(
    "alacritty"
    "cargo"
    "claude"
    "cursor"
    "git"
    "nvim"
    "skhd"
    "ssh"
    "superwhisper"
    "tmux"
    "vscode"
    "yabai"
    "zsh"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "Stowing $dir..."
        stow "$dir"
    else
        echo "Directory $dir not found, skipping..."
    fi
done

echo "Done!"