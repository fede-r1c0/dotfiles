#!/bin/bash
# install.sh — Cross-platform dotfiles installer (orchestrator).
#
# Soporta: macOS, Arch Linux, Raspberry Pi OS / Debian.
# Idempotente: re-run safe. Logging completo. Backup + rollback.
#
# Uso:
#   ./install.sh [MODE] [OPTIONS]
#
# Modes (mutually exclusive, default: --full):
#   -f, --full        packages + dotfiles + shell setup
#   -d, --dotfiles    solo stow (no instala packages)
#   -b, --brew        solo packages (no stow)
#   -s, --shell       solo OMZ + shell setup
#       --rollback    revierte stow + restaura último backup
#
# Options:
#   --dry-run         simula sin mutar
#   --minimal         skip desktop + DevOps tools (Pi-friendly)
#   -h, --help        ayuda
#   -v, --version     versión

set -euo pipefail

readonly VERSION="2.0.0"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

# -----------------------------------------------------------------------------
# Source libs (existing, validated)
# -----------------------------------------------------------------------------
readonly LIB_DIR="$DOTFILES_DIR/zsh/.zsh/scripts/lib"
# shellcheck source=zsh/.zsh/scripts/lib/colors.sh
source "$LIB_DIR/colors.sh"
# shellcheck source=zsh/.zsh/scripts/lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=zsh/.zsh/scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=zsh/.zsh/scripts/lib/validation.sh
source "$LIB_DIR/validation.sh"

# -----------------------------------------------------------------------------
# Globals (consumidos por scripts/install/*)
# -----------------------------------------------------------------------------
MODE="full"
DRY_RUN=0
MINIMAL=0
ROLLBACK_DIR=""

# Counters (consumed by scripts/install/*.sh)
# shellcheck disable=SC2034
PKG_INSTALLED=0
# shellcheck disable=SC2034
PKG_SKIPPED=0
# shellcheck disable=SC2034
PKG_FAILED=0
# shellcheck disable=SC2034
STOWED=()

# Logging
LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"

# -----------------------------------------------------------------------------
# CLI parsing
# -----------------------------------------------------------------------------
print_help() {
    cat <<EOF
install.sh v${VERSION} — cross-platform dotfiles installer

Usage:
    $0 [MODE] [OPTIONS]

Modes (default: --full):
    -f, --full        packages + dotfiles + shell setup
    -d, --dotfiles    solo stow
    -b, --brew        solo packages (no stow)
    -s, --shell       solo OMZ + shell
        --rollback    revierte último install

Options:
    --dry-run         simula sin mutar el sistema
    --minimal         skip desktop + DevOps tools
    -h, --help        esta ayuda
    -v, --version     versión

Examples:
    $0                         # full install (default)
    $0 --dry-run --full        # preview completo
    $0 --dotfiles              # solo stow
    $0 --full --minimal        # full sin desktop ni DevOps
    $0 --rollback              # revertir
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--full)      MODE="full" ;;
            -d|--dotfiles)  MODE="dotfiles" ;;
            -b|--brew)      MODE="packages" ;;
            -s|--shell)     MODE="shell" ;;
            --rollback)     MODE="rollback" ;;
            --dry-run)      DRY_RUN=1 ;;
            --minimal)      MINIMAL=1 ;;
            -h|--help)      print_help; exit 0 ;;
            -v|--version)   echo "install.sh v$VERSION"; exit 0 ;;
            *) die "Argumento desconocido: $1 (ver --help)" 1 ;;
        esac
        shift
    done
}

# -----------------------------------------------------------------------------
# Logging setup
# -----------------------------------------------------------------------------
init_logging() {
    log_init "$LOG_FILE"
    log_set_level "info"
    log_start "install.sh v$VERSION"
    log_info "Modo: $MODE | dry-run: $DRY_RUN | minimal: $MINIMAL"
    log_info "Log file: $LOG_FILE"

    trap 'log_error "Install falló en línea $LINENO. Log: $LOG_FILE"' ERR
    trap 'log_end "install.sh" $?' EXIT
}

# -----------------------------------------------------------------------------
# OS dispatch
# -----------------------------------------------------------------------------
detect_os_family() {
    local os
    os=$(detect_os)
    case "$os" in
        macos) echo "macos" ;;
        linux)
            if [[ -f /etc/arch-release ]]; then
                echo "arch"
            elif grep -qiE "raspberry|debian|ubuntu" /etc/os-release 2>/dev/null; then
                echo "raspbian"
            else
                echo "unknown"
            fi
            ;;
        *) echo "unsupported" ;;
    esac
}

# -----------------------------------------------------------------------------
# Source install scripts (lazy by family)
# -----------------------------------------------------------------------------
source_install_scripts() {
    # shellcheck source=scripts/install/common.sh
    source "$DOTFILES_DIR/scripts/install/common.sh"

    case "$OS_FAMILY" in
        macos)
            # shellcheck source=scripts/install/macos.sh
            source "$DOTFILES_DIR/scripts/install/macos.sh"
            ;;
        arch)
            # shellcheck source=scripts/install/linux-source.sh
            source "$DOTFILES_DIR/scripts/install/linux-source.sh"
            # shellcheck source=scripts/install/arch.sh
            source "$DOTFILES_DIR/scripts/install/arch.sh"
            ;;
        raspbian)
            # shellcheck source=scripts/install/linux-source.sh
            source "$DOTFILES_DIR/scripts/install/linux-source.sh"
            # shellcheck source=scripts/install/raspbian.sh
            source "$DOTFILES_DIR/scripts/install/raspbian.sh"
            ;;
        *) die "OS family no soportado: $OS_FAMILY" 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Phase runners
# -----------------------------------------------------------------------------
phase_packages() {
    log_section "Phase: Packages"
    case "$OS_FAMILY" in
        macos)    install_macos_packages ;;
        arch)     install_arch_packages; install_arch_extras ;;
        raspbian) install_raspbian_packages; install_raspbian_extras ;;
    esac
}

phase_dotfiles() {
    log_section "Phase: Dotfiles"
    require_command stow "Instalar GNU Stow primero (corré --brew o --full)"
    backup_existing_dotfiles
    stow_packages
    ensure_precommit_hooks
}

phase_shell() {
    log_section "Phase: Shell"
    ensure_omz
    install_omz_extras
    ensure_default_shell_zsh
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"
    init_logging

    OS_FAMILY=$(detect_os_family)
    log_info "OS family: $OS_FAMILY"

    if [[ "$OS_FAMILY" == "unsupported" || "$OS_FAMILY" == "unknown" ]]; then
        die "OS no soportado. Soportados: macOS, Arch, Raspberry Pi OS / Debian." 1
    fi

    source_install_scripts

    if [[ "$MODE" == "rollback" ]]; then
        rollback "$ROLLBACK_DIR"
        exit 0
    fi

    ensure_sudo

    case "$MODE" in
        full)
            phase_packages
            phase_dotfiles
            phase_shell
            ;;
        dotfiles)
            phase_dotfiles
            ;;
        packages)
            phase_packages
            ;;
        shell)
            phase_shell
            ;;
        *) die "Modo desconocido: $MODE" 1 ;;
    esac

    print_summary
    log_success "Install completado. Re-abrí tu terminal o 'exec zsh -l'"
}

main "$@"
