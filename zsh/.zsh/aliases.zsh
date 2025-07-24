# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Navigation aliases
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....="cd ../../../.."
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

# File management aliases
alias mv='mv -iv'
alias ln='ln -iv'
alias rm='rm -i'

# Terminal history aliases
alias private-mode='export HISTIGNORE="*" && echo "History recording paused. Use exit-private-mode to resume."'
alias exit-private-mode='unset HISTIGNORE && echo "History recording resumed."'

# Set alias for Nvim
alias vim='nvim --cmd "set rtp+=~/.config/nvim"'

# Modern CLI aliases
alias ls='eza -lh --icons --git'
alias ll='eza -lah --show-symlinks --icons --git'
alias find='fd'
alias grep='rg'
alias du='dust'
alias cd='z'
alias cat='bat'