# Environment
export EDITOR="nvim"
export AWS_PAGER=""  # disable paging for cursor
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="/Users/wadefletcher/Library/pnpm"

# Path - consolidated
export PATH="/usr/local/sbin:$PATH"                                             # homebrew sbin
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"                                  # llvm
export PATH="$BUN_INSTALL/bin:$PATH"                                            # bun
export PATH="$PNPM_HOME:$PATH"                                                  # pnpm
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" # yarn
export PATH="$HOME/.pyenv/bin:$PATH"                                            # pyenv

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # save timestamp
setopt HIST_EXPIRE_DUPS_FIRST    # expire duplicates first
setopt HIST_IGNORE_DUPS          # ignore duplicated commands
setopt HIST_IGNORE_SPACE         # ignore commands starting with space
setopt HIST_VERIFY               # show command before executing from history
setopt SHARE_HISTORY             # share history between sessions

# Key bindings
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b) '
setopt PROMPT_SUBST
PROMPT='%F{yellow}%~/%f ${vcs_info_msg_0_}%F{green}λ%f '

# Aliases - config files
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias nvimconf="cd ~/.dotfiles/nvim/.config/nvim/ && nvim init.lua"
alias alacrittyrc="nvim ~/.dotfiles/alacritty/.config/alacritty/alacritty.toml"
alias skhdrc="nvim ~/.dotfiles/skhd/.skhdrc"
alias yabairc="nvim ~/.dotfiles/yabai/.yabairc"

# Aliases - git
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gs="git status -sb"
alias gp="git push"
alias gl="git log --oneline -10"

# Functions
gq() {
  git add .
  git commit -m "$(date -u +'%Y-%m-%dT%H:%M:%S')"
  git push
}

claude-sync() {
  local current_host=$(hostname)
  if [[ "$current_host" == "arrakis" ]]; then
    rsync -avz corrino:~/.claude/projects/ ~/.claude/projects/
  elif [[ "$current_host" == "corrino" ]]; then
    rsync -avz arrakis:~/.claude/projects/ ~/.claude/projects/
  else
    echo "Current host is neither arrakis nor corrino"
    return 1
  fi
}

# Lazy loading
pyenv() {
  unset -f pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

gcloud() {
  unset -f gcloud
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
  gcloud "$@"
}

# Aliases - tools
alias startup="yabai --restart-service && sudo yabai --load-sa && skhd --restart-service"
alias claude="/Users/wadefletcher/.claude/local/claude"

# Immediate loads (fast)
. "$HOME/.cargo/env"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
