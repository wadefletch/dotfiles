# Environment
export EDITOR="nvim"
export AWS_PAGER=""  # disable paging for cursor
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="/Users/wadefletcher/Library/pnpm"

# Path
export PATH="/usr/local/sbin:$PATH"                                             # homebrew sbin
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"                                  # llvm
export PATH="$BUN_INSTALL/bin:$PATH"                                            # bun
export PATH="$PNPM_HOME:$PATH"                                                  # pnpm
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" # yarn
export PATH="$HOME/.local/bin:$PATH"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

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
eval "$(starship init zsh)"

# Aliases - tools
alias claude="/Users/wadefletcher/.claude/local/claude"

# Aliases - config files
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias nvimconf="cd ~/.dotfiles/nvim/.config/nvim/ && nvim init.lua"
alias alacrittyrc="nvim ~/.dotfiles/alacritty/.config/alacritty/alacritty.toml"

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

 cctb() {
      local agent_name="$1"
      local cc_cmd="CROWDCONTROL_WORKSPACES_DIR=~/Development/Tractorbeam/cc-workspaces crowdcontrol"
      local repo="tractorbeamai/monorepo"

      echo "🛸 Creating agent: $agent_name"
      if eval "$cc_cmd new $agent_name git@github.com:$repo"; then

          echo "🚀 Starting agent..."
          if eval "$cc_cmd start $agent_name"; then

              echo "🔌 Connecting to agent..."
              eval "$cc_cmd connect $agent_name"
          else
              echo "❌ Failed to start agent: $agent_name"
              return 1
          fi
      else
          echo "❌ Failed to create agent: $agent_name"
          return 1
      fi
  }

# Lazy load expensive gcloud
gcloud() {
  unset -f gcloud
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
  gcloud "$@"
}

# Immediate loads (fast)
. "$HOME/.cargo/env"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
