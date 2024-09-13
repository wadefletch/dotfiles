# zsh config
# Wade Fletcher, 2023

# ========== Path Adjustments ==========
export PATH="/usr/local/sbin:$PATH"                                             # homebrew
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" # yarn
export PATH="$HOME/.pyenv/bin:$PATH"                                            # pyenv
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"                                  # llvm

# ============== Aliases ===============
# Config File Shortcuts
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias skhdrc="nvim ~/.dotfiles/skhd/.skhdrc"
alias yabairc="nvim ~/.dotfiles/yabai/.yabairc"
alias alacrittyrc="nvim ~/.dotfiles/alacritty/.alacritty.toml"
alias nvimconf="cd ~/.dotfiles/nvim/.config/nvim/ && nvim init.lua"

# Git Shortcuts
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gq="git add . && git commit -m \"$(date -u +'%Y-%m-%dT%H:%M:%S')\" && git push"
alias wip="git add . && git commit -m \"WIP $(date -u +'%Y-%m-%dT%H:%M:%S')\" && git push"

# yabai + skhd shortcuts
alias startup="yabai --restart-service && sudo yabai --load-sa && skhd --restart-service"

# ============== PNPM ==================
export PNPM_HOME="/Users/wadefletcher/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ============== Pyenv =================
eval "$(pyenv init -)"

# ============== History ===============
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# ============== Prompt ================
function git_branch_name() {
  branch=$(git symbolic-ref HEAD 2>/dev/null | awk 'BEGIN{FS="/"} {print $NF}')
  if [[ $branch == "" ]]; then
    :
  else
    echo '('$branch') '
  fi
}

setopt prompt_subst

PROMPT='%F{yellow}%~/%f $(git_branch_name)%F{blue}λ%f '

# bun completions
[ -s "/Users/wadefletcher/.bun/_bun" ] && source "/Users/wadefletcher/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo
. "$HOME/.cargo/env"

# gcloud components
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
