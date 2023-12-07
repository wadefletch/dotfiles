# zsh config
# Wade Fletcher, 2023

# ========== Path Adjustments ==========
export PATH="/usr/local/sbin:$PATH" # homebrew
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" # yarn
export PATH="$HOME/.pyenv/bin:$PATH" # pyenv

# ============== Aliases ===============
# Config File Shortcuts
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias skhdrc="nvim ~/.dotfiles/skhd/.skhdrc"
alias alacrittyrc="nvim ~/.dotfiles/alacritty/.alacritty.yml"
alias nvimconf="cd ~/.dotfiles/nvim/.config/nvim/ && nvim ."

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
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
  if [[ $branch == "" ]];
  then
    :
  else
    echo '('$branch') '
  fi
}

setopt prompt_subst

prompt='%2/ $(git_branch_name)λ '
