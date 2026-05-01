#!/bin/bash
# scripts/install/macos.sh — macOS installer (Homebrew + Brewfile).

ensure_homebrew() {
    if command_exists brew; then
        log_info "Homebrew ya instalado"
        return 0
    fi
    log_info "Instalando Homebrew"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] Homebrew install"
        return 0
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # shellenv para sesión actual (Apple Silicon → /opt/homebrew, Intel → /usr/local)
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_macos_packages() {
    log_section "Homebrew Bundle"
    ensure_homebrew

    local brewfile="$DOTFILES_DIR/Brewfile"
    if [[ ! -f "$brewfile" ]]; then
        die "Brewfile no encontrado en $brewfile"
    fi

    if (( DRY_RUN )); then
        log_info "[DRY-RUN] brew bundle --file=$brewfile"
        run brew bundle check --file="$brewfile" || true
        return 0
    fi

    log_info "Ejecutando brew bundle (puede tardar varios minutos)"
    if ! brew bundle --file="$brewfile"; then
        log_warn "brew bundle reportó fallos parciales — validando críticos"
    fi

    # Validación critical packages — si faltan estos, abort. Skip en dry-run.
    if (( ! DRY_RUN )); then
        local critical=(zsh stow git fzf ripgrep)
        local missing=()
        local pkg
        for pkg in "${critical[@]}"; do
            command_exists "$pkg" || missing+=("$pkg")
        done
        if (( ${#missing[@]} > 0 )); then
            die "Critical packages missing: ${missing[*]} — abort install"
        fi
        log_success "Critical packages validados"
    fi
}

install_macos_extras() {
    # Hooks específicos macOS post-brew (e.g. defaults write, launchd, etc.).
    # Por ahora: noop. Extender acá si se necesita.
    return 0
}
