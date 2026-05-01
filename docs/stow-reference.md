# Stow Reference

GNU Stow is a symlink farm manager. It turns a directory of packages into symlinks under `$HOME` (or any target directory).

## Mental model

```
~/dotfiles/
├── zsh/
│   └── .zshrc          ── stow zsh ──→  ~/.zshrc → ~/dotfiles/zsh/.zshrc
└── tmux/
    └── .tmux.conf      ── stow tmux ─→  ~/.tmux.conf → ~/dotfiles/tmux/.tmux.conf
```

Each top-level directory is a Stow package. Files inside mirror the target structure.

## Core commands

```bash
cd ~/dotfiles

# Install (create symlinks)
stow zsh

# Reinstall (remove + add — useful after adding files to a package)
stow -R zsh

# Uninstall (remove symlinks; repo untouched)
stow -D zsh

# Multi-package in one invocation
stow zsh tmux ghostty

# Verbose (see every link operation)
stow -v zsh
```

## Preview (simulate / check conflicts)

Stow has no native `--list-all` or `--check-conflicts`. Equivalents:

### List packages

```bash
ls -d ~/dotfiles/*/ | xargs -n1 basename
```

### Simulate (preview without mutations)

```bash
cd ~/dotfiles
stow --simulate -v zsh

# Empty output → already stowed or no-op.
# WARNING / ERROR → conflict.
```

### Detect conflicts

```bash
cd ~/dotfiles
stow --simulate zsh 2>&1 | grep -iE "warning|error|conflict"
```

## Conflicts

Typical case: `~/.zshrc` exists as a regular file (not a symlink) and you want to stow `zsh/`.

```
WARNING: existing target is neither a link nor a directory: .zshrc
All operations aborted.
```

### Resolutions

**1. Manual backup + retry**

```bash
mv ~/.zshrc ~/.zshrc.bak
cd ~/dotfiles && stow zsh
diff ~/.zshrc ~/.zshrc.bak  # verify content
```

**2. `--adopt` (powerful but destructive)**

```bash
cd ~/dotfiles
stow --adopt zsh
```

`--adopt` moves the target file **into** the package, overwriting the repo version. **Always inspect with `git diff` immediately** and revert if it clobbered anything important:

```bash
cd ~/dotfiles
git diff zsh/
git checkout -- zsh/  # revert if --adopt overwrote valuable content
```

`install.sh` falls back to `--adopt` automatically when conflicts are detected. The pre-stow backup phase ensures a recoverable copy exists.

**3. Force unstow + re-stow**

```bash
stow -D zsh        # remove existing symlinks
mv ~/.zshrc ~/.zshrc.old
stow zsh
```

## Tree folding

Stow folds directories by default — it symlinks the entire dir when all contents belong to the package. Disable when the target dir must remain real (e.g. `.config/` shared by multiple tools):

```bash
stow --no-folding ghostty
```

Creates per-file symlinks instead of a single dir-level link.

## `.stow-local-ignore`

Per-package regex ignore list. Place at the package root:

```
# zsh/.stow-local-ignore
\.DS_Store
\.swp$
README.*
.*\.bak$
```

Useful to keep `README.md` out of the linked tree.

> **Note**: this repo also ships a top-level `.stow-local-ignore` that protects non-stow paths (`scripts/`, `packages/`, `docs/`, etc.) when running `stow .` from the repo root.

## Best practices

- ✅ Always edit in the repo (`~/dotfiles/zsh/.zshrc`), never the target (`~/.zshrc`).
- ✅ Re-stow after structural changes (`stow -R PKG`) — adding or removing files.
- ✅ Simulate before stowing on a new machine — surface conflicts up front.
- ✅ Keep secrets out of the tree: never stow `.env`, `.aws/credentials`, `.ssh/id_*`. Use `.stow-local-ignore` or exclude from the repo entirely.
- ✅ `.ssh` permissions: SSH requires `600` on keys, `700` on the dir. Stow preserves repo permissions, which is fragile — prefer not to version SSH keys.
- ❌ Never stow as root — symlinks inherit ownership.
- ❌ Never combine `--adopt` with a dirty repo — you will silently overwrite changes.

## Secrets handling

- **Never commit**: `.env`, `.aws/credentials`, `.ssh/id_*`, tokens, API keys.
- **Pre-commit gate**: `gitleaks` is wired into `.pre-commit-config.yaml`.
- **Templates**: keep `gitconfig.template` in the repo and the real `~/.config/git/config` outside the stow tree.
- **Encryption**: for secrets that must be versioned, use `sops` with an age key.

## Debugging

```bash
# Packages currently stowed (any target, depth 3)
find ~ -maxdepth 3 -type l -lname '*dotfiles*' 2>/dev/null

# Inverse — links created by stow zsh
find ~ -maxdepth 3 -type l -lname '*dotfiles/zsh/*' 2>/dev/null

# Maximum verbosity
stow -v -v zsh   # -vv for full detail
```
