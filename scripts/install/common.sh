#!/bin/bash
# scripts/install/common.sh — Cross-OS install helpers.
# Idempotent guards. Sourced by install.sh post lib bootstrap.
# Asume ya cargados: lib/colors.sh, lib/common.sh, lib/logging.sh, lib/validation.sh.

# Stow packages (top-level dirs en repo). MacOS y Linux comparten esta lista.
# i3/picom/polybar/rofi solo aplican a Linux desktop.
# NOTA: NO usar `readonly array=(...)` — incompatible con bash 3.2 (macOS default).
STOW_BASE=(zsh tmux ghostty zed terraform)
STOW_LINUX_DESKTOP=(i3 picom polybar rofi)

# -----------------------------------------------------------------------------
# Backup pre-stow
# -----------------------------------------------------------------------------
backup_existing_dotfiles() {
    local backup_dir
    backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    local backed_up=0
    local files=(
        ".zshrc" ".zshenv" ".p10k.zsh"
        ".tmux.conf"
        ".config/ghostty" ".config/zed"
        ".config/i3" ".config/picom" ".config/polybar" ".config/rofi"
        ".terraformrc"
    )
    local f
    for f in "${files[@]}"; do
        if [[ -e "$HOME/$f" && ! -L "$HOME/$f" ]]; then
            mkdir -p "$backup_dir/$(dirname "$f")"
            cp -R "$HOME/$f" "$backup_dir/$f"
            backed_up=$((backed_up + 1))
        fi
    done

    if (( backed_up > 0 )); then
        log_info "Backup de $backed_up archivos en $backup_dir"
        echo "$backup_dir" > /tmp/dotfiles-last-backup
    else
        log_info "Nada que respaldar (no hay archivos no-symlink)"
    fi
}

# -----------------------------------------------------------------------------
# Stow operations (idempotente)
# -----------------------------------------------------------------------------
ensure_stowed() {
    local pkg="$1"
    [[ ! -d "$DOTFILES_DIR/$pkg" ]] && { log_warn "Package $pkg no existe, skip"; return 0; }

    local sim_output
    # -v requerido: sin verbose stow no printea LINK/UNLINK/etc.
    # Filtra el banner "WARNING: in simulation mode..." que stow siempre emite con --simulate.
    sim_output=$(cd "$DOTFILES_DIR" && stow --simulate -v "$pkg" 2>&1 \
        | grep -v "in simulation mode" || true)

    # Conflict signals reales: ERROR, "existing target", "neither a link nor a directory".
    if echo "$sim_output" | grep -qiE "(ERROR|existing target|neither a link)"; then
        log_warn "Conflictos en $pkg → usando --adopt"
        if (( DRY_RUN )); then
            log_info "[DRY-RUN] cd $DOTFILES_DIR && stow --adopt -v $pkg"
            return 0
        fi
        (cd "$DOTFILES_DIR" && stow --adopt -v "$pkg") || {
            log_error "Falló stow --adopt $pkg"
            return 1
        }
        return 0
    fi

    # Sin output (post-banner-filter) = ya stowed o no-op.
    if [[ -z "${sim_output//[[:space:]]/}" ]]; then
        log_info "$pkg ya stowed"
        return 0
    fi

    if (( DRY_RUN )); then
        log_info "[DRY-RUN] cd $DOTFILES_DIR && stow -v $pkg"
        return 0
    fi
    (cd "$DOTFILES_DIR" && stow -v "$pkg") || {
        log_error "Falló stow $pkg"
        return 1
    }
}

stow_packages() {
    log_section "Stow Packages"
    local pkg
    STOWED=()
    for pkg in "${STOW_BASE[@]}"; do
        ensure_stowed "$pkg" && STOWED+=("$pkg")
    done

    if is_linux && [[ "${MINIMAL:-0}" != "1" ]]; then
        for pkg in "${STOW_LINUX_DESKTOP[@]}"; do
            ensure_stowed "$pkg" && STOWED+=("$pkg")
        done
    fi
}

# -----------------------------------------------------------------------------
# Oh My Zsh + plugins (KEEP_ZSHRC=yes — respeta nuestro symlink)
# -----------------------------------------------------------------------------
ensure_omz() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh ya instalado"
        return 0
    fi
    log_info "Instalando Oh My Zsh (unattended, keep-zshrc)"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] OMZ install"
        return 0
    fi
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
        --unattended --keep-zshrc
}

ensure_omz_plugin() {
    local name="$1" repo="$2"
    local target="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"
    if [[ -d "$target" ]]; then
        log_info "Plugin $name ya instalado"
        return 0
    fi
    log_info "Instalando plugin $name"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] git clone $repo $target"
        return 0
    fi
    git clone --depth 1 "$repo" "$target"
}

ensure_omz_theme() {
    local name="$1" repo="$2"
    local target="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/$name"
    if [[ -d "$target" ]]; then
        log_info "Theme $name ya instalado"
        return 0
    fi
    log_info "Instalando theme $name"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] git clone $repo $target"
        return 0
    fi
    git clone --depth 1 "$repo" "$target"
}

install_omz_extras() {
    log_section "OMZ Plugins & Theme"
    ensure_omz_theme "powerlevel10k" "https://github.com/romkatv/powerlevel10k.git"
    ensure_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
    ensure_omz_plugin "you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use.git"
    ensure_omz_plugin "kube-ps1" "https://github.com/jonmosco/kube-ps1.git"
}

# -----------------------------------------------------------------------------
# Pre-commit hooks (gitleaks + shellcheck + shfmt + hygiene)
# -----------------------------------------------------------------------------
ensure_precommit_hooks() {
    # Solo aplica si estamos en el dotfiles repo y pre-commit está disponible.
    [[ ! -f "$DOTFILES_DIR/.pre-commit-config.yaml" ]] && return 0
    if ! command_exists pre-commit; then
        log_warn "pre-commit no instalado — skip hooks setup"
        return 0
    fi

    local git_dir="$DOTFILES_DIR/.git"
    [[ ! -d "$git_dir" ]] && { log_info "$DOTFILES_DIR no es git repo — skip pre-commit"; return 0; }

    # Idempotente: pre-commit install reescribe hook files si ya existen.
    if [[ -f "$git_dir/hooks/pre-commit" ]] && grep -q "pre-commit" "$git_dir/hooks/pre-commit" 2>/dev/null; then
        log_info "pre-commit hooks ya instalados"
        return 0
    fi

    log_info "Instalando pre-commit hooks (commit + push)"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] cd $DOTFILES_DIR && pre-commit install && pre-commit install --hook-type pre-push"
        return 0
    fi
    (cd "$DOTFILES_DIR" && pre-commit install && pre-commit install --hook-type pre-push) \
        || log_warn "pre-commit install reportó fallos"
}

# -----------------------------------------------------------------------------
# Default shell
# -----------------------------------------------------------------------------
ensure_default_shell_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)" || { log_error "zsh no encontrado"; return 1; }

    if [[ "$SHELL" == "$zsh_path" ]]; then
        log_info "zsh ya es default shell"
        return 0
    fi

    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        log_info "Agregando $zsh_path a /etc/shells"
        if (( DRY_RUN )); then
            log_info "[DRY-RUN] sudo tee -a /etc/shells"
        else
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
    fi

    log_info "chsh -s $zsh_path"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] chsh -s $zsh_path"
        return 0
    fi
    chsh -s "$zsh_path" || log_warn "chsh falló — cambiar manualmente con 'chsh -s $zsh_path'"
}

# -----------------------------------------------------------------------------
# Sudo strategy (Homebrew pattern — NOT keep-alive loop)
# -----------------------------------------------------------------------------
ensure_sudo() {
    is_macos && return 0
    [[ ! -x /usr/bin/sudo ]] && return 0

    log_info "Validando credenciales sudo"
    if (( DRY_RUN )); then
        return 0
    fi
    if ! sudo -v; then
        die "sudo requerido para instalar paquetes" 1
    fi
    trap '/usr/bin/sudo -k' EXIT
}

# -----------------------------------------------------------------------------
# Run wrapper (dry-run aware)
# -----------------------------------------------------------------------------
run() {
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] $*"
        return 0
    fi
    "$@"
}

# -----------------------------------------------------------------------------
# Rollback
# -----------------------------------------------------------------------------
rollback() {
    local backup_dir="${1:-}"
    [[ -z "$backup_dir" ]] && backup_dir="$(cat /tmp/dotfiles-last-backup 2>/dev/null || true)"
    [[ -z "$backup_dir" || ! -d "$backup_dir" ]] && die "No backup encontrado en /tmp/dotfiles-last-backup"

    confirm "Rollback desde $backup_dir? Removerá symlinks stow." || return 1

    cd "$DOTFILES_DIR" || die "No puedo cd $DOTFILES_DIR"
    local pkg
    for pkg in "${STOW_BASE[@]}" "${STOW_LINUX_DESKTOP[@]}"; do
        [[ -d "$pkg" ]] && stow -D "$pkg" 2>/dev/null || true
    done

    cp -R "$backup_dir/." "$HOME/"
    log_success "Rollback completado desde $backup_dir"
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
print_summary() {
    log_section "Installation Summary"
    log_info "OS:           $(detect_os) $(detect_arch)"
    log_info "Mode:         $MODE"
    log_info "Dry-run:      $DRY_RUN"
    log_info "Minimal:      ${MINIMAL:-0}"
    log_info "Stowed:       ${STOWED[*]:-none}"
    log_info "Pkg success:  ${PKG_INSTALLED:-0}"
    log_info "Pkg skipped:  ${PKG_SKIPPED:-0}"
    log_info "Pkg failed:   ${PKG_FAILED:-0}"
    log_info "Log file:     $LOG_FILE"
    log_info "Backup:       $(cat /tmp/dotfiles-last-backup 2>/dev/null || echo 'none')"
    if (( ${PKG_FAILED:-0} > 0 )); then
        log_warn "Hubo fallos — revisar $LOG_FILE"
    fi
}
