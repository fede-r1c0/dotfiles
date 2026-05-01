# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Claude-specific guidance

### Plan mode + skills

- **Structural changes** (new installers, orchestrator refactors, moving packages): enter plan mode first. Confirm before mutating `install.sh` or `scripts/install/*`.
- Relevant skills: `init` to regenerate this file when architecture changes.

### Languages

- User-facing prose: **Spanish** (including user-facing parts of commit messages).
- Identifiers, code, literal error messages: English.

### Destructive operations

Confirm before:

- `rm` against user files under `~/`.
- `stow -D` that could leave the system without a working shell config.
- `chsh` (changing the default shell).
- Any `sudo` outside the standard install flow.

### Testing changes

- **Before marking a task complete**, always run:
  ```bash
  shellcheck install.sh scripts/**/*.sh
  bash install.sh --dry-run --full
  ```
- Never push without `shellcheck` clean on touched files.

### Repository patterns

- **Idempotency**: every `ensure_X` function must check state and return 0 when already applied.
- **Logging**: use `log_info` / `log_warn` / `log_error` / `log_success` from `lib/logging.sh`. No raw `echo` in install scripts.
- **Dry-run**: any mutating command must be wrapped with `run` or guarded by `if (( DRY_RUN ))`.
- **Counters**: `PKG_INSTALLED`, `PKG_SKIPPED`, `PKG_FAILED` are globals — increment from wrappers, not from individual installers.

### Anti-patterns

- ❌ Do not create a project-level `MEMORY.md` — memory lives at user level under `~/.claude/projects/<project>/memory/`.
- ❌ Do not move `zsh/.zsh/scripts/lib/` — paths are hardcoded in `brew-update.sh` and `git-branch-cleanup.sh`. Source from `$DOTFILES_DIR/zsh/.zsh/scripts/lib/`.
- ❌ Do not use a sudo keep-alive loop — risk of `pam_faillock` lockout on Linux.
- ❌ Do not install OMZ before stow — it overwrites `~/.zshrc`.
