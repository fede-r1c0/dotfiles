# AGENTS.md

> Open standard agent guidance file ([agents.md](https://agents.md)) used by
> Claude Code, Codex, Cursor, Factory, Sourcegraph y otros agentes.

## Project

Personal dotfiles repo. Manages config files via **GNU Stow** (symlink farm).
Soporta:

- **macOS** (primary, Apple Silicon + Intel)
- **Arch Linux**
- **Raspberry Pi OS / Debian / Ubuntu**

Goal: configurar un nuevo equipo en el menor tiempo posible — single-command bootstrap.

## Build & Run

```bash
# Bootstrap nuevo equipo (vanilla machine)
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash

# Bootstrap minimal (Pi-friendly: skip desktop + DevOps tools)
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash -s -- --minimal

# Re-run en máquina ya configurada
cd ~/dotfiles && ./install.sh --full

# Solo stow (cambios de config)
./install.sh --dotfiles

# Preview sin mutar
./install.sh --full --dry-run

# Revertir
./install.sh --rollback

# Stow individual
cd ~/dotfiles && stow <package>      # symlink
cd ~/dotfiles && stow -D <package>   # remove
cd ~/dotfiles && stow -R <package>   # restow
cd ~/dotfiles && stow --simulate <package>   # preview
```

## Test

```bash
# Bats unit tests (lib/ + scripts)
bats zsh/.zsh/scripts/tests/

# Single test file
bats zsh/.zsh/scripts/tests/test_common.bats

# Filter
bats zsh/.zsh/scripts/tests/test_common.bats --filter "trim"
```

## Lint

```bash
# Shellcheck (config en zsh/.zsh/scripts/.shellcheckrc)
shellcheck install.sh scripts/**/*.sh zsh/.zsh/scripts/*.sh zsh/.zsh/scripts/lib/*.sh

# Pre-commit (gitleaks secret detection)
pre-commit run --all-files
```

## Conventions

- **Shell style**: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- `set -euo pipefail` en cada script (excepto `linux-source.sh` que usa `-uo` para fault tolerance per-installer)
- `readonly` para constantes; `local` para vars de función
- `[[ ]]` no `[ ]`; `$(...)` no backticks; quotear todas las vars: `"$var"`
- Source order en libs: `colors → common → logging → validation`
- Idempotencia obligatoria: cada función debe ser safe para re-run vía guards (`command_exists`, dir checks, etc.)

## Architecture

### Stow packages

Cada top-level dir es un paquete Stow. Files mirror estructura de `~/`.

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
 linux-source.sh (Linux only)     ← binary installers (eza/fnm/k8s/etc)
```

**Order crítico** (validado): packages → backup → stow → OMZ con `KEEP_ZSHRC=yes` → shell.
OMZ debe correr DESPUÉS de stow (sino pisa `~/.zshrc` aún siendo symlink).

### Zsh load order

`.zshrc` glob-sources `~/.zsh/*.zsh` (alfabético). Convención:

- `aliases.zsh` — aliases
- `config.zsh` — env vars + tool init (con `(( $+commands[X] ))` guards)
- `scripts/` — utilities (no auto-sourced)

### Library system (`zsh/.zsh/scripts/lib/`)

Reusable desde cualquier script:

- `colors.sh` — terminal colors + format helpers
- `common.sh` — OS detect, command utils, string/array, user prompts
- `logging.sh` — structured logging con file output
- `validation.sh` — input/state validation

Sourcear con `$DOTFILES_DIR/zsh/.zsh/scripts/lib/`.

## Files

| Path | Purpose |
|------|---------|
| `install.sh` | Entry orchestrator (CLI + OS dispatch) |
| `scripts/bootstrap.sh` | Vanilla machine prereqs + clone + install |
| `scripts/install/common.sh` | Cross-OS helpers (stow, OMZ, backup, rollback) |
| `scripts/install/macos.sh` | Homebrew + Brewfile |
| `scripts/install/arch.sh` | pacman + AUR (yay) |
| `scripts/install/raspbian.sh` | apt-get |
| `scripts/install/linux-source.sh` | Binary installers (versiones cacheadas, fault-tolerant) |
| `packages/arch.sh` | Arch package arrays (CORE/CLI/DESKTOP/AUR) |
| `packages/raspbian.sh` | Raspbian package arrays |
| `Brewfile` | macOS packages |
| `zsh/.zsh/scripts/lib/` | Reusable shell libraries |
| `zsh/.zsh/scripts/{brew-update,git-branch-cleanup}.sh` | User CLI utilities |
| `docs/install.md` | Detailed install guide |
| `docs/stow-reference.md` | Stow commands + best practices |
| `docs/packages.md` | Per-OS package matrix |

## Validated technical decisions

- **OMZ + Stow order**: stow ANTES de OMZ. OMZ usa `KEEP_ZSHRC=yes --keep-zshrc`. Validado: sin esto, OMZ pisa `~/.zshrc` aún siendo symlink.
- **sudo strategy**: `sudo -v` + `trap '/usr/bin/sudo -k' EXIT` (Homebrew pattern). NO usar keep-alive loop — causa lockouts con `pam_faillock`.
- **GitHub API**: cache de versiones en single batch al inicio (`fetch_latest_versions`). Auth opcional `GITHUB_TOKEN` para subir rate de 60/h a 5000/h.
- **Linux source installers**: `install_with_fallback` per tool — fallos no matan el script (script usa `-uo`, no `-e`).
- **Brew bundle**: post-bundle valida critical packages (zsh, stow, git, fzf, ripgrep). Si faltan, abort.
- **AUR helper**: `yay` se instala SOLO si `ARCH_AUR` no está vacío.
