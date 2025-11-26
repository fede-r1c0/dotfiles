# User configuration

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Set terminal history options
HISTFILE=~/.zsh_history
HISTSIZE=100000
HISTTIMEFORMAT="%m-%d-%y %r "
HIST_STAMPS="mm/dd/yyyy"
SAVEHIST=100000

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Set EDITOR and VISUAL to nvim if available, otherwise use vim
if (( ${+commands[nvim]} )); then
  export EDITOR=nvim
  export VISUAL=nvim
else
  export EDITOR=vim
  export VISUAL=vim
fi

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Homebrew completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  autoload -Uz compinit
fi

# ZSH Completion
autoload -Uz compinit && compinit
_comp_options+=(globdots)	# auto-complete dot files

# Initialize thefuck (corrects your previous command)
eval "$(thefuck --alias)"

# Initialize MacFly (better history search)
eval "$(mcfly init zsh)"

# Initialize zoxide (smart cd command)
eval "$(zoxide init zsh)"

# Initialize fnm (Fast Node Manager)
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi
eval "$(fnm env --use-on-cd --shell zsh)"

# GPG TTY
export GPG_TTY=$(tty)

# Set the default pager to less with specific options
export MANPAGER="sh -c 'col -bx | bat -l man -p'"  

# IDEs and other tools that use the terminal
if [[ "$PAGER" == "head -n 10000 | cat" || "$COMPOSER_NO_INTERACTION" == "1" ]]; then
  return
fi

if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
  return
fi

# Added by Antigravity
export PATH="/Users/fede/.antigravity/antigravity/bin:$PATH"
