# Default editor
if command -v nvim &> /dev/null; then
  export EDITOR="nvim"
fi

# Pyenv (Python)
if command -v pyenv &> /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - zsh)"
fi

# NVM (Node)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# PNPM (Node)
if [[ -d "/Users/wadefletcher/Library/pnpm" ]]; then
  export PNPM_HOME="/Users/wadefletcher/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi

# Rustup (Rust)
if command -v brew &> /dev/null && brew list rustup &>/dev/null; then
  export PATH="$(brew --prefix rustup)/bin:$PATH"
fi

# Cargo-installed Binaries (Rust)
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Postgres 17
if [[ -d "/opt/homebrew/opt/postgresql@17/bin" ]]; then
  export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
fi

# LLVM (probably Rust, tbh not sure why i have this)
if [[ -d "/opt/homebrew/opt/llvm/bin" ]]; then
  export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
fi

# Path addition required by factory.ai droid
if [[ -d "/Users/wadefletcher/.local/bin" ]]; then
  export PATH="/Users/wadefletcher/.local/bin:$PATH"
fi

# AWS CLI
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
  # Skip pretty terminal init when inside a Cursor Agent sandbox
elif command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Aliases - config files
alias zshrc="${EDITOR:-vi} ~/.dotfiles/zsh/.zshrc"
alias ghosttyrc="${EDITOR:-vi} ~/.dotfiles/ghostty/.config/ghostty/config"
alias nvimconf="${EDITOR:-vi} ~/.dotfiles/nvim/.config/nvim/"

# Aliases - git
if command -v git &> /dev/null; then
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
fi

# Utility functions
if command -v git &> /dev/null; then
  gq() {
    git add .
    git commit -m "$(date -u +'%Y-%m-%dT%H:%M:%S')"
    git push
  }
fi

# Stop all Docker containers and processes on dev ports
stopall() {
  docker ps -q | xargs -r docker kill 2>/dev/null
  for port in 3000 3001 3002 3003 3004 3005; do
    lsof -ti:$port | xargs -r kill -9 2>/dev/null
  done
  echo "Stopped all Docker containers and cleared ports 3000-3005"
}


