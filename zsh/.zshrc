# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle :omz:plugins:ssh-agent agent-forwarding yes

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 7

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Homebrew completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  autoload -Uz compinit
fi

# Auto-fix ZSH compinit insecure directories
function fix_compinit_insecure_dirs() {
  local insecure_dirs=$(compaudit 2>/dev/null)
  if [[ -n "$insecure_dirs" ]]; then
    echo "Fixing insecure completion directories..."
    for dir in ${(f)insecure_dirs}; do
      chmod 755 "$dir"
      chmod 755 "$(dirname $dir)"
    done
    # Reinitialize completions
    rm -f ~/.zcompdump; compinit
  fi
}
fix_compinit_insecure_dirs

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git 
  docker
  kubectl
  minikube
  aws
  terraform
  vscode
  ssh-agent
  zsh-syntax-highlighting
  zsh-autosuggestions
  you-should-use
  aliases
  alias-finder
  encode64
  kube-ps1
  tldr
  fabric
  thefuck
)

source $ZSH/oh-my-zsh.sh

KUBE_PS1_BINARY=oc
PROMPT='$(kube_ps1)'$PROMPT # or RPROMPT='$(kube_ps1)'

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Modern CLI aliases
alias ls='eza --icons --git'
alias ll='eza -l --icons --git'
alias la='eza -lah --show-symlinks --icons --git'
alias find='fd'
alias grep='rg'
alias du='dust'

# Initialize thefuck (corrects your previous command)
eval $(thefuck --alias)

# Initialize MacFly (better history search)
eval "$(mcfly init zsh)"

# Initialize zoxide (smart cd command)
eval "$(zoxide init zsh)"
alias cd='z'

### Terminal history aliases
alias private-mode='export HISTIGNORE="*" && echo "History recording paused. Use exit-private-mode to resume."'
alias exit-private-mode='unset HISTIGNORE && echo "History recording resumed."'

### Set dyff for kubernetes
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"

### Set alias for Nvim
alias vim='nvim --cmd "set rtp+=~/.config/nvim"'

# Config Krew - a plugin manager for kubectl
# https://krew.sigs.k8s.io/docs/user-guide/setup/install-krew/
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
alias krew='kubectl krew'

########################################
#######  Kubernetes aliases  ###########

# get zsh complete kubectl
source <(kubectl completion zsh)
alias kubectl=kubecolor
# make completion work with kubecolor
compdef kubecolor=kubectl

alias k=kubectl
alias kg='kubectl get'
alias kgl='kubectl get -l'
alias kgw='kubectl get --watch'
alias kd='kubectl describe'
alias kdl='kubectl describe -l'
alias kex='kubectl exec -it'
alias klo='kubectl logs -f'
alias kdel='kubectl delete'

alias kcn='kubectl config set-context --current --namespace'
alias kctx='kubectl ctx'

alias kgp='kubectl get pods'
alias kgd='kubectl get deployment'
alias kge='kubectl get events'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kgcm='kubectl get configmap'
alias kgsec='kubectl get secret'
alias kgpv='kubectl get pv'
alias kgpvc='kubectl get pvc'
alias kgcrd='kubectl get crd'
alias kgno='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgsts='kubectl get statefulset'
alias kga='kubectl get-all'

alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe svc'
alias kdi='kubectl describe ingress'
alias kdcm='kubectl describe configmap'
alias kdsec='kubectl describe secret'
alias kdpv='kubectl describe pv'
alias kdpvc='kubectl describe pvc'
alias kdcrd='kubectl describe crd'
alias kdno='kubectl describe node'
alias kdns='kubectl describe namespace'
alias kdsts='kubectl describe statefulset'

alias kdelp='kubectl delete pod'
alias kdeld='kubectl delete deployment'
alias kdels='kubectl delete svc'
alias kdeli='kubectl delete ingress'
alias kdelcm='kubectl delete configmap'
alias kdelsec='kubectl delete secret'
alias kdelpv='kubectl delete pv'
alias kdelpvc='kubectl delete pvc'
alias kdelcrd='kubectl delete crd'
alias kdelno='kubectl delete node'
alias kdelns='kubectl delete namespace'
alias kdelsts='kubectl delete statefulset'

alias ksys='kubectl --namespace=kube-system'


############################################
## Terraform / Terragrunt / Tofu aliases ###
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

#########################################
###### Fabric config and aliases ########
alias fabric='fabric-ai'

# Loop through all files in the ~/.config/fabric/patterns directory
for pattern_file in $HOME/.config/fabric/patterns/*; do
    # Get the base name of the file (i.e., remove the directory path)
    pattern_name=$(basename "$pattern_file")

    # Create an alias in the form: alias pattern_name="fabric --pattern pattern_name"
    alias_command="alias $pattern_name='fabric --pattern $pattern_name'"

    # Evaluate the alias command to add it to the current shell
    eval "$alias_command"
done

yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] youtube-link"
        echo "Use the '-t' flag to get the transcript with timestamps."
        return 1
    fi

    transcript_flag="--transcript"
    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi
    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}

#########################################

fpath=(~/.zsh/completions $fpath)
