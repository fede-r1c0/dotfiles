# Dotfiles with GNU Stow

## Introduction

This repository manages my configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/). These are the base dotfiles I start with when setting up a new environment in macOS, Arch Linux and Raspberry Pi OS.

## TODO

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

To utilize the [Zsh](https://www.zsh.org/) configuration with [Oh My Zsh](https://ohmyz.sh/), framework and the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme you need to have zsh, git, wget and curl installed on your system.

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
- [MesloLGS NF Fonts](https://github.com/romkatv/powerlevel10k#fonts): A patched font for powerlevel10k theme.

For a comprehensive list of recommended packages, tools, and detailed setup instructions for shell prerequisites for multiple OS, including macOS, Arch Linux, and Raspberry Pi OS, read the [zsh/README.md](zsh/README.md) file in this repository.

## Usage

### Install GNU Stow

Stow is a symlink farm manager that can make the system believe our dotfiles are placed in the same home directory.

Install GNU Stow using your package manager.

```bash
# macOS
brew install stow

# Arch Linux (you can use yay instead of pacman)
sudo pacman -S stow

# Raspberry Pi OS
sudo apt install stow 
```

### Clone this repo

```bash
git clone https://github.com/feder1c0/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Directory Structure

Each directory in this repository represents a "package" that can be stowed independently. The structure within each package directory mirrors where the files should be placed in your home directory.

**How GNU Stow interprets the structure:**

- The top-level directories (`alacritty`, `i3`, `zsh`) are package names
- Everything inside a package directory represents the target structure relative to your home directory
- Files and folders are symlinked exactly as they appear in the package (even if they are nested)

**Examples:**

```bash
dotfiles/
├── alacritty
│   └── .config
│       └── alacritty
│           └── alacritty.toml → `~/.config/alacritty/alacritty.toml` (preserves nested structure)
├── i3
│   └── .config
│       └── i3
│           ├── config → `~/.config/i3/config` (creates subdirectories as needed)
│           └── i3status.conf → `~/.config/i3/i3status.conf`
└── zsh
    └── .zshrc → `~/.zshrc` (file goes directly in home)
```

### Stow a package

When you stow a package, GNU Stow creates symlinks from your home `~` to the files in the package directory, to stow a package run the `stow` command with the package name. </br>
Example, to stow the `zsh` package:

```bash
stow zsh
```

### Unstow a package

To remove a package symlink (unstow), use the `stow` command with the `-D` flag. </br>
Example, to remove the `zsh` package symlinks:

```bash
stow -D zsh
```

To remove all packages symlinks, use the `-D` flag with a dot (`.`) to indicate the current directory:

```bash
stow -D .
```

## Tips

- Backup your configuration files before using Stow, just in case.
- Only stow the packages you need.
- Edit files in this repo, not in your home directory.

## More Info

See [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html).
