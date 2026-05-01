# git-branch-cleanup.sh

Safe local Git branch cleanup utility with protection for important branches.

## Features

- **Protects important branches**: main, master, develop, staging, production, release
- **Protects current branch**: Never deletes the branch you're on
- **Safe deletion**: Uses `git branch -d` by default (only merged branches)
- **Force mode**: Option to delete unmerged branches with `-f`
- **Dry run**: Preview changes without making them
- **Remote pruning**: Clean up stale remote-tracking branches

## Quick Usage

```bash
# Interactive cleanup (shows confirmation)
gbc

# Preview what would be deleted (safe)
gbc --dry-run
gbc -n

# Force delete unmerged branches
gbc --force
gbc -f

# Also prune remote-tracking branches
gbc --all
gbc -a

# Protect additional branches
gbc --protected staging,prod

# Combine options
gbc -nf              # dry-run + force mode info
gbc -a -p feature/x  # prune remote + protect feature/x
```

## Options

| Short | Long | Description |
|-------|------|-------------|
| `-n` | `--dry-run` | Preview without deleting |
| `-f` | `--force` | Delete unmerged branches (git branch -D) |
| `-a` | `--all` | Also prune remote-tracking branches |
| `-p` | `--protected` | Additional branches to protect (comma-separated) |
| `-q` | `--quiet` | Suppress non-essential output |
| `-h` | `--help` | Show help |
| `-v` | `--version` | Show version |

## Protected Branches

The following branches are never deleted:

- `main`, `master`, `develop`, `staging`, `production`, `release`
- Current branch (the one you're on)
- Any branch specified with `--protected`

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (or nothing to delete) |
| 1 | Error (not a git repo, invalid options, etc.) |
| 2 | User cancelled operation |
