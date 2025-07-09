# Dotfiles with GNU Stow

This repository manages your configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

### macOS

#### Install latest zsh version

```bash
brew install zsh
chsh -s /usr/local/bin/zsh
exec zsh
```

#### Install Homebrew package manager

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Install development & productivity tools

```bash
brew install \
gnupg \
tree \
jq \
yq \
pre-commit \
alacritty \
nvim \
kubectl \
kustomize \
helm \
tenv
```

```bash
brew install --cask \
alacritty \
warp \
stats \
visual-studio-code \
slack \
docker \
freelens \
flameshot
```

#### Install must-to-have Command Line Tools

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

#### Install zsh-autosuggestions ohmyzsh plugin

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

#### Install zsh-syntax-highlighting ohmyzsh plugin

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### Install zsh-you-should-use plugin

```bash
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
```

#### Install powerlevel10k theme

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

#### Install fonts for powerlevel10k

Install [MesloLGS NF Fonts](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts) - the recommended fonts patched for powerlevel10k.

##### for macOS

```bash
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
```

##### for Linux

```bash
sudo apt install fontconfig \
mkdir -p ~/.fonts 
```

```bash
curl -o ~/.fonts/MesloLGS-NF-Regular.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf
```

```bash
curl -o ~/.fonts/MesloLGS-NF-Bold.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf
```

```bash
curl -o ~/.fonts/MesloLGS-NF-Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf
```

```bash
curl -o ~/.fonts/MesloLGS-NF-Bold-Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf
```

```bash
fc-cache -fv \
source ~/.zshrc
```

### Install Krew kubernetes plugin manager

[Krew](https://github.com/kubernetes-sigs/krew) is a kubernetes plugin manager for kubectl command-line tool.

#### Install krew

```bash
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
```

#### Install krew base plugins

```bash
kubectl krew install ctx
kubectl krew install ns
kubectl krew install get-all
kubectl krew install stern
```

### Install Fabric (fabric-ai)

[Fabric](https://github.com/danielmiessler/Fabric) is an open-source framework for augmenting humans using AI.

#### Install Fabric

```bash
brew install fabric-ai
```

#### Setup Fabric

Run the setup to set up required plugins and api keys.

```bash
fabric --setup
```

## Install GNU Stow

```bash
brew install stow # macOS
sudo apt install stow # Ubuntu / Raspbian
sudo pacman -S stow # Arch / Manjaro
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
    │       └── fabric_
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
