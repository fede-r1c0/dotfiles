#!/bin/bash
# scripts/install/raspbian.sh — Raspberry Pi OS / Debian installer.

# shellcheck source=../../packages/raspbian.sh
source "$DOTFILES_DIR/packages/raspbian.sh"

install_raspbian_packages() {
    log_section "apt Packages"

    log_info "apt update"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] sudo apt-get update"
    else
        sudo apt-get update -qq || log_warn "apt update con warnings"
    fi

    log_info "apt install core + cli"
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] sudo apt-get install ${RASPBIAN_CORE[*]} ${RASPBIAN_CLI[*]}"
    else
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            "${RASPBIAN_CORE[@]}" "${RASPBIAN_CLI[@]}" \
            || log_warn "apt install reportó fallos parciales en CORE+CLI"
    fi

    if [[ "${MINIMAL:-0}" != "1" ]]; then
        log_info "Instalando desktop packages"
        if (( DRY_RUN )); then
            log_info "[DRY-RUN] sudo apt-get install ${RASPBIAN_DESKTOP[*]}"
        else
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
                "${RASPBIAN_DESKTOP[@]}" \
                || log_warn "apt desktop reportó fallos parciales"
        fi
    fi

    # Validación critical
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
}

install_raspbian_extras() {
    # Linux-source tools — eza/dust/mcfly/fnm/etc no están en apt o son outdated.
    # shellcheck disable=SC2034  # consumed by linux-source.sh
    OS_FAMILY="raspbian"
    install_linux_source_tools
}
