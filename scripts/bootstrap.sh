#!/bin/bash
# scripts/bootstrap.sh — Vanilla machine prereqs + clone + install.
#
# Single-command setup desde una máquina recién encendida. Instala lo mínimo
# para clonar el repo y ejecutar install.sh.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/feder1c0/dotfiles/main/scripts/bootstrap.sh | bash
#   curl -fsSL ... | bash -s -- --minimal
#
# Variables:
#   DOTFILES_REPO   override repo URL (default: feder1c0/dotfiles)
#   DOTFILES_DIR    override clone target (default: $HOME/dotfiles)

set -euo pipefail

readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/feder1c0/dotfiles.git}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# -----------------------------------------------------------------------------
# OS detection
# -----------------------------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            if [[ -f /etc/arch-release ]]; then
                echo "arch"
            elif grep -qiE "raspberry|debian|ubuntu" /etc/os-release 2>/dev/null; then
                echo "raspbian"
            else
                echo "linux-unknown"
            fi
            ;;
        *) echo "unsupported" ;;
    esac
}

# -----------------------------------------------------------------------------
# Prereq installers
# -----------------------------------------------------------------------------
prereqs_macos() {
    if ! xcode-select -p &>/dev/null; then
        echo "[bootstrap] Solicitando Xcode Command Line Tools (puede tomar varios minutos)"
        xcode-select --install || true
        # Wait until /usr/bin/git existe (CLT instalado)
        until xcode-select -p &>/dev/null; do
            sleep 30
        done
    fi
    # git/curl son parte de Xcode CLT en macOS — listo.
}

prereqs_arch() {
    sudo pacman -Sy --noconfirm --needed git curl ca-certificates
}

prereqs_raspbian() {
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git curl ca-certificates
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    local os
    os=$(detect_os)
    echo "[bootstrap] OS detectado: $os"

    case "$os" in
        macos)    prereqs_macos ;;
        arch)     prereqs_arch ;;
        raspbian) prereqs_raspbian ;;
        *)        echo "[bootstrap] OS no soportado: $os" >&2; exit 1 ;;
    esac

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "[bootstrap] Clonando $DOTFILES_REPO → $DOTFILES_DIR"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        echo "[bootstrap] Repo ya existe en $DOTFILES_DIR — git pull"
        (cd "$DOTFILES_DIR" && git pull --ff-only) || echo "[bootstrap] pull falló — continuando con estado actual"
    fi

    echo "[bootstrap] Ejecutando install.sh --full $*"
    exec bash "$DOTFILES_DIR/install.sh" --full "$@"
}

main "$@"
