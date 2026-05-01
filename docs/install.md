# Install Guide

Detailed installation reference. For the quickstart see [`README.md`](../README.md).

## Support matrix

| OS | Bootstrap | Package manager | Notes |
|----|-----------|-----------------|-------|
| macOS (Apple Silicon) | ✓ | Homebrew | primary target |
| macOS (Intel) | ✓ | Homebrew | |
| Arch Linux | ✓ | pacman + yay (AUR) | rolling release |
| Raspberry Pi OS / Debian / Ubuntu | ✓ | apt + binary installers | minimal mode supported |

## Bootstrap (vanilla machine)

Single command from a freshly imaged machine:

```bash
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash
```

Headless / Pi / no DevOps tooling:

```bash
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash -s -- --minimal
```

`bootstrap.sh`:

1. Detects OS family (`darwin` / arch / debian-family).
2. Installs minimal prereqs: `git`, `curl`, `ca-certificates` (+ Xcode CLT on macOS).
3. Clones the repo to `~/dotfiles` (or pulls if already present).
4. Delegates to `install.sh --full` with any forwarded flags.

## Modes

`install.sh` has 5 mutually exclusive modes:

| Flag | Mode | Phases |
|------|------|--------|
| `-f`, `--full` | Full | packages → backup → stow → OMZ → shell (default) |
| `-d`, `--dotfiles` | Dotfiles only | backup → stow (assumes packages present) |
| `-b`, `--brew` | Packages only | packages, no stow, no shell |
| `-s`, `--shell` | Shell only | OMZ + plugins + chsh |
| `--rollback` | Rollback | unstow + restore last backup |

## Options

| Flag | Effect |
|------|--------|
| `--dry-run` | Simulate without mutating; logs every command. |
| `--minimal` | Skip desktop (i3/picom/polybar/rofi/ghostty/zed) and DevOps tools (docker/k8s/sops/tenv/cosign). Pi-friendly. |
| `-h`, `--help` | Help |
| `-v`, `--version` | Version |

## Install order (validated)

```
1. parse_args        — CLI parsing
2. init_logging      — log_init + ERR/EXIT traps
3. detect_os_family  — macos / arch / raspbian
4. source scripts    — common.sh + OS-specific
5. ensure_sudo       — sudo -v + trap (no keep-alive)
6. phase_packages    — brew bundle / pacman / apt + linux-source
7. phase_dotfiles    — backup + stow + pre-commit hooks
8. phase_shell       — OMZ with KEEP_ZSHRC=yes + plugins + chsh
9. print_summary     — counts + log path + backup path
```

**Critical**: stow runs before OMZ. Without `KEEP_ZSHRC=yes`, OMZ overwrites `~/.zshrc` even when symlinked.

## Idempotency

Every `ensure_X` function checks state and returns early when already applied:

- `ensure_homebrew` → `command_exists brew`
- `ensure_omz` → `[[ -d "$HOME/.oh-my-zsh" ]]`
- `ensure_default_shell_zsh` → `[[ "$SHELL" == "$(command -v zsh)" ]]`
- `ensure_stowed PKG` → `stow --simulate -v` to detect conflicts
- `install_with_fallback NAME FN` → `command_exists "$NAME"` before installing

Re-running `install.sh --full` is safe (no-op when fully applied).

## Logging

- File: `/tmp/dotfiles-install-YYYYMMDD-HHMMSS.log`.
- Levels: `debug`, `info`, `warn`, `error`, `success`.
- Override: edit `init_logging()` in `install.sh` or export `DOTFILES_LOG_LEVEL=debug`.

The ERR trap captures any unhandled failure:

```
[ERROR] Install failed at line 142. Log: /tmp/dotfiles-install-...log
```

## Backup and rollback

`backup_existing_dotfiles` runs **before** stow. Backup target:

```
~/.dotfiles-backup-YYYYMMDD-HHMMSS/
```

Only non-symlink files are backed up — existing symlinks already point to the repo.

Last backup path: `/tmp/dotfiles-last-backup`.

Rollback:

```bash
./install.sh --rollback
```

Steps:

1. `stow -D` for every package.
2. `cp -R "$backup_dir"/. "$HOME"/`.

## GitHub API rate limit

`linux-source.sh` caches latest versions in a single batch at startup (`fetch_latest_versions`).

Unauthenticated: 60 req/h. Authenticated: 5000 req/h.

```bash
export GITHUB_TOKEN=ghp_xxx
./install.sh --full
```

## Critical-package validation

After install, the orchestrator verifies these are on `PATH`; aborts otherwise:

- `zsh`, `stow`, `git`, `fzf`, `ripgrep`.

## Troubleshooting

### `brew bundle` partial failure

`install.sh` logs `[WARN]` and continues. Aborts only if a critical package is missing. Inspect the log for the specific package.

### `sudo` timeout during long Linux installs

Default sudo timestamp is 5 minutes. If the install exceeds it, sudo re-prompts. Workaround:

```bash
# Temporary: drop in /etc/sudoers.d/dotfiles-install
echo "Defaults:$USER timestamp_timeout=60" | sudo tee /etc/sudoers.d/dotfiles-install
# Remove afterwards.
```

### Stow conflict

When `stow PKG` reports a conflict, the orchestrator falls back to `--adopt`, which adopts the existing target file into the repo. **Inspect with `git diff` before committing**.

### OMZ overwrote `.zshrc`

Re-run `install.sh --dotfiles` to re-stow. Backup at `/tmp/dotfiles-last-backup`.

### Linux: `kubectl` / `helm` / etc. missing

These are source-installs in `/usr/local/bin`. Reopen the terminal or `hash -r`. Otherwise inspect the log for download failures.

## Pre-commit hooks

The repo uses pre-commit as the **primary** secret-prevention gate. CI is the secondary layer.

### Automatic install

`./install.sh --full` (or `--dotfiles`) runs `ensure_precommit_hooks` after stow. Idempotent: detects existing hooks and skips.

### Manual install

```bash
cd ~/dotfiles
pre-commit install                       # commit-time
pre-commit install --hook-type pre-push  # push-time (extra layer)
pre-commit run --all-files               # smoke test
```

`pre-commit` ships in `Brewfile` (macOS) and `packages/{arch,raspbian}.sh` (Linux). If missing: `brew install pre-commit` / `pacman -S pre-commit` / `apt install pre-commit`.

### Configured hooks (`.pre-commit-config.yaml`)

| Tool | Version | Purpose |
|------|---------|---------|
| gitleaks | v8.30.1 | Secret scan (config in `.gitleaks.toml`) |
| shellcheck-py | v0.9.0.6 | Shell lint (`--severity=warning`) |
| pre-commit-shfmt | v3.9.0-1 | Shell format (4-space, switch-case indent) |
| pre-commit-hooks | v6.0.0 | trailing-whitespace, EOF, yaml, large-files, merge-conflict, shebang, private-key, line-endings |

### Bypass policy

`git commit --no-verify` skips hooks. **Do not use it.** A leaked secret requires credential rotation; force-push does not help — GitHub indexes and caches refs.

### Updating versions

```bash
pre-commit autoupdate
```

Review the diff and commit the updated `.pre-commit-config.yaml`.

### Allowlisting false positives

Edit `.gitleaks.toml`:

```toml
[allowlist]
paths = ['''path/regex.*''']
regexes = ['''(?i)example[_-]?key''']
```

## CI

### `install-test.yml` — functional verification

- Matrix: `ubuntu-latest` + `macos-latest`.
- shellcheck across every `.sh`.
- `install.sh --dry-run --full` (no mutations).
- bats tests.

### `security.yml` — secret-scan defense in depth

- Triggers: PR, weekly cron (Mon 06:00 UTC), manual.
- Single job: gitleaks v8.30.1 against full git history + working tree.
- Purpose: catch secrets that slipped past pre-commit (external PRs, `--no-verify`) and re-scan history with newer detection rules.
- Complements pre-commit; does not replace it.
