#====== Path Adjustments =====
export PATH="$HOME/.bin:$PATH"


# ===== powerline-10k =====

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /usr/local/opt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ===== pyenv =====
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi


# ===== NVM =====
export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


# ===== fzf =====
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# ===== Historical Completion =====
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down


# ===== zsh-autosuggestions =====
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh


# ===== Fun Commands of My Own Addition =====

alias top='vtop --theme nord'
alias spotify='ncspot'

alias wifi='osx-wifi-cli'
alias chrome="/Applications/Google\\ \\Chrome.app/Contents/MacOS/Google\\ \\Chrome"
alias netflix="chrome --app=https://netflix.com"
alias dm="dark-mode"

alias vimrc="sudo vim ~/.dotfiles/vim/.vimrc"
alias zshrc="sudo vim ~/.dotfiles/zsh/.zshrc"
alias skhdrc="sudo vim ~/.dotfiles/skhd/.skhdrc"
alias yabairc="sudo vim ~/.dotfiles/yabai/.yabairc"

