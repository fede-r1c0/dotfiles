# Dotfiles with GNU Stow

## Introduction

This repository manages my configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/). These are the base dotfiles I start with when setting up a new environment in macOS, Arch Linux and Raspberry Pi OS.

## Table of Contents

- [Introduction](#introduction)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Install GNU Stow](#install-gnu-stow)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
  - [Clone this repo](#clone-this-repo)
  - [Stow a package](#stow-a-package)
  - [Unstow (remove symlinks)](#unstow-remove-symlinks)
- [Tips](#tips)
- [More Info](#more-info)

## Prerequisites

Essential packages:

- [zsh](https://github.com/zsh-users/zsh): A shell designed for interactive use.
- [gnupg](https://gnupg.org/): A tool for secure communication and data protection.
- [git](https://github.com/git/git): A fast, scalable, distributed revision control system.
- [neovim](https://github.com/neovim/neovim): A modern, hackable, and extensible text editor.
- [fontconfig](https://github.com/centricular/fontconfig): A library for font customization and configuration.

Must-have CLI tools:

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

Ohmyzsh + powerlevel10k theme

- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh): An community-driven framework for managing zsh configuration
- [powerlevel10k](https://github.com/romkatv/powerlevel10k): A powerful theme for zsh and oh-my-zsh.

Essential work tools (optional):

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
- [fabric](https://github.com/danielmiessler/Fabric): A tool to augment humans using AI.

## Install GNU Stow

Stow is a symlink farm manager that can make the system believe our dotfiles are placed in the same home directory.

```bash
# macOS
brew install stow

# Arch Linux (you can use yay instead of pacman)
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
├── i3
│   └── .config
│       └── i3
│           ├── config
│           └── i3status.conf
└── zsh
    └── .zshrc
```

## Usage

### Clone this repo

```bash
git clone https://github.com/feder1c0/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Stow a package

By default the "stow" command will create a symbolic link from the contents of the directory to the home (~) directory.

```bash
stow zsh # this will symlink the zsh files into your home directory
```

It is also possible to declare a specific target path to stow

```bash
stow folder -t target_path # this will symlink the files into the target path
```

### Unstow (remove symlinks)

This will remove the symlinks from the home directory.

```bash
stow -D zsh
```

To remove all symlinks, you can use the following command:

```bash
stow -D .
```

## Tips

- Only stow the packages you need.
- Edit files in this repo, not in your home directory.

## More Info

See [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html).
