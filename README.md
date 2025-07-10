# Dotfiles with GNU Stow

## Introduction

This repository manages your configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/).

## TODO

- [ ] Install and redefine Linux prerequisites.
- [ ] Migrate macOS prerequisites to brew bundle and Brewfile ([docs](https://docs.brew.sh/Brew-Bundle-and-Brewfile)).
- [ ] Automation scripts for macOS.
- [ ] Automation scripts for Linux.
- [ ] Implement Github Actions to lint Markdown and packages.
- [ ] Review project with [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles).

## Table of Contents

- [Introduction](#introduction)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
  - [macOS](#macos)
    - [Install homebrew package manager](#install-homebrew-package-manager)
    - [Install latest zsh version](#install-latest-zsh-version)
    - [Install development & productivity tools](#install-development--productivity-tools)
    - [Install must-have CLI Tools](#install-must-have-cli-tools)
  - [Linux](#linux)
    - [Arch Linux](#arch-linux)
      - [Install zsh and set as default shell](#install-zsh-and-set-as-default-shell)
    - [Raspberry Pi OS](#raspberry-pi-os)
      - [Install zsh and set as default shell](#install-zsh-and-set-as-default-shell)
      - [Install packages from apt](#install-basic-packages-from-apt)
    - [Install Docker](#install-docker)
    - [Install kubectl](#install-kubectl)
    - [Install kustomize](#install-kustomize)
    - [Install Helm](#install-helm)
  - [Install ohmyzsh + plugins + powerlevel10k theme](#install-ohmyzsh--plugins--powerlevel10k-theme)
    - [Install ohmyzsh](#install-ohmyzsh)
    - [Install necessary ohmyzsh plugins](#install-necessary-ohmyzsh-plugins)
    - [Install powerlevel10k theme](#install-powerlevel10k-theme)
    - [Install fonts for powerlevel10k theme](#install-fonts-for-powerlevel10k)
  - [Install Krew](#install-krew)
  - [Install Dyff](#install-dyff)
  - [Install Fabric](#install-fabric)
- [Install GNU Stow](#install-gnu-stow)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
  - [Clone this repo](#clone-this-repo)
  - [Stow a package](#stow-a-package)
  - [Unstow (remove symlinks)](#unstow-remove-symlinks)
- [Tips](#tips)
- [More Info](#more-info)

## Prerequisites

### macOS

#### Install homebrew package manager

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Install latest zsh version

```bash
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
pre-commit \
nvim \
kubectl \
kustomize \
helm \
age \
sops \
tenv
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
clipy \
raycast \
stats \
visual-studio-code \
cursor \
slack \
docker \
freelens \
flameshot
```

#### Install must-have CLI Tools

- [bat](https://github.com/sharkdp/bat): A cat replacement with syntax highlighting.
- [eza](https://github.com/eza-community/eza): A modern ls with colors and Git info ([exa](https://github.com/ogham/exa) fork).
- [fd](https://github.com/sharkdp/fd): An fastest alternative to the find command.
- [ripgrep](https://github.com/BurntSushi/ripgrep): An fastest alternative to the grep command.
- [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder.
- [tldr](https://github.com/tldr-pages/tldr): Collaborative cheatsheets for console commands.
- [zoxide](https://github.com/ajeetdsouza/zoxide): A smarter cd command. Supports all major shells.
- [dust](https://github.com/bootandy/dust): A more intuitive version of du in rust.
- [btop](https://github.com/aristocratos/btop): Like htop but best.
- [mcfly](https://github.com/cantino/mcfly): Fly through your shell history.
- [thefuck](https://github.com/nvbn/thefuck): Corrects your previous command. (Just type fuck)

```bash
brew install \
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
```

### Linux

#### Arch Linux

##### Install zsh and set as default shell

```bash
sudo pacman -S zsh
zsh --version
chsh -s $(which zsh)
exec zsh
```

#### Raspberry Pi OS

##### Install packages from apt

```bash
sudo apt update
sudo apt install -y \
  zsh \
  apt-transport-https \
  iptables \
  git \
  neovim \
  jq \
  yq \
  tree \
  age \
  tenv
```

##### Set zsh as default shell

```bash
zsh --version
chsh -s $(which zsh)
exec zsh
```

#### Install Docker

```bash
# Download the latest Docker Engine static binary (iptables is required for Docker networking)
ARCH=$(arch | sed 's/x86_64/amd64/' | sed 's/aarch64/aarch64/')
DOCKER_VERSION=$(curl -s https://download.docker.com/linux/static/stable/${ARCH}/ | grep -oP 'docker-\K([0-9.]+)(?=\.tgz)' | sort -V | tail -n1)
curl -LO "https://download.docker.com/linux/static/stable/${ARCH}/docker-${DOCKER_VERSION}.tgz"
tar xzvf docker-${DOCKER_VERSION}.tgz

# Move the Docker binaries to /usr/local/bin
sudo mv docker/* /usr/local/bin/

# Add user to docker group
sudo groupadd docker
sudo usermod -aG docker $USER
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

#### Install tenv

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

# Verify installation
tenv version
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

```bash
# Install fontconfig
sudo apt install fontconfig # Raspberry Pi OS
sudo pacman -S fontconfig # Arch Linux

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

# Install krew base plugins
kubectl krew install ctx
kubectl krew install ns
kubectl krew install get-all
kubectl krew install stern
```

### Install Dyff

[Dyff](https://github.com/homeport/dyff) is an open-source diff tool for YAML files, and sometimes JSON. Similar to the standard diff tool, it follows the principle of describing the change by going from the from input file to the target to input file. [Use cases](https://github.com/homeport/dyff?tab=readme-ov-file#use-cases-and-examples)

```bash
curl --silent --location https://git.io/JYfAY | bash
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
curl -L https://github.com/danielmiessler/fabric/releases/latest/download/fabric-linux-amd64 > fabric && chmod +x fabric && ./fabric --version

# Raspberry Pi OS (arm64)
curl -L https://github.com/danielmiessler/fabric/releases/latest/download/fabric-linux-arm64 > fabric && chmod +x fabric && ./fabric --version
```

```bash
# Setup Fabric plugins and api keys.
fabric --setup
```

## Install GNU Stow

```bash
# macOS
brew install stow

# Arch Linux
sudo pacman -S stow

# Raspberry Pi OS
sudo apt install stow 
```

## Directory Structure

Organize your dotfiles in subdirectories named after each application. For example:

```bash
dotfiles/
├── alacritty
│   └── .config
│       └── alacritty
│           └── alacritty.toml
├── p10k
│   └── .p10k.zsh
└── zsh
    ├── .zsh
    │   └── completions
    │       ├── _kubectl
    │       └── _fabric
    └── .zshrc
```

## Usage

### Clone this repo

```bash
git clone https://github.com/feder1c0/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Stow a package

```bash
stow zsh
stow alacritty
stow p10k
```

This will symlink the files into your home directory.

### Unstow (remove symlinks)

```bash
stow -D zsh
```

or full remove

```bash
stow -D .
```

## Tips

- Only stow the packages you need.
- Edit files in this repo, not in your home directory.

## More Info

See [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html).
