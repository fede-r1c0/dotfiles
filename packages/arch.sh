#!/bin/bash
# packages/arch.sh — Arch Linux package lists.
# Sourced by scripts/install/arch.sh. Bash arrays only, no logic.

# shellcheck disable=SC2034  # arrays consumed by sourcing script

# Core: requeridos pre-stow / pre-OMZ.
ARCH_CORE=(
    zsh git stow gnupg curl wget
    iptables fail2ban ca-certificates
    base-devel
)

# CLI tools: must-have para flujo de trabajo.
ARCH_CLI=(
    neovim fontconfig
    jq yq tree age
    bat eza fd ripgrep fzf
    zoxide dust btop mcfly thefuck
    git-delta pre-commit
    docker docker-compose
    kubectl helm kustomize
)

# Desktop: skip en --minimal.
ARCH_DESKTOP=(
    ghostty
    i3-wm picom polybar rofi
)

# AUR: requieren yay/paru.
ARCH_AUR=(
    kubecolor
    tlrc
)
