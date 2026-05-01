# brew-update.sh

Comprehensive Homebrew package management with support for interactive mode and automation.

## Features

- Interactive menu for manual updates
- Automated modes for cron/scheduled execution
- Brewfile synchronization
- Package addition with auto-categorization
- Comprehensive logging

## Quick Usage

```bash
# Interactive mode (menu)
bu

# Daily update (upgrade all installed packages)
bu -d

# Full update (sync with Brewfile + upgrade everything)
bu -f

# Quiet mode (ideal for cron)
bu -dq    # daily + quiet
bu -fq    # full + quiet

# Add packages to Brewfile
bu add vim                    # Add brew formula
bu add --cask docker          # Add cask
bu add --mas Xcode            # Add Mac App Store app
bu add --vscode extension.id  # Add VSCode extension
```

## Options

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--daily` | Upgrade all installed packages |
| `-f` | `--full` | Sync with Brewfile + upgrade all |
| `-q` | `--quiet` | Suppress colors and progress messages |
| `-h` | `--help` | Show help |
| `-v` | `--version` | Show version |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BREW_UPDATE_LOG_DIR` | Log directory | `/tmp` |
| `BREW_UPDATE_LOG` | Full path to log file | Auto-generated |
| `BREWFILE` | Path to Brewfile | `~/dotfiles/Brewfile` |

## Cron Configuration

```bash
# Edit crontab
crontab -e

# Daily update at 9am
0 9 * * * ~/.zsh/scripts/brew-update.sh -dq

# Full update every Sunday at 10am
0 10 * * 0 ~/.zsh/scripts/brew-update.sh -fq

# Custom log directory
0 9 * * * BREW_UPDATE_LOG_DIR=$HOME/logs ~/.zsh/scripts/brew-update.sh -dq
```

**Note**: `/tmp` is cleaned periodically by macOS. For persistent logs, use `BREW_UPDATE_LOG_DIR`.
