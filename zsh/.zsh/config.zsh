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
(( $+commands[thefuck] )) && eval "$(thefuck --alias)"

# Initialize MacFly (better history search)
(( $+commands[mcfly] )) && eval "$(mcfly init zsh)"

# Initialize zoxide (smart cd command)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# Initialize fnm (Fast Node Manager)
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"

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

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Kiro
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
