#!/bin/bash
input=$(cat)

# Current directory and git info
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$current_dir")
model=$(echo "$input" | jq -r '.model.display_name')

# Git branch
git_info=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
             git -C "$current_dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    git_info="  $branch"  # nf-dev-git_branch
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

# Cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost_fmt=$(printf "%.2f" "$cost")

printf "\033[36m%s\033[0m%s \033[90m%s · %d%% · \$%s\033[0m" \
    "$dir_name" "$git_info" "$model" "$percent" "$cost_fmt"
