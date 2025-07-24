#########################################
######	Kubernetes configuration  #######

# Set kube-ps1 for Kubernetes prompt
KUBE_PS1_BINARY=oc
PROMPT='$(kube_ps1)'$PROMPT # or RPROMPT='$(kube_ps1)'

### Kubernetes zsh complete kubectl
source <(kubectl completion zsh)

### Set kubectl alias to use kubecolor
alias kubectl=kubecolor
compdef kubecolor=kubectl

### Set dyff for kubernetes
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"

# Config Krew - a plugin manager for kubectl
# https://krew.sigs.k8s.io/docs/user-guide/setup/install-krew/
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
alias krew='kubectl krew'

########################################
#######  Kubernetes aliases  ###########

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
