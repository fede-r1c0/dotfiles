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

# Terminal history hygiene
# histstop / histstart : pause/resume recording in current session
# histfind / histclear : scan / redact secrets in history files
if [[ -n "${ZSH_VERSION-}" ]]; then
    histstop() {
        export HISTIGNORE='*'
        export HIST_PRIVATE=1
        # Avoid clobbering Powerlevel10k / Starship right-prompt
        if [[ -z "${P9K_MODE-}${STARSHIP_SHELL-}" ]]; then
            RPROMPT='%F{red}[HIST OFF]%f'
        fi
        print -P '%F{yellow}History recording paused.%f Use %F{green}histstart%f to resume.'
    }
    histstart() {
        unset HISTIGNORE HIST_PRIVATE
        if [[ -z "${P9K_MODE-}${STARSHIP_SHELL-}" ]]; then
            RPROMPT=''
        fi
        print -P '%F{green}History recording resumed.%f'
    }
fi
alias histfind='~/.zsh/scripts/hist-hygiene.sh --find'
alias histclear='~/.zsh/scripts/hist-hygiene.sh --clear'

# Set alias for Nvim
alias vim='nvim --cmd "set rtp+=~/.config/nvim"'

# Modern CLI aliases
alias ll='eza -lah --show-symlinks --icons --git'
# Git aliases
alias gbc='~/.zsh/scripts/git-branch-cleanup.sh' # Git branch cleanup script

# Custom aliases
alias bu='~/.zsh/scripts/brew-update.sh' # Brew update script
alias claude-mem='"$HOME/.bun/bin/bun" "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
