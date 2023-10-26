# ============= oh-my-zsh ==============
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="gentoo"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# ========== Path Adjustments ==========
export PATH="/usr/local/sbin:$PATH" # homebrew
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" # yarn
export PAth="$HOME/.pyenv/bin:$PATH" # pyenv

# ============== Aliases ===============
# Config File Shortcuts
alias zshrc="nvim ~/.dotfiles/zsh/.zshrc"
alias skhdrc="nvim ~/.dotfiles/skhd/.skhdrc"
# alias yabairc="nvim ~/.dotfiles/yabai/.yabairc"
alias alacrittyrc="nvim ~/.dotfiles/alacritty/.alacritty.yml"

# Neovim Config Shortcut
alias nvimconf="cd ~/.dotfiles/nvim/.config/nvim/ && nvim ."

# Atmos Monorepo Tools
alias yws="yarn workspace"
alias ywsf="yarn workspace @atmos/frontend"
alias ywsb="yarn workspace @atmos/backend"
alias ywsr="yarn workspace @atmos/reports"
alias atmos="cd ~/Development/Atmos/atmos-app/"


# pnpm
export PNPM_HOME="/Users/wadefletcher/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
