# Dotfiles with GNU Stow

## Introduction

This repository manages my configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/). These are the base dotfiles I start with when setting up a new environment in macOS, Arch Linux and Raspberry Pi OS.

## TODO

- [x] Install and redefine Linux prerequisites.
- [x] Complete main README.md with prerequisites references.
- [ ] Migrate macOS prerequisites to brew bundle and Brewfile ([docs](https://docs.brew.sh/Brew-Bundle-and-Brewfile)).
- [ ] Automation scripts for macOS.
- [ ] Automation scripts for Linux.
- [ ] Implement Github Actions to lint Markdown and packages vulnerabilities.

## Table of Contents

- [Introduction](#introduction)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Install GNU Stow](#install-gnu-stow)
  - [Directory Structure](#directory-structure)
  - [Clone this repo](#clone-this-repo)
  - [Stow a package](#stow-a-package)
  - [Unstow (remove symlinks)](#unstow-remove-symlinks)
- [Tips](#tips)
- [More Info](#more-info)

## Prerequisites

To utilize this zsh configuration with oh-my-zsh, ensure that you have zsh, git, wget and curl installed on your system. These tools are required to clone this repository and initialize the recommended base setup.

### Essential packages

- [zsh](https://github.com/zsh-users/zsh): A shell designed for interactive use.
- [curl](https://curl.se/): A command-line tool for transferring data with URLs.
- [wget](https://www.gnu.org/software/wget/): A free utility for non
- [git](https://github.com/git/git): A fast, scalable, distributed revision control system.
- [gnupg](https://gnupg.org/): A tool for secure communication and data protection.


### Ohmyzsh + powerlevel10k theme

- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh): An community-driven framework for managing zsh configuration
- [powerlevel10k](https://github.com/romkatv/powerlevel10k): A powerful theme for zsh and oh-my-zsh.
- [fontconfig](https://github.com/centricular/fontconfig): A library for font customization and configuration.

For a comprehensive list of recommended packages, tools, and detailed installation instructions for shell prerequisites on each supported operating system, refer to [zsh/README.md](zsh/README.md).

## Usage

### Install GNU Stow

Stow is a symlink farm manager that can make the system believe our dotfiles are placed in the same home directory.

```bash
# macOS
brew install stow

# Arch Linux (you can use yay instead of pacman)
sudo pacman -S stow

# Raspberry Pi OS
sudo apt install stow 
```

### Directory Structure

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
