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

# Rustup (Rust)
if command -v brew &> /dev/null && brew list rustup &>/dev/null; then
  export PATH="$(brew --prefix rustup)/bin:$PATH"
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
# Aliases - directories
alias cdd="cd ~/.dotfiles"
alias cdcm="cd ~/Developer/Tractorbeam/client-carlyle/carlyle-monorepo"
alias cdii="cd ~/Developer/Tractorbeam/internal-infra"
alias cdt="cd ~/Developer/Tractorbeam"

# Aliases - git
if command -v git &> /dev/null; then
  alias ga="git add"
  alias gc="git commit -m"
  alias gcd="git commit -m '$(date -u +\'%Y-%m-%dT%H:%M:%S\')'"
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

# mkdir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Stop all Docker containers and processes on dev ports
stopall() {
  local containers
  containers=$(docker ps --format '{{.ID}} {{.Names}}' | grep -v orbstack)
  if [[ -n "$containers" ]]; then
    echo "$containers" | awk '{print $2}' | while read -r name; do echo "  container: $name"; done
    echo "$containers" | awk '{print $1}' | xargs -r docker kill 2>/dev/null
  fi
  local pids
  for port in 3000 3001 3002 3003 3004 3005 4000 4001 4100 4317 4318 4566 5432 6379 8126 8888 8889 8890; do
    pids=$(lsof -ti:$port 2>/dev/null)
    if [[ -n "$pids" ]]; then
      echo "  port $port: $(echo "$pids" | wc -w | tr -d ' ') process(es)"
      echo "$pids" | xargs kill -9 2>/dev/null
    fi
  done
  echo "done"
}


# Automatically squash-merge PR after all checks pass
automerge() {
  gh pr checks $1 --watch && gh pr merge $1 --squash --delete-branch
}

# Run a gh command as the Carlyle account over HTTPS, then switch back
ghc() {
  gh auth switch --user wade-fletcher-cw_tcgemu
  gh config set -h github.com git_protocol https
  gh "$@"
  gh auth switch --user wadefletch
  gh config set -h github.com git_protocol ssh
}
