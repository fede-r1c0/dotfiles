# Dotfiles with GNU Stow

This repository manages your configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/).

TODO:
    - Add Linux prerequisites
    - Migrate to brew bundle and Brewfile [https://docs.brew.sh/Brew-Bundle-and-Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
    - Automation script for macOS
    - Automation script for Linux
    - Github Actions lint Markdown an Shell [https://github.com/alrra/dotfiles](https://github.com/alrra/dotfiles)
    - Review projet with [https://github.com/webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)

## Table of Contents

- [Dotfiles with GNU Stow](#dotfiles-with-gnu-stow)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
  - [macOS](#macos)
    - [Install homebrew package manager](#install-homebrew-package-manager)
    - [Install latest zsh version](#install-latest-zsh-version)
    - [Install development & productivity tools](#install-development--productivity-tools)
    - [Install must-have CLI Tools](#install-must-have-cli-tools)
  - [Linux](#linux)
    - [Install zsh and set as default shell](#install-zsh-and-set-as-default-shell)
  - [Install ohmyzsh + plugins + powerlevel10k theme](#install-ohmyzsh--plugins--powerlevel10k-theme)
    - [Install ohmyzsh](#install-ohmyzsh)
    - [Install necessary ohmyzsh plugins](#install-necessary-ohmyzsh-plugins)
    - [Install powerlevel10k theme](#install-powerlevel10k-theme)
    - [Install fonts for powerlevel10k theme](#install-fonts-for-powerlevel10k)
      - [MesloLGS NF Fonts for macOS](#meslolgs-nf-fonts-for-macos)
      - [MesloLGS NF Fonts for Linux](#meslolgs-nf-fonts-for-linux)
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

#### Install zsh and set as default shell

```bash
# Ubuntu / Raspbian
sudo apt install zsh
zsh --version
chsh -s $(which zsh)
exec zsh
```

```bash
# Arch / Manjaro
sudo pacman -S zsh
zsh --version
chsh -s $(which zsh)
exec zsh
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
sudo apt install fontconfig # Ubuntu / Raspbian
sudo pacman -S fontconfig # Arch / Manjaro

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
# for Linux or macOS (you need curl and jq installed)
curl --silent --location https://git.io/JYfAY | bash
```

### Install Fabric

[Fabric](https://github.com/danielmiessler/Fabric) is an open-source framework for augmenting humans using AI. It provides a modular system for solving specific problems using a crowdsourced set of AI prompts that can be used anywhere.

Using Homebrew or the Arch Linux package managers makes fabric available as **fabric-ai**.

```bash
# macOS

brew install fabric-ai

# Linux (arm64)

curl -L https://github.com/danielmiessler/fabric/releases/latest/download/fabric-linux-arm64 > fabric && chmod +x fabric && ./fabric --version

# Linux (amd64)

curl -L https://github.com/danielmiessler/fabric/releases/latest/download/fabric-linux-amd64 > fabric && chmod +x fabric && ./fabric --version

# Run the setup to set up required plugins and api keys.
fabric --setup
```

## Install GNU Stow

```bash
# macOS
brew install stow

# Ubuntu / Raspbian
sudo apt install stow 

# Arch / Manjaro
sudo pacman -S stow
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
