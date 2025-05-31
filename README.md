# Dotfiles with GNU Stow

This repository manages your configuration files (dotfiles) using [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

Install GNU Stow:

```bash
brew install stow   # macOS
yay -S stow   # Arch Linux
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

1. **Clone this repo:**

```bash
git clone https://github.com/feder1c0/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. **Stow a package:**

```bash
stow zsh
stow alacritty
stow p10k
```

This will symlink the files into your home directory.

3. **Unstow (remove symlinks):**

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