# git-branch-update.sh

Safe rebase of the current branch onto a remote base branch.

## Features

- **Never touches the remote**: `git fetch` is read-only for origin; the script never pushes
- **Preserves local work**: uncommitted changes are stashed automatically (`--autostash`) and re-applied after the rebase
- **Dry run**: preview how far behind/ahead without rebasing
- **Conflict-safe**: on conflict the rebase pauses; `git rebase --abort` restores the exact previous state (including stashed changes)
- **Recoverable**: pre-rebase commits stay reachable via `ORIG_HEAD` / `git reflog`

## Quick Usage

```bash
# Rebase current branch onto the latest origin/main
gbu main

# Preview only — fetch + ahead/behind counts, no rebase
gbu develop --dry-run
gbu develop -n
```

## Options

| Short | Long | Description |
|-------|------|-------------|
| `-n` | `--dry-run` | Show ahead/behind counts without rebasing |
| `-q` | `--quiet` | Suppress non-essential output |
| `-h` | `--help` | Show help |
| `-v` | `--version` | Show version |

## What It Does

1. `git fetch origin <base-branch>` (read-only for the remote)
2. `git rebase --autostash origin/<base-branch>`

## If Conflicts Happen

The rebase pauses on the conflicting commit.

- Resolve and run `git rebase --continue`, or
- Run `git rebase --abort` to restore the exact previous state (including stashed changes)

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (or already up to date) |
| 1 | Error (not a git repo, missing/unknown base branch, rebase already in progress, etc.) |
| 3 | Rebase stopped on conflicts (resolve or abort manually) |
