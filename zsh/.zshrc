export EDITOR="nvim"

# Pyenv (Python)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# NVM (Node)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# PNPM (Node)
export PNPM_HOME="/Users/wadefletcher/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Rustup (Rust)
export PATH="$(brew --prefix rustup)/bin:$PATH"

# Postgres 17
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# LLVM (probably Rust, tbh not sure why i have this)
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# AWS Cli
export AWS_PAGER=""  # disable paging so agents can consume

# History
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # save timestamp
setopt HIST_EXPIRE_DUPS_FIRST    # expire duplicates first
setopt HIST_IGNORE_DUPS          # ignore duplicated commands
setopt HIST_IGNORE_SPACE         # ignore commands starting with space
setopt HIST_VERIFY               # show command before executing from history

# Keybinds
bindkey -e  # Use emacs key bindings (readline compatible)

# History search with up/down arrows
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Standard readline word movement (Alt+f/b)
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Alt+arrow for word movement (multiple terminal escape sequences)
bindkey "^[[1;3C" forward-word     # Alt+Right
bindkey "^[[1;3D" backward-word    # Alt+Left
bindkey "^[^[[C" forward-word      # Alt+Right (older terminals)
bindkey "^[^[[D" backward-word     # Alt+Left (older terminals)

# Additional readline-compatible bindings
bindkey "^[d" kill-word            # Alt+d (delete word forward)
bindkey "^[^?" backward-kill-word  # Alt+Backspace
bindkey "^[." insert-last-word     # Alt+. (insert last argument)
bindkey "^[<" beginning-of-buffer-or-history  # Alt+< (beginning)
bindkey "^[>" end-of-buffer-or-history        # Alt+> (end)

# Prompt
if [[ -n "$CURSOR_AGENT" ]]; then
  # Skip pretty terminal init when inside a Cusror Agent sandbox
else
  eval "$(starship init zsh)"
fi

# Aliases - tools
alias claude="/Users/wadefletcher/.claude/local/claude"

# Aliases - config files
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias ghosttyrc="nvim ~/.dotfiles/ghostty/.config/ghostty/config"
alias nvimconf="nvim ~/.dotfiles/nvim/.config/nvim/"

# Aliases - git
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit"
alias gcd="git commit -m '$(date -u +\'%Y-%m-%dT%H:%M:%S\')'"
alias gbo="git checkout"
alias gbb="git checkout -b"
alias gs="git status -sb"
alias gp="git push"
alias gl="git log --oneline -10"

# Utility functions
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

