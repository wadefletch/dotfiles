#!/bin/bash

# Description:
# This script lists all installed applications in /Applications and ~/Applications,
# extracts their names, sanitizes them, and searches for matches in Homebrew formulae and casks.

# Handle Ctrl-C gracefully
trap 'echo -e "\n\nInterrupted by user"; exit 130' INT

# Find all .app directories in both /Applications and ~/Applications
find /Applications ~/Applications -maxdepth 1 -type d -name "*.app" -print0 | while IFS= read -r -d $'\0' app_path; do
    # Extract the application name without the .app suffix
    app_name=$(basename "$app_path" .app)
    echo "Checking: $app_name"

    # Sanitize the app name to create a basic search term for Homebrew
    # - Replace spaces with hyphens
    # - Remove everything after @ (if versioned)
    # - Replace other non-alphanumeric characters with hyphens
    search_term=$(echo "$app_name" | sed -e 's/@.*//' -e 's/ /-/g' -e 's/[^A-Za-z0-9-]/-/g')

    # Check if already installed via brew
    installed_via_brew=false
    
    # Check if installed as a cask
    if brew list --cask "$search_term" >/dev/null 2>&1; then
        installed_via_brew=true
        cask_info=$(brew info --cask "$search_term" 2>/dev/null | head -1)
        echo -e "  \033[32m✓ Installed via Homebrew cask: $cask_info\033[0m"
    # Check if installed as a formula
    elif brew list "$search_term" >/dev/null 2>&1; then
        installed_via_brew=true
        formula_info=$(brew info "$search_term" 2>/dev/null | head -1)
        echo -e "  \033[32m✓ Installed via Homebrew formula: $formula_info\033[0m"
    fi

    # If not installed via brew, check if available
    if [ "$installed_via_brew" = false ]; then
        echo -e "  \033[31m✗ Not installed via Homebrew\033[0m"
        
        # Search for a matching Homebrew cask
        if cask_match=$(brew search --cask "$search_term" 2>/dev/null | grep -i "^$search_term\$"); then
            cask_info=$(brew info --cask "$cask_match" 2>/dev/null | head -1)
            echo "    Available as cask: $cask_info"
        # Search for a matching Homebrew formula
        elif formula_match=$(brew search "$search_term" 2>/dev/null | grep -i "^$search_term\$"); then
            formula_info=$(brew info "$formula_match" 2>/dev/null | head -1)
            echo "    Available as formula: $formula_info"
        fi
    fi
done