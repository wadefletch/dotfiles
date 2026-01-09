#!/bin/bash
# Claude Code status line
#
# Design:
#   cyan    → directory (primary context - where you are)
#   white   → git branch (navigation context)
#   gray    → metadata (model, context %)
#
# Groups separated by ·
#   location (dir branch) | model | context %
#
# Format: dir branch · model · %%

input=$(cat)

# Current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$current_dir")

# Model
model=$(echo "$input" | jq -r '.model.display_name')

# Git branch
branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
             git -C "$current_dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# Context window percentage
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ] && [ "$context_size" != "null" ] && [ "$context_size" != "0" ]; then
    tokens=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    percent=$((tokens * 100 / context_size))
else
    percent=0
fi

# Colors
cyan="\033[36m"
gray="\033[90m"
reset="\033[0m"

# Output: dir branch · model · %%
if [ -n "$branch" ]; then
    printf "${cyan}%s${reset} %s ${gray}· %s · %d%%${reset}" \
        "$dir_name" "$branch" "$model" "$percent"
else
    printf "${cyan}%s${reset} ${gray}· %s · %d%%${reset}" \
        "$dir_name" "$model" "$percent"
fi
