# Shell prerequisites for dotfiles

These are the shell prerequisites for my dotfiles configuration. This is a work in progress and will be updated as I add more tools and configurations scripts to automate the installation of the prerequisites in each OS.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
  - [macOS](#macos)
    - [Install homebrew package manager](#install-homebrew-package-manager)
    - [Install latest zsh version](#install-latest-zsh-version)
    - [Install development & productivity tools](#install-development--productivity-tools)
  - [Linux](#linux)
    - [Arch Linux](#arch-linux)
      - [Install packages from pacman](#install-packages-from-pacman)
      - [Set zsh as default shell](#set-zsh-as-default-shell)
    - [Raspberry Pi OS](#raspberry-pi-os)
      - [Install packages from apt](#install-packages-from-apt)
      - [Set zsh as default shell](#set-zsh-as-default-shell)
      - [Install eza](#install-eza)
      - [Install dust](#install-dust)
      - [Install mcfly](#install-mcfly)
    - [Install Docker](#install-docker)
    - [Install kubectl](#install-kubectl)
    - [Install kustomize](#install-kustomize)
    - [Install Helm](#install-helm)
    - [Install sops](#install-sops)
  - [Install ohmyzsh + plugins + powerlevel10k theme](#install-ohmyzsh--plugins--powerlevel10k-theme)
    - [Install ohmyzsh](#install-ohmyzsh)
    - [Install necessary ohmyzsh plugins](#install-necessary-ohmyzsh-plugins)
    - [Install powerlevel10k theme](#install-powerlevel10k-theme)
    - [Install fonts for powerlevel10k theme](#install-fonts-for-powerlevel10k)
  - [Install Krew](#install-krew)
  - [Install Dyff](#install-dyff)
  - [Install tenv](#install-tenv)
  - [Install Fabric](#install-fabric)

## Prerequisites

### macOS

#### Install homebrew package manager

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew doctor
```

#### Install latest zsh version

```bash
brew update
brew install zsh
chsh -s /usr/local/bin/zsh
exec zsh
```

#### Install development & productivity tools

```bash
brew install \
gnupg \
tree \
jq \
yq \
nvim \
bat \
eza \
fd \
ripgrep \
fzf \
tldr \
zoxide \
dust \
btop \
mcfly \
thefuck
kubectl \
kustomize \
helm \
age \
sops \
cosign \
tenv \
pre-commit
```

This is not a pre-requisite but is my essential stack for macOS

```bash
brew install --cask \
firefox \
cloudflare-warp \
1password \
keybase \
alacritty \
warp \
docker \
docker-compose \
raycast \
stats \
visual-studio-code \
cursor \
slack \
notion \
freelens \
flameshot
```

### Linux

#### Arch Linux

##### Install packages from pacman

```bash
sudo pacman -S zsh \
  gnupg \
  iptables \
  fail2ban \
  git \
  neovim \
  fontconfig \
  jq \
  yq \
  tree \
  age \
  bat \
  eza \
  fd \
  ripgrep \
  fzf \
  tlrc \
  zoxide \
  dust \
  btop \
  mcfly \
  thefuck \
  pre-commit
```

##### Set zsh as default shell

```bash
zsh --version
chsh -s $(which zsh)
exec zsh
```

#### Raspberry Pi OS

##### Install packages from apt

```bash
sudo apt update
sudo apt install -y zsh \
  apt-transport-https \
  iptables \
  fail2ban \
  git \
  neovim \
  fontconfig \
  jq \
  yq \
  tree \
  age \
  bat \
  fd-find \
  ripgrep \
  fzf \
  tldr \
  zoxide \
  btop \
  thefuck \
  pre-commit
```

##### Set zsh default shell

```bash
zsh --version
chsh -s $(which zsh)
exec zsh
```

##### Install eza

```bash
# Download the latest eza binar
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

# Install eza
sudo apt update
sudo apt install -y eza
```

##### Install dust

```bash
# Download the latest dust binary
ARCH=$(arch | sed 's|amd64|x86_64|g' | sed 's|arm64|aarch64|g')
DUST_VERSION=$(curl https://api.github.com/repos/bootandy/dust/releases/latest | jq -r .tag_name)
curl -LO "https://github.com/bootandy/dust/releases/download/${DUST_VERSION}/dust-${DUST_VERSION}-${ARCH}-unknown-linux-gnu.tar.gz"

# Extract the dust binary and move to /usr/local/bin
tar -xvzf "dust-${DUST_VERSION}-${ARCH}-unknown-linux-gnu.tar.gz"
sudo mv dust-${DUST_VERSION}-${ARCH}-unknown-linux-gnu/dust /usr/local/bin/
rm -r dust-${DUST_VERSION}-${ARCH}-unknown-linux-gnu*

# Verify installation
dust -V
```

##### Install mcfly

```bash
# Download the latest mcfly binary
ARCH=$(arch | sed 's|amd64|x86_64|g' | sed 's|arm64|aarch64|g')
MCFLY_VERSION=$(curl https://api.github.com/repos/cantino/mcfly/releases/latest | jq -r .tag_name)
curl -LO "https://github.com/cantino/mcfly/releases/download/${MCFLY_VERSION}/mcfly-${MCFLY_VERSION}-${ARCH}-unknown-linux-musl.tar.gz"

# Extract the dust binary and move to /usr/local/bin
tar -xvzf "mcfly-${MCFLY_VERSION}-${ARCH}-unknown-linux-musl.tar.gz"
sudo mv mcfly /usr/local/bin/
rm -r mcfly*

# Verify installation
mcfly -V
```

#### Install Docker

```bash
# Install Docker Engine
curl -sSL https://get.docker.com | sudo sh

# Add user to docker group
sudo groupadd docker
sudo usermod -aG docker ${USER}
newgrp docker

# Verify installation
docker --version
dockerd --version
```

#### Install kubectl

```bash
# Download the latest kubectl binary
ARCH=$(arch | sed 's|x86_64|amd64|g' | sed 's|aarch64|arm64|g')
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"

# Move the kubectl binary to /usr/local/bin
sudo mv kubectl /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

#### Install kustomize

```bash
# Download the latest kustomize binary
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Move the kustomize binary to /usr/local/bin
sudo mv kustomize /usr/local/bin/kustomize

# Verify installation
kustomize version
```

#### Install Helm

```bash
# Download the latest helm binary
ARCH=$(arch | sed 's|x86_64|amd64|g' | sed 's|aarch64|arm64|g')
HELM_VERSION=$(curl https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name)
curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz | tar zx

# Move the helm binary to /usr/local/bin
sudo mv linux-${ARCH}/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm
rm -rf linux-${ARCH}

# Verify installation
helm version
```

#### Install sops

```bash
# Download the latest sops binary
ARCH=$(arch | sed 's|x86_64|amd64|g' | sed 's|aarch64|arm64|g')
SOPS_VERSION=$(curl https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name)
curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCH}

# Move the sops binary to /usr/local/bin
sudo mv sops-${SOPS_VERSION}.linux.${ARCH} /usr/local/bin/sops
chmod +x /usr/local/bin/sops

# Verify installation
sops --version
```

### Install ohmyzsh + plugins + powerlevel10k theme

#### Install ohmyzsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### Install necessary ohmyzsh plugins

```bash
# Auto-suggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Syntax highlighting 
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-

# You should use
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
```

#### Install powerlevel10k theme

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

#### Install fonts for powerlevel10k

Install [MesloLGS NF Fonts](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts) - the recommended fonts patched for powerlevel10k.

##### MesloLGS NF Fonts for macOS

```bash
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
```

##### MesloLGS NF Fonts for Linux

[fontconfig](https://github.com/centricular/fontconfig) must be installed to use the MesloLGS NF Fonts.

```bash
# Create ~/.fonts directory
mkdir -p ~/.fonts 

# Download MesloLGS-NF-Regular.ttf
curl -o ~/.fonts/MesloLGS-NF-Regular.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf

# MesloLGS-NF-Bold.ttf
curl -o ~/.fonts/MesloLGS-NF-Bold.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf

# Download MesloLGS-NF-Italic.ttf
curl -o ~/.fonts/MesloLGS-NF-Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf

# Download MesloLGS-NF-Bold-Italic.ttf
curl -o ~/.fonts/MesloLGS-NF-Bold-Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf

# Scans and builds font information cache
fc-cache -fv

# Reload zsh configuration to apply font changes
source ~/.zshrc
```

### Install Krew

[Krew](https://github.com/kubernetes-sigs/krew) is a package manager to find and install [kubectl plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/). Krew helps you discover plugins, install and manage them on your machine. It is similar to tools like apt, dnf or [brew](https://brew.sh/). Today, over [200 kubectl plugins](https://krew.sigs.k8s.io/plugins/) are available on Krew.

```bash
# Install krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# Add krew to PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Install krew base plugins
kubectl krew install ctx
kubectl krew install ns
kubectl krew install stern
```

### Install Dyff

[Dyff](https://github.com/homeport/dyff) is an open-source diff tool for YAML files, and sometimes JSON. Similar to the standard diff tool, it follows the principle of describing the change by going from the from input file to the target to input file. [Use cases](https://github.com/homeport/dyff?tab=readme-ov-file#use-cases-and-examples)

```bash
curl --silent --location https://git.io/JYfAY | sudo bash
```

### Install tenv

[tenv](https://github.com/tofuutils/tenv) is a versatile version manager for OpenTofu, Terraform, Terragrunt, Terramate and Atmos, written in Go. Tenv is a successor of [tofuenv](https://github.com/tofuutils/tofuenv) and [tfenv](https://github.com/tfutils/tfenv).

```bash
# macOS
brew install cosign tenv
```

```bash
# Download the latest cosign binary required for tenv
ARCH=$(arch | sed 's|x86_64|amd64|g' | sed 's|aarch64|arm64|g')
COSIGN_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name)
curl -O -L "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${ARCH}"

# Move the cosign binary to /usr/local/bin
sudo mv "cosign-linux-${ARCH}" /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Verify installation
cosign version

# Download the latest tenv binary
ARCH=$(arch | sed 's|x86_64|amd64|g' | sed 's|aarch64|arm64|g')
TENV_VERSION=$(curl --silent https://api.github.com/repos/tofuutils/tenv/releases/latest | jq -r .tag_name)
curl -LO "https://github.com/tofuutils/tenv/releases/download/${TENV_VERSION}/tenv_${TENV_VERSION}_linux_${ARCH}.tar.gz"
tar -xzf "tenv_${TENV_VERSION}_linux_${ARCH}.tar.gz" tenv
rm "tenv_${TENV_VERSION}_linux_${ARCH}.tar.gz"

# Move the tenv binary to /usr/local/bin
sudo mv tenv /usr/local/bin/tenv

# Install tenv completion for ohmyzsh
mkdir -p ~/.oh-my-zsh/completions
tenv completion zsh > ~/.oh-my-zsh/completions/_tenv
```

### Install Fabric

[Fabric](https://github.com/danielmiessler/Fabric) is an open-source framework for augmenting humans using AI. It provides a modular system for solving specific problems using a crowdsourced set of AI prompts that can be used anywhere.

Using Homebrew or the Arch Linux package managers makes fabric available as **fabric-ai**.

```bash
# macOS
brew install fabric-ai
```

```bash
# Arch Linux (amd64)
curl -L https://github.com/danielmiessler/fabric/releases/latest/download/fabric-linux-amd64 > fabric && chmod +x fabric && sudo mv fabric /usr/local/bin/fabric && fabric --version

# Raspberry Pi OS (arm64)
curl -L https://github.com/danielmiessler/fabric/releases/latest/download/fabric-linux-arm64 > fabric && chmod +x fabric && sudo mv fabric /usr/local/bin/fabric && fabric --version
```

```bash
# Setup Fabric plugins and api keys.
fabric --setup
```
