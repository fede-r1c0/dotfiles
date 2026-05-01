# Install Guide

Guía completa de instalación de los dotfiles. Para quickstart ver `README.md`.

## Soporte

| OS | Bootstrap | Package Manager | Notas |
|----|-----------|-----------------|-------|
| macOS (Apple Silicon) | ✓ | Homebrew | primary target |
| macOS (Intel) | ✓ | Homebrew | |
| Arch Linux | ✓ | pacman + yay (AUR) | rolling release |
| Raspberry Pi OS / Debian / Ubuntu | ✓ | apt + binary installers | minimal mode disponible |

## Bootstrap (vanilla machine)

Single command desde una máquina recién encendida:

```bash
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash
```

Para Raspberry Pi o equipos sin desktop / sin DevOps tools:

```bash
curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash -s -- --minimal
```

Bootstrap hace:

1. Detecta OS (`darwin` / arch / debian-family).
2. Instala prereqs mínimos: `git`, `curl`, `ca-certificates` (+ Xcode CLT en macOS).
3. Clona el repo a `~/dotfiles` (o pulls si ya existe).
4. Ejecuta `install.sh --full` (con flags adicionales si se pasaron).

## Modes

`install.sh` tiene 5 modos mutuamente exclusivos:

| Flag | Modo | Hace |
|------|------|------|
| `-f`, `--full` | Full | packages → backup → stow → OMZ → shell (default) |
| `-d`, `--dotfiles` | Dotfiles only | backup → stow (asume packages instalados) |
| `-b`, `--brew` | Packages only | solo packages, no stow ni shell |
| `-s`, `--shell` | Shell only | solo OMZ + plugins + chsh |
| `--rollback` | Rollback | revierte stow + restaura último backup |

## Options

| Flag | Efecto |
|------|--------|
| `--dry-run` | Simula sin mutar el sistema. Muestra todos los comandos. |
| `--minimal` | Skip desktop (i3/picom/polybar/rofi/ghostty/zed) + DevOps (docker/k8s/sops/tenv/cosign). Ideal Pi. |
| `-h`, `--help` | Ayuda |
| `-v`, `--version` | Versión |

## Install order (validated)

```
1. parse_args        — CLI parsing
2. init_logging      — log_init + ERR/EXIT traps
3. detect_os_family  — macos / arch / raspbian
4. source scripts    — common.sh + OS-specific
5. ensure_sudo       — sudo -v + trap (NO keep-alive)
6. phase_packages    — brew bundle / pacman / apt + linux-source
7. phase_dotfiles    — backup + stow
8. phase_shell       — OMZ con KEEP_ZSHRC=yes + plugins + chsh
9. print_summary     — counts + log path + backup path
```

**Crítico**: stow ANTES de OMZ. OMZ pisaría `~/.zshrc` aún siendo symlink sin `KEEP_ZSHRC=yes`.

## Idempotencia

Cada función `ensure_X` chequea estado y retorna early si ya aplicado:

- `ensure_homebrew` → `command_exists brew`
- `ensure_omz` → `[[ -d "$HOME/.oh-my-zsh" ]]`
- `ensure_default_shell_zsh` → `[[ "$SHELL" == "$(command -v zsh)" ]]`
- `ensure_stowed PKG` → `stow --simulate` para detectar conflictos
- `install_with_fallback NAME FN` → `command_exists "$NAME"` antes de instalar

Re-run de `install.sh --full` es safe (no-op si todo está aplicado).

## Logging

- File: `/tmp/dotfiles-install-YYYYMMDD-HHMMSS.log`
- Niveles: debug, info, warn, error, success
- Setear nivel: edit `init_logging()` en `install.sh` o exportar `DOTFILES_LOG_LEVEL=debug`

ERR trap captura cualquier failure no manejado:

```
[ERROR] Install falló en línea 142. Log: /tmp/dotfiles-install-...log
```

## Backup + rollback

`backup_existing_dotfiles` corre **antes** de stow. Backup target:

```
~/.dotfiles-backup-YYYYMMDD-HHMMSS/
```

Solo respalda archivos no-symlink (los symlinks ya apuntan al repo, no necesitan backup).

Path del último backup: `/tmp/dotfiles-last-backup`.

Rollback:

```bash
./install.sh --rollback
```

Hace:

1. `stow -D` para todos los packages.
2. `cp -R "$backup_dir"/. "$HOME"/`.

## GitHub API rate limit

`linux-source.sh` cachea versiones latest en un solo batch al inicio (`fetch_latest_versions`).

Sin auth: 60 requests/hora.
Con auth: 5000 requests/hora.

```bash
export GITHUB_TOKEN=ghp_xxx
./install.sh --full
```

## Critical packages validation

Post-install valida que estos estén disponibles, abort si no:

- `zsh`, `stow`, `git`, `fzf`, `ripgrep`

## Troubleshooting

### `brew bundle` falla parcial

`install.sh` reporta `[WARN]` y continúa. Si falta un crítico, abort. Revisar log para package específico.

### `sudo timeout` durante install Linux largo

Default sudo timestamp = 5min. Si install excede, pide credentials de nuevo. Para evitar:

```bash
# Temporal: editar /etc/sudoers.d/dotfiles-install
echo "Defaults:$USER timestamp_timeout=60" | sudo tee /etc/sudoers.d/dotfiles-install
# (remove después)
```

### Stow conflict

Si `stow PKG` reporta conflict, install usa `--adopt` automáticamente — adopta el archivo existente al repo. **Verificar diff** después con `git diff` antes de commit.

### OMZ pisó mi .zshrc

Re-run `install.sh --dotfiles` para re-stowear. Backup en `/tmp/dotfiles-last-backup`.

### Linux: kubectl/helm/etc no aparecen

Esos son source-installs en `/usr/local/bin`. Re-abrir terminal o `hash -r`. Si no, revisar log para fallo de download.

## Pre-commit hooks

Repo usa pre-commit como **gate primario** anti-secretos. CI es layer secundario.

### Instalación automática

`./install.sh --full` (o `--dotfiles`) corre `ensure_precommit_hooks` post-stow.
Idempotente: detecta si hooks ya instalados y skip.

### Instalación manual

```bash
cd ~/dotfiles
pre-commit install                       # commit-time
pre-commit install --hook-type pre-push  # push-time (extra capa)
pre-commit run --all-files               # smoke test
```

`pre-commit` ya viene en Brewfile (macOS) y `packages/{arch,raspbian}.sh` (Linux).
Si falta: `brew install pre-commit` / `pacman -S pre-commit` / `apt install pre-commit`.

### Hooks configurados (`.pre-commit-config.yaml`)

| Tool | Versión | Función |
|------|---------|---------|
| gitleaks | v8.30.1 | Secret scan (config en `.gitleaks.toml`) |
| shellcheck-py | v0.9.0.6 | Shell lint (--severity=warning) |
| pre-commit-shfmt | v3.9.0-1 | Shell format (4-space, switch-case indent) |
| pre-commit-hooks | v6.0.0 | trailing-whitespace, EOF, yaml, large-files, merge-conflict, shebang, private-key, line-endings |

### Bypass (NO recomendado)

`git commit --no-verify` salta hooks. **No usar** — secret en remote requiere
rotación manual de credentials, force-push no basta (GitHub indexa/cachea).

### Update versiones

```bash
pre-commit autoupdate
```

Revisar diff y commitear el `.pre-commit-config.yaml` actualizado.

### Allowlist falsos positivos

Edit `.gitleaks.toml`:

```toml
[allowlist]
paths = ['''path/regex.*''']
regexes = ['''(?i)example[_-]?key''']
```

## CI

### `install-test.yml` — funcionalidad

- Matrix `ubuntu-latest + macos-latest`
- shellcheck en todos los `.sh`
- `install.sh --dry-run --full` (sin mutaciones)
- bats tests

### `security.yml` — secret scan defense-in-depth

- Trigger: PR + weekly cron (Mon 06:00 UTC) + manual
- Job único: gitleaks v8.30.1 contra full git history + working tree
- Propósito: catch secrets que slipearon (PRs externos, --no-verify), y re-escanear
  history con detection rules nuevas que aparecen tras commits viejos
- No reemplaza pre-commit — lo complementa
