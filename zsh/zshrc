# Add deno completions to search path
# if [[ ":$FPATH:" != *":/home/usman/completions:"* ]]; then export FPATH="/home/usman/completions:$FPATH"; fi
# Add deno completions to search path
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

alias c=clear
alias lg=lazygit
alias gpo="git push origin"
alias gpl="git pull origin"
alias zed="flatpak run dev.zed.Zed"

source $ZSH/oh-my-zsh.sh
export PATH="$HOME/.rbenv/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(zoxide init zsh)";
eval "$(rbenv init -)"

export EDITOR='vim'
