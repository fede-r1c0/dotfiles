# Scripts

Terminal utility scripts included in the zsh configuration of these dotfiles.

## Aliases

The following aliases are configured in `~/.zsh/aliases.zsh` and are automatically loaded with the zsh configuration:

| Alias | Script | Description |
|-------|--------|-------------|
| `bu` | `brew-update.sh` | Homebrew package management |
| `gbc` | `git-branch-cleanup.sh` | Git branch cleanup |

---

## brew-update.sh

Script for Homebrew package management with support for interactive mode and cron.

### Quick Usage

```bash
# Interactive mode (menu)
bu

# Daily update (update all installed packages)
bu -d

# Full update (sync with Brewfile + update everything)
bu -f

# Quiet mode (ideal for cron)
bu -dq    # daily + quiet
bu -fq    # full + quiet
```

### Options

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--daily` | Updates Homebrew and all installed packages |
| `-f` | `--full` | Syncs with Brewfile, installs missing packages and updates everything |
| `-q` | `--quiet` | Suppresses colors and progress messages |
| `-h` | `--help` | Shows help |

### Logging

Logs are automatically saved with timestamps for every execution:

- **Default location**: `/tmp/brew-update_YYYYMMDD_HHMMSS.log`
- **Example**: `/tmp/brew-update_20251209_194352.log`

The script always creates a complete log file with timestamps for each operation.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `BREW_UPDATE_LOG_DIR` | Directory for log files (default: `/tmp`) |
| `BREW_UPDATE_LOG` | Full path to specific log file (overrides default) |

```bash
# Custom log directory
BREW_UPDATE_LOG_DIR=$HOME/logs bu -dq

# Specific log file
BREW_UPDATE_LOG=/var/log/brew.log bu -fq
```

### Cron Configuration

```bash
# Edit crontab
crontab -e

# Daily update at 9am - logs saved to /tmp/
0 9 * * * ~/.zsh/scripts/brew-update.sh -dq

# Full update every Friday at 7pm with custom log directory
0 19 * * 5 BREW_UPDATE_LOG_DIR=$HOME/logs ~/.zsh/scripts/brew-update.sh -fq
```

**Note**: `/tmp` is cleaned periodically by macOS. For persistent logs, use `BREW_UPDATE_LOG_DIR` to specify a permanent location like `$HOME/logs`.

---

## git-branch-cleanup.sh

Script to safely clean up local Git branches.

### Usage

```bash
gbc
```

### Features

- **Protects main branches**: Automatically excludes `main`, `master` and the current branch (`*`)
- **Safe deletion**: Uses `git branch -d` (does not delete branches with unmerged changes)
- **Confirmation required**: Shows branches to be deleted and asks for confirmation before proceeding
- **Compatible**: Detects and uses `ripgrep` or `grep` based on availability

### Usage Example

```bash
$ gbc
🐙 Git branch cleanup script
🗑️  Git branches to be deleted:
feature/login
feature/api-v2
bugfix/header
⚠️  WARNING: This will permanently delete the branches. Are you sure? (y/N): y
Deleted branch feature/login (was abc1234).
Deleted branch feature/api-v2 (was def5678).
Deleted branch bugfix/header (was ghi9012).
✅ Cleanup completed
```

### Notes

- If a branch has unmerged changes, `git branch -d` will fail (use `git branch -D` manually if necessary)
- To see which branches would be deleted without executing: `git branch | grep -v -E "(main|master|\*)"`
