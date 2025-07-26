# Zsh Setup and Configuration

This README provides comprehensive setup instructions for configuring a powerful terminal environment based on [Zsh](https://www.zsh.org/) with [Oh My Zsh](https://ohmyz.sh/) framework and the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. It includes installation guides for essential CLI tools, development utilities, and productivity applications of my daily workflow.

The guide covers setup procedures for multiple operating systems, including macOS, Arch Linux, and Raspberry Pi OS, with package managers to streamline the setup process and automated installation scripts. Whether you're setting up a new development environment or improving your terminal setup, this documentation will help you create a powerful and efficient command-line environment that enhances productivity and simplifies development workflows.

Note: This guide is tailored to my personal preferences and may not suit everyone's needs. Feel free to adapt the instructions to your own requirements.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
  - [macOS](#macos)
    - [Install homebrew package manager](#install-homebrew-package-manager)
    - [Install packages from Brewfile](#install-packages-from-brewfile)
  - [Arch Linux](#arch-linux)
    - [Install packages from pacman](#install-packages-from-pacman)
    - [Set zsh as default shell](#set-zsh-as-default-shell)
  - [Raspberry Pi OS](#raspberry-pi-os)
    - [Install packages from apt](#install-packages-from-apt)
    - [Set zsh as default shell](#set-zsh-as-default-shell)
    - [Install eza](#install-eza)
    - [Install dust](#install-dust)
    - [Install mcfly](#install-mcfly)
  - [Linux from source](#linux-from-source)
    - [Install fnm](#install-fnm)
    - [Install pyenv](#install-pyenv)
    - [Install Docker](#install-docker)
    - [Install kubectl](#install-kubectl)
    - [Install kustomize](#install-kustomize)
    - [Install Helm](#install-helm)
    - [Install sops](#install-sops)
    - [Install Krew](#install-krew)
    - [Install Dyff](#install-dyff)
    - [Install tenv](#install-tenv)
    - [Install Fabric](#install-fabric)
- [Install Oh My Zsh + Powerlevel10k](#install-oh-my-zsh--powerlevel10k)
  - [Install Oh My Zsh](#install-oh-my-zsh)
  - [Install Powerlevel10k theme](#install-powerlevel10k-theme)

## Prerequisites

This is a list of packages and tools that are part of my daily use in the command line terminal and development environments in my personal setup.

### Essential packages

- [zsh](https://github.com/zsh-users/zsh): A shell designed for interactive use.
- [curl](https://curl.se/): A command-line tool for transferring data with URLs.
- [wget](https://www.gnu.org/software/wget/): A free utility for non-interactive download of files from the web.
- [git](https://github.com/git/git): A fast, scalable, distributed revision control system.
- [gnupg](https://gnupg.org/): A tool for secure communication and data protection.

### Oh My Zsh + Powerlevel10k theme

- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh): An community-driven framework for managing zsh configuration
- [powerlevel10k](https://github.com/romkatv/powerlevel10k): A powerful theme for zsh and oh-my-zsh.
- [fontconfig](https://github.com/centricular/fontconfig): A library for font customization and configuration.
- [MesloLGS NF Fonts](https://github.com/romkatv/powerlevel10k#fonts): A patched font for powerlevel10k theme.

### Must-have CLI tools

- [neovim](https://github.com/neovim/neovim): A modern, hackable, and extensible text editor.
- [jq](https://github.com/stedolan/jq): A lightweight and flexible command-line JSON processor.
- [yq](https://github.com/mikefarah/yq): A lightweight and flexible command-line YAML processor.
- [tree](https://github.com/git-guides/install-git): A tool to display directories as trees.
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

### Recommended tools (optional)

- [docker](https://github.com/docker/docker): A tool to manage Docker containers.
- [docker-compose](https://github.com/docker/compose): A tool to manage Docker Compose.
- [kubectl](https://github.com/kubernetes/kubectl): The Kubernetes command-line tool.
- [kustomize](https://github.com/kubernetes-sigs/kustomize): A tool for customizing Kubernetes YAML configurations.
- [helm](https://github.com/helm/helm): The Kubernetes package manager.
- [age](https://github.com/FiloSottile/age): A simple, modern and secure file encryption tool.
- [sops](https://github.com/getsops/sops): A tool to encrypt and decrypt files with ease.
- [pre-commit](https://github.com/pre-commit/pre-commit): A framework for managing and maintaining multi-language pre-commit hooks.
- [krew](https://github.com/kubernetes-sigs/krew): A tool to manage kubectl plugins.
- [dyff](https://github.com/homeport/dyff): A tool to diff YAML files.
- [cosign](https://github.com/sigstore/cosign): Code signing and transparency for containers and binaries
- [tenv](https://github.com/tofuutils/tenv): A tool to manage Terraform versions.
- [fnm](https://github.com/Schniz/fnm): A tool to manage Node.js versions.
- [pyenv](https://github.com/pyenv/pyenv): A tool to manage Python versions.
- [fabric](https://github.com/danielmiessler/Fabric): A tool to augment humans using AI.

</br>

---

### macOS

#### Install homebrew package manager

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew doctor
```

#### Install packages from Brewfile

Into the [Brewfile](../Brewfile) you can find a list of packages and tools that I use in my daily work.
You can install them using the following command:

```bash
# Install packages and dependencies from Brewfile
brew bundle install --file=Brewfile

# Verify installations
brew list
```

ZSH is already installed on macOS and is the default shell. You can verify the version of zsh installed by running:

```bash
zsh --version
```

</br>

---

### Arch Linux

#### Install packages from pacman

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
  ghostty \
  pre-commit
```

##### Set zsh as default shell

```bash
zsh --version
chsh -s $(which zsh)
exec zsh
```

</br>

---

### Raspberry Pi OS

#### Install packages from apt

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

#### Set zsh default shell

```bash
zsh --version
chsh -s $(which zsh)
exec zsh
```

#### Install eza

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

#### Install dust

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

#### Install mcfly

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

</br>

---

### Linux from source

#### Install fnm

[FNM](https://github.com/Schniz/fnm) is a fast and simple Node.js version manager. It allows you to easily switch between Node.js versions and manage your development environment. Install fnm was really simple. I ran the following command to get it up and running:

```bash
# Linux
curl -fsSL https://fnm.vercel.app/install | bash

eval "$(fnm env - use-on-cd - shell zsh)" 
```

#### Install pyenv

[Pyenv](https://github.com/pyenv/pyenv) is a simple Python version management tool. It allows you to easily switch between multiple versions of Python.

```bash
# Linux
curl https://pyenv.run | bash
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

#### Install Krew

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

#### Install Dyff

[Dyff](https://github.com/homeport/dyff) is an open-source diff tool for YAML files, and sometimes JSON. Similar to the standard diff tool, it follows the principle of describing the change by going from the from input file to the target to input file. [Use cases](https://github.com/homeport/dyff?tab=readme-ov-file#use-cases-and-examples)

```bash
curl --silent --location https://git.io/JYfAY | sudo bash
```

#### Install tenv

[tenv](https://github.com/tofuutils/tenv) is a versatile version manager for OpenTofu, Terraform, Terragrunt, Terramate and Atmos, written in Go. Tenv is a successor of [tofuenv](https://github.com/tofuutils/tofuenv) and [tfenv](https://github.com/tfutils/tfenv).

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

#### Install Fabric

[Fabric](https://github.com/danielmiessler/Fabric) is an open-source framework for augmenting humans using AI. It provides a modular system for solving specific problems using a crowdsourced set of AI prompts that can be used anywhere.

Using Homebrew or the Arch Linux package managers makes fabric available as **fabric-ai**.

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

## Install Oh My Zsh + Powerlevel10k

[Oh My Zsh](https://ohmyz.sh/) is a community-driven framework for managing your zsh configuration. It comes with a lot of plugins and themes that can enhance your terminal experience. [Powerlevel10k](https://github.com/romkatv/powerlevel10k) is a theme for Oh My Zsh that provides a beautiful and informative prompt.

### Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### Install Oh My Zsh plugins

```bash
# Auto-suggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Syntax highlighting 
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-

# You should use
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
```

### Install Powerlevel10k theme

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

#### Install fonts for Powerlevel10k

Install [MesloLGS NF Fonts](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts) - the recommended fonts patched for Powerlevel10k.

```bash
# macOS
brew install --cask font-meslo-lg-nerd-font
```

for Linux distributions [fontconfig](https://github.com/centricular/fontconfig) must be installed to use the MesloLGS NF Fonts.

```bash
# Linux

# Create fonts directory
mkdir -p ~/.fonts 

# Download MesloLGS NF Fonts
curl -o ~/.fonts/MesloLGS-NF-Regular.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf
curl -o ~/.fonts/MesloLGS-NF-Bold.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf
curl -o ~/.fonts/MesloLGS-NF-Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf
curl -o ~/.fonts/MesloLGS-NF-Bold-Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf

# Scans and builds font information cache
fc-cache -fv

# Reload zsh configuration to apply font changes
source ~/.zshrc
```

## Notes

- After installing the packages and tools, you may need to restart your terminal or run `source ~/.zshrc` to apply the changes.
- Make sure to customize your `.zshrc` file according to your preferences and the tools you have installed.
- For any issues or suggestions, please feel free to open an issue on the [GitHub repository](https://github.com/feder1c0/dotfiles/issues).
