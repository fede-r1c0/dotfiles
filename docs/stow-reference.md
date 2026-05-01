# Stow Reference

GNU Stow es un symlink farm manager. Convierte un dir de packages en symlinks
en `$HOME` (o el target dir).

## Mental model

```
~/dotfiles/
├── zsh/
│   └── .zshrc          ── stow zsh ──→  ~/.zshrc → ~/dotfiles/zsh/.zshrc
└── tmux/
    └── .tmux.conf      ── stow tmux ─→  ~/.tmux.conf → ~/dotfiles/tmux/.tmux.conf
```

Cada top-level dir = un Stow package. Files dentro mirror la estructura target.

## Comandos esenciales

```bash
cd ~/dotfiles

# Instalar (crear symlinks)
stow zsh

# Re-instalar (remove + add — útil tras agregar archivos al package)
stow -R zsh

# Desinstalar (remove symlinks, no toca repo)
stow -D zsh

# Multi-package en un comando
stow zsh tmux ghostty

# Verbose (ver qué hace cada link)
stow -v zsh
```

## Preview (simulate / check-conflicts)

Stow no tiene `--list-all` ni `--check-conflicts` nativos. Equivalentes:

### List packages

```bash
ls -d ~/dotfiles/*/ | xargs -n1 basename
```

### Simulate (preview sin mutar)

```bash
cd ~/dotfiles
stow --simulate -v zsh

# Output vacío = todo OK, ya stowed o sin cambios
# WARNING/ERROR = conflict
```

### Check si conflict

```bash
cd ~/dotfiles
stow --simulate zsh 2>&1 | grep -iE "warning|error|conflict"
```

## Conflictos

Caso típico: `~/.zshrc` existe como archivo regular (no symlink) y querés stowear `zsh/`.

```
WARNING: existing target is neither a link nor a directory: .zshrc
All operations aborted.
```

### Soluciones

**1. Backup manual + retry**

```bash
mv ~/.zshrc ~/.zshrc.bak
cd ~/dotfiles && stow zsh
diff ~/.zshrc ~/.zshrc.bak  # verificar contenido
```

**2. `--adopt` (peligroso pero útil)**

```bash
cd ~/dotfiles
stow --adopt zsh
```

`--adopt` MUEVE el archivo del target al package (¡sobrescribe el del repo!).
**Verificar inmediatamente con `git diff`** y revertir si pisó algo importante:

```bash
cd ~/dotfiles
git diff zsh/
git checkout -- zsh/  # revertir si --adopt pisó cosas valiosas
```

`install.sh` usa `--adopt` automáticamente cuando detecta conflicts y luego corre backup pre-stow para tener respaldo.

**3. Force unstow + re-stow**

```bash
stow -D zsh        # remove cualquier symlink existente
mv ~/.zshrc ~/.zshrc.old
stow zsh
```

## Tree folding

Stow por default folds dirs (symlink el dir entero si todo el contenido es del package). A veces no querés eso (ej: `.config/` debe ser dir real para que otros tools agreguen ahí):

```bash
stow --no-folding ghostty
```

Crea symlinks file-por-file en lugar del dir entero.

## .stow-local-ignore

Archivos a ignorar al stowear, regex per-package. Crear en raíz del package:

```
# zsh/.stow-local-ignore
\.DS_Store
\.swp$
README.*
.*\.bak$
```

Útil para excluir `README.md` del package de los symlinks.

## Best practices

- ✅ **Editar siempre en el repo** (`~/dotfiles/zsh/.zshrc`), nunca en el target (`~/.zshrc`).
- ✅ **Re-stow tras cambios estructurales** (`stow -R PKG`) — agregar/remover archivos.
- ✅ **Simulate antes de stow en máquina nueva** — detectar conflicts.
- ✅ **`.gitignore` secrets**: nunca stoear `.env`, `.aws/credentials`, `.ssh/id_*`. Usar `.stow-local-ignore` o no incluir en repo.
- ✅ **Permisos `.ssh`**: si stoears `.ssh/`, ojo con permisos — Stow preserva los del repo. SSH exige `600` en keys, `700` en dir. Mejor: NO incluir SSH keys en repo.
- ❌ **No stoear como root** — los symlinks heredan ownership.
- ❌ **No mezclar `--adopt` con repo dirty** — pisás changes sin querer.

## Secrets handling

- **Nunca commitear**: `.env`, `.aws/credentials`, `.ssh/id_*`, tokens, API keys.
- **Pre-commit hook**: `gitleaks` ya configurado en `.pre-commit-config.yaml`.
- **Plantillas**: `gitconfig.template` en repo, `gitconfig` real en `~/.config/git/config` no-stoeado.
- **Encriptación**: para secrets que sí necesitás versionar, usar `sops` + age key.

## Debugging

```bash
# Ver qué packages tenés stoweados
find ~ -maxdepth 3 -type l -lname '*dotfiles*' 2>/dev/null

# Inverso (qué symlinks creó stow zsh)
find ~ -maxdepth 3 -type l -lname '*dotfiles/zsh/*' 2>/dev/null

# Verbose en install
stow -v -v zsh   # -vv para más detalle
```
