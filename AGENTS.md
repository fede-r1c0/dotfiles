# AGENTS.md

> Open-standard agent guidance file ([agents.md](https://agents.md)) consumed by Claude Code, Codex, Cursor, Factory, Sourcegraph, and other coding agents.

## Project

Personal dotfiles managed via **GNU Stow** (symlink farm). Targets:

- **macOS** (primary; Apple Silicon + Intel)
- **Arch Linux**
- **Raspberry Pi OS / Debian / Ubuntu**

Goal: vanilla machine to fully provisioned environment in a single command.

## Build & run

```bash
# Bootstrap a vanilla machine
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash

# Bootstrap minimal (Pi/headless: skip desktop + DevOps tools)
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash -s -- --minimal

# Re-run on a configured machine
cd ~/dotfiles && ./install.sh --full

# Re-stow only (config changes)
./install.sh --dotfiles

# Preview without mutations
./install.sh --full --dry-run

# Revert
./install.sh --rollback

# Stow individual package
cd ~/dotfiles && stow <package>          # symlink
cd ~/dotfiles && stow -D <package>       # remove
cd ~/dotfiles && stow -R <package>       # restow
cd ~/dotfiles && stow --simulate <package>  # preview
```

## Test

```bash
# Bats unit tests (lib/ + scripts)
bats zsh/.zsh/scripts/tests/

# Single file
bats zsh/.zsh/scripts/tests/test_common.bats

# Filter by name
bats zsh/.zsh/scripts/tests/test_common.bats --filter "trim"
```

## Lint

```bash
# Shellcheck (config in zsh/.zsh/scripts/.shellcheckrc)
shellcheck install.sh scripts/**/*.sh zsh/.zsh/scripts/*.sh zsh/.zsh/scripts/lib/*.sh

# Pre-commit (gitleaks, shellcheck, shfmt, hygiene)
pre-commit run --all-files
```

## Conventions

- **Style**: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
- `set -euo pipefail` in every script, except `linux-source.sh` which uses `-uo` for per-installer fault tolerance.
- `readonly` for constants, `local` for function variables.
- `[[ ]]` over `[ ]`; `$(...)` over backticks; quote all variable expansions: `"$var"`.
- Library source order: `colors → common → logging → validation`.
- Idempotency is mandatory — every function must be safe to re-run via guards (`command_exists`, dir checks, simulate output).

## Architecture

### Stow packages

Each top-level dir is a Stow package. File trees mirror `~/`.

| Package | macOS | Linux desktop | Linux minimal |
|---------|:-----:|:-------------:|:-------------:|
| `zsh` | ✓ | ✓ | ✓ |
| `tmux` | ✓ | ✓ | ✓ |
| `ghostty` | ✓ | ✓ | — |
| `zed` | ✓ | ✓ | — |
| `terraform` | ✓ | ✓ | ✓ |
| `i3` | — | ✓ | — |
| `picom` | — | ✓ | — |
| `polybar` | — | ✓ | — |
| `rofi` | — | ✓ | — |

### Install flow

```
bootstrap.sh (vanilla prereqs + clone)
       ↓
install.sh (orchestrator, OS dispatch)
       ↓
   ┌───┴───┬─────────┐
   ▼       ▼         ▼
 macos.sh arch.sh raspbian.sh    ← packages
   │       │         │
   └───┬───┴─────────┘
       ▼
  common.sh                       ← stow + OMZ + shell
       │
       ▼
 linux-source.sh (Linux only)     ← binary installers (eza/fnm/k8s tooling)
```

**Required ordering**: packages → backup → stow → OMZ with `KEEP_ZSHRC=yes` → shell. OMZ runs **after** stow; otherwise it overwrites `~/.zshrc` even when symlinked.

### Zsh load order

`.zshrc` glob-sources `~/.zsh/*.zsh` in alphabetical order. Convention:

- `aliases.zsh` — aliases.
- `config.zsh` — env vars + tool init guarded by `(( $+commands[X] ))`.
- `scripts/` — utilities, not auto-sourced.

### Library system (`zsh/.zsh/scripts/lib/`)

Reusable from any script:

- `colors.sh` — terminal colors + format helpers.
- `common.sh` — OS detection, command utilities, string/array helpers, prompts.
- `logging.sh` — structured logging with file output.
- `validation.sh` — input/state validation.

Source from `$DOTFILES_DIR/zsh/.zsh/scripts/lib/`.

## File map

| Path | Purpose |
|------|---------|
| `install.sh` | Entry orchestrator (CLI + OS dispatch) |
| `scripts/bootstrap.sh` | Vanilla prereqs + clone + delegate to `install.sh` |
| `scripts/install/common.sh` | Cross-OS helpers (stow, OMZ, backup, rollback, pre-commit hooks) |
| `scripts/install/macos.sh` | Homebrew + Brewfile |
| `scripts/install/arch.sh` | pacman + AUR (yay) |
| `scripts/install/raspbian.sh` | apt-get |
| `scripts/install/linux-source.sh` | Binary installers (cached versions, fault-tolerant) |
| `packages/arch.sh` | Arch package arrays (CORE/CLI/DESKTOP/AUR) |
| `packages/raspbian.sh` | Raspbian package arrays |
| `Brewfile` | macOS packages |
| `zsh/.zsh/scripts/lib/` | Reusable shell libraries |
| `zsh/.zsh/scripts/{brew-update,git-branch-cleanup}.sh` | User CLI utilities |
| `docs/install.md` | Install guide |
| `docs/stow-reference.md` | Stow reference |
| `docs/packages.md` | Per-OS package matrix |

## Validated technical decisions

- **OMZ + Stow order**: stow before OMZ. OMZ invoked with `KEEP_ZSHRC=yes --keep-zshrc`. Without these flags it overwrites `~/.zshrc` even when symlinked.
- **sudo strategy**: `sudo -v` plus `trap '/usr/bin/sudo -k' EXIT` (Homebrew pattern). No keep-alive loop — triggers `pam_faillock` lockouts on Linux.
- **GitHub API**: versions cached in a single batch at startup (`fetch_latest_versions`). Optional `GITHUB_TOKEN` raises rate from 60/h to 5000/h.
- **Linux source installers**: `install_with_fallback` per tool; failures are non-fatal because the script uses `-uo`, not `-e`.
- **Brew bundle**: post-bundle validates critical packages (`zsh`, `stow`, `git`, `fzf`, `ripgrep`). Aborts if any are missing.
- **AUR helper**: `yay` is installed only when `ARCH_AUR` is non-empty.
- **`stow .` is unsafe** without `.stow-local-ignore`; treats the whole repo as a single package and creates dir-level symlinks. `install.sh` iterates `STOW_BASE` explicitly to avoid this.
