#!/bin/bash
# scripts/install/arch.sh — Arch Linux installer (pacman + AUR).

# Source package arrays.
# shellcheck source=../../packages/arch.sh
source "$DOTFILES_DIR/packages/arch.sh"

ensure_aur_helper() {
    [[ ${#ARCH_AUR[@]} -eq 0 ]] && return 0
    if command_exists yay; then
        log_info "yay ya instalado"
        return 0
    fi
    log_info "Instalando yay (AUR helper)"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] build yay desde AUR"
        return 0
    fi
    sudo pacman -S --needed --noconfirm git base-devel
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
}

install_arch_packages() {
    log_section "Arch Linux Packages"

    log_info "pacman -Syu (system update + core + cli)"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] pacman -Syu --needed ${ARCH_CORE[*]} ${ARCH_CLI[*]}"
    else
        sudo pacman -Syu --noconfirm --needed "${ARCH_CORE[@]}" "${ARCH_CLI[@]}" \
            || log_warn "pacman reportó fallos parciales en CORE+CLI"
    fi

    if [[ "${MINIMAL:-0}" != "1" ]]; then
        log_info "Instalando desktop packages"
        if (( DRY_RUN )); then
            log_info "[DRY-RUN] pacman -S --needed ${ARCH_DESKTOP[*]}"
        else
            sudo pacman -S --needed --noconfirm "${ARCH_DESKTOP[@]}" \
                || log_warn "pacman desktop reportó fallos parciales"
        fi
    fi

    if [[ ${#ARCH_AUR[@]} -gt 0 ]]; then
        ensure_aur_helper
        log_info "Instalando AUR packages"
        if (( DRY_RUN )); then
            log_info "[DRY-RUN] yay -S --needed ${ARCH_AUR[*]}"
        else
            yay -S --needed --noconfirm "${ARCH_AUR[@]}" \
                || log_warn "yay AUR reportó fallos parciales"
        fi
    fi

    # Validación critical — skip en dry-run
    if (( ! DRY_RUN )); then
        local critical=(zsh stow git fzf ripgrep)
        local missing=()
        local pkg
        for pkg in "${critical[@]}"; do
            command_exists "$pkg" || missing+=("$pkg")
        done
        if (( ${#missing[@]} > 0 )); then
            die "Critical packages missing: ${missing[*]}"
        fi
        log_success "Critical packages validados"
    fi
}

install_arch_extras() {
    # Source-installs solo si --full o si se necesita docker/k8s en Arch
    # (el grueso ya está en pacman/AUR para Arch). fnm/dyff/eza no están en repos
    # oficiales con la versión que queremos → linux-source los maneja como fallback.
    # shellcheck disable=SC2034  # consumed by linux-source.sh
    OS_FAMILY="arch"
    install_linux_source_tools
}
