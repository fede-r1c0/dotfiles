# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Claude-specific guidance

### Plan mode + skills

- **Cambios estructurales** (nuevos installers, refactor del orchestrator, mover packages): usar plan mode primero. Confirmar con el usuario antes de mutar `install.sh` o `scripts/install/*`.
- **Skills relevantes**: `init` para regenerar este archivo si la arquitectura cambia.

### Idiomas

- Comunicación con el usuario: **español** (incluye comentarios en commit messages user-facing).
- Identifiers, código, error messages literales: inglés.

### Operaciones destructivas

Pedir confirmación antes de:

- `rm` sobre archivos del usuario (`~/`)
- `stow -D` que pueda dejar el sistema sin shell config funcional
- `chsh` (cambio de default shell)
- Cualquier `sudo` no listado en el flow estándar

### Testing changes

- **Antes de marcar tarea completa**, correr siempre:
  ```bash
  shellcheck install.sh scripts/**/*.sh
  bash install.sh --dry-run --full
  ```
- Nunca hacer push sin que `shellcheck` pase clean en archivos tocados.

### Patrones del repo a respetar

- **Idempotencia**: toda función `ensure_X` debe chequear estado y retornar 0 si ya está aplicado.
- **Logging**: usar `log_info`/`log_warn`/`log_error`/`log_success` desde `lib/logging.sh`. No `echo` directo en install scripts.
- **Dry-run**: cualquier comando que mute el sistema debe ir wrapped con `run` o tener el guard `if (( DRY_RUN ))`.
- **Counters**: `PKG_INSTALLED`, `PKG_SKIPPED`, `PKG_FAILED` son globales — incrementar desde wrappers, no desde installers individuales.

### What NOT to do

- ❌ NO crear `MEMORY.md` project-level — es user-level por defecto en `~/.claude/projects/<project>/memory/`.
- ❌ NO mover `zsh/.zsh/scripts/lib/` — paths hardcoded en `brew-update.sh` y `git-branch-cleanup.sh` rompen. Source desde `$DOTFILES_DIR/zsh/.zsh/scripts/lib/`.
- ❌ NO usar sudo keep-alive loop — riesgo de lockout con `pam_faillock` en Linux.
- ❌ NO instalar OMZ antes de stow — pisa `~/.zshrc`.
