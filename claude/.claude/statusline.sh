#!/bin/bash
# Claude Code status line
#
# Design:
#   cyan    → directory (primary context - where you are)
#   white   → git branch (navigation context)
#   green   → added lines
#   red     → deleted lines
#   gray    → metadata (model, context %)
#
# Format: dir branch +N -N · model · %%

input=$(cat)

# Current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$current_dir")

# Model
model=$(echo "$input" | jq -r '.model.display_name')

# Context window percentage (use new built-in field)
percent=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Git info
branch=""
diff_stat=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
             git -C "$current_dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

    # Line diff counts (staged + unstaged)
    stats=$(git -C "$current_dir" --no-optional-locks diff --numstat HEAD 2>/dev/null | \
            awk '{add+=$1; del+=$2} END {printf "%d %d", add, del}')
    added=$(echo "$stats" | cut -d' ' -f1)
    deleted=$(echo "$stats" | cut -d' ' -f2)

    if [ "$added" -gt 0 ] || [ "$deleted" -gt 0 ]; then
        diff_stat=" +${added} -${deleted}"
    fi
fi

# Colors
cyan="\033[36m"
green="\033[32m"
red="\033[31m"
gray="\033[90m"
reset="\033[0m"

# Output: dir branch +N -N · model · %%
if [ -n "$branch" ]; then
    if [ -n "$diff_stat" ]; then
        printf "${cyan}%s${reset} %s ${green}+%s${reset} ${red}-%s${reset} ${gray}· %s · %d%%${reset}" \
            "$dir_name" "$branch" "$added" "$deleted" "$model" "$percent"
    else
        printf "${cyan}%s${reset} %s ${gray}· %s · %d%%${reset}" \
            "$dir_name" "$branch" "$model" "$percent"
    fi
else
    printf "${cyan}%s${reset} ${gray}· %s · %d%%${reset}" \
        "$dir_name" "$model" "$percent"
fi
