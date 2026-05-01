# zsh

Stow package: `.zshrc`, `.p10k.zsh`, custom scripts, and `.zsh/` config glob.

## Layout

```
zsh/
├── .zshrc                       # entry; glob-sources ~/.zsh/*.zsh
├── .p10k.zsh                    # Powerlevel10k config
└── .zsh/
    ├── aliases.zsh              # aliases
    ├── config.zsh               # env + tool init (guarded by $+commands[X])
    └── scripts/                 # CLI utilities (not auto-sourced)
        ├── brew-update.sh       # alias: bu
        ├── git-branch-cleanup.sh  # alias: gbc
        └── lib/                 # reusable shell libraries
```

## Install

Provisioned by `install.sh` (see [`docs/install.md`](../docs/install.md)). For manual stow:

```bash
cd ~/dotfiles && stow zsh
```

OMZ + Powerlevel10k + plugins are installed by `install.sh` after stow with `KEEP_ZSHRC=yes`. Manual install order is documented in [`docs/install.md`](../docs/install.md).

## Packages

CLI tools, fonts, and DevOps tooling: see [`docs/packages.md`](../docs/packages.md).

## Scripts

`brew-update.sh`, `git-branch-cleanup.sh`, and shared libraries: see [`.zsh/scripts/README.md`](.zsh/scripts/README.md).

## Conventions

- Edit in repo (`~/dotfiles/zsh/`), never the symlinked target.
- Add new config files to `.zsh/` — `.zshrc` glob-sources them in alphabetical order.
- Tool init guarded by `(( $+commands[X] ))` to keep config portable across machines without that tool installed.
