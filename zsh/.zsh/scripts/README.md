# Shell Scripts

A collection of professional shell scripts for system administration and development workflows.

## Overview

```
scripts/
├── brew-update.sh          # Homebrew package management
├── git-branch-cleanup.sh   # Git branch cleanup utility
├── lib/                    # Shared libraries
│   ├── colors.sh           # Terminal colors and formatting
│   ├── common.sh           # Common utilities
│   ├── logging.sh          # Logging system
│   └── validation.sh       # Input validation
└── tests/                  # Bats test suite
    ├── test_common.bats
    ├── test_validation.bats
    └── test_git_cleanup.bats
```

## Quick Start

### Aliases

These aliases are configured in `~/.zsh/aliases.zsh`:

| Alias | Script | Description |
|-------|--------|-------------|
| `bu` | `brew-update.sh` | Homebrew package management |
| `gbc` | `git-branch-cleanup.sh` | Git branch cleanup |

---

## Scripts

### brew-update.sh

Comprehensive Homebrew package management with support for interactive mode and automation.

#### Features

- Interactive menu for manual updates
- Automated modes for cron/scheduled execution
- Brewfile synchronization
- Package addition with auto-categorization
- Comprehensive logging

#### Quick Usage

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

#### Options

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--daily` | Upgrade all installed packages |
| `-f` | `--full` | Sync with Brewfile + upgrade all |
| `-q` | `--quiet` | Suppress colors and progress messages |
| `-h` | `--help` | Show help |
| `-v` | `--version` | Show version |

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BREW_UPDATE_LOG_DIR` | Log directory | `/tmp` |
| `BREW_UPDATE_LOG` | Full path to log file | Auto-generated |
| `BREWFILE` | Path to Brewfile | `~/dotfiles/Brewfile` |

#### Cron Configuration

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

---

### git-branch-cleanup.sh

Safe local Git branch cleanup utility with protection for important branches.

#### Features

- **Protects important branches**: main, master, develop, staging, production, release
- **Protects current branch**: Never deletes the branch you're on
- **Safe deletion**: Uses `git branch -d` by default (only merged branches)
- **Force mode**: Option to delete unmerged branches with `-f`
- **Dry run**: Preview changes without making them
- **Remote pruning**: Clean up stale remote-tracking branches

#### Quick Usage

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

#### Options

| Short | Long | Description |
|-------|------|-------------|
| `-n` | `--dry-run` | Preview without deleting |
| `-f` | `--force` | Delete unmerged branches (git branch -D) |
| `-a` | `--all` | Also prune remote-tracking branches |
| `-p` | `--protected` | Additional branches to protect (comma-separated) |
| `-q` | `--quiet` | Suppress non-essential output |
| `-h` | `--help` | Show help |
| `-v` | `--version` | Show version |

#### Protected Branches

The following branches are never deleted:
- `main`, `master`, `develop`, `staging`, `production`, `release`
- Current branch (the one you're on)
- Any branch specified with `--protected`

#### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (or nothing to delete) |
| 1 | Error (not a git repo, invalid options, etc.) |
| 2 | User cancelled operation |

---

## Shared Libraries

The `lib/` directory contains reusable shell libraries.

### Usage in Scripts

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libraries in order
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/validation.sh"
```

### lib/colors.sh

Terminal colors and formatting utilities.

```bash
# Colors are auto-initialized
print_success "Operation completed"
print_warning "Something might be wrong"
print_error "Something went wrong"
print_info "Processing..."

# Manual color usage
printf '%b%s%b\n' "$GREEN" "Green text" "$NC"

# Formatting
print_header "Section Title"
print_line 60
print_box "Title" "Line 1" "Line 2"
```

### lib/common.sh

Common utilities for all scripts.

```bash
# Platform detection
detect_os          # Returns: macos, linux, windows, unknown
detect_arch        # Returns: arm64, x64, etc.
is_macos           # Boolean check
is_apple_silicon   # Boolean check

# Command utilities
command_exists git && echo "Git is installed"
require_command brew "Install from https://brew.sh"

# Error handling
die "Error message" [exit_code]

# String utilities
trimmed=$(trim "  hello  ")
is_blank "$var" && echo "Empty"
lower=$(to_lower "HELLO")

# Array utilities
array_contains "needle" "${haystack[@]}"
joined=$(array_join "," "${array[@]}")

# User interaction
confirm "Continue?" && do_something
name=$(prompt_input "Enter name" "default")

# File utilities
backup=$(backup_file "/path/to/file")
require_readable_file "/path/to/config"
```

### lib/logging.sh

Structured logging with file output.

```bash
# Initialize
log_init "/path/to/logfile.log"
log_set_level "debug"  # debug, info, warn, error, silent

# Log messages
log_debug "Debug information"
log_info "General information"
log_warn "Warning message"
log_error "Error message"
log_success "Success message"

# Utilities
log_section "Section Title"
log_start "script-name"
log_end "script-name" $exit_code
```

### lib/validation.sh

Input and state validation.

```bash
# String validation
validate_not_empty "$var" "Variable name"
validate_length "$password" 8 64 "Password"
validate_alphanumeric "$username" "Username"

# Numeric validation
validate_integer "$count" "Count"
validate_positive_integer "$port" "Port"
validate_range "$value" 1 100 "Value"

# File system validation
validate_file "$path" "Config file"
validate_directory "$dir" "Output directory"
validate_safe_path "$input" "User path"

# Git validation
validate_git_repo
validate_git_branch "main"
validate_git_clean

# Network validation
validate_url "https://example.com"
validate_hostname "example.com"
validate_port "8080"
validate_ipv4 "192.168.1.1"

# Homebrew validation
validate_homebrew
validate_brewfile "/path/to/Brewfile"
validate_brew_package "vim"
```

---

## Testing

Tests are written using [bats-core](https://github.com/bats-core/bats-core).

### Install bats-core

```bash
brew install bats-core
```

### Run Tests

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/test_common.bats

# Run with verbose output
bats --verbose-run tests/

# Run specific test by name
bats tests/test_common.bats --filter "trim"
```

### Test Structure

```bash
tests/
├── test_common.bats      # Tests for lib/common.sh
├── test_validation.bats  # Tests for lib/validation.sh
└── test_git_cleanup.bats # Tests for git-branch-cleanup.sh
```

---

## Development

### Code Style

Scripts follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) with these conventions:

- Use `set -euo pipefail` at the start
- Use `readonly` for constants
- Use `local` for function variables
- Use `[[ ]]` for conditionals (not `[ ]`)
- Use `$(...)` for command substitution (not backticks)
- Quote all variables: `"$var"` not `$var`

### Linting

Use [ShellCheck](https://www.shellcheck.net/) for static analysis:

```bash
# Install
brew install shellcheck

# Run on all scripts
shellcheck *.sh lib/*.sh

# Run with specific severity
shellcheck --severity=warning *.sh
```

### Adding New Scripts

1. Create the script with proper shebang and documentation
2. Source required libraries
3. Add tests in `tests/`
4. Update this README
5. Add alias in `~/.zsh/aliases.zsh` if needed

```bash
#!/bin/bash
# my-script.sh - Brief description
#
# Detailed description of what the script does.
#
# Usage: my-script.sh [OPTIONS]

set -euo pipefail

readonly VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# ... script implementation ...
```

---

## License

These scripts are part of personal dotfiles and are provided as-is.
