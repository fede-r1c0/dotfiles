#!/bin/bash
# packages/raspbian.sh — Raspberry Pi OS / Debian package lists.
# Sourced by scripts/install/raspbian.sh. Bash arrays only, no logic.

# shellcheck disable=SC2034  # arrays consumed by sourcing script

# Core: requeridos pre-stow / pre-OMZ.
RASPBIAN_CORE=(
    zsh git stow curl wget gnupg
    apt-transport-https iptables fail2ban
    ca-certificates build-essential
)

# CLI tools disponibles en apt.
RASPBIAN_CLI=(
    neovim fontconfig
    jq tree age
    bat fd-find ripgrep fzf
    zoxide btop thefuck
    pre-commit
)

# Desktop: skip en --minimal.
RASPBIAN_DESKTOP=(
    i3 picom polybar rofi
)

# Source-install (no en apt o versiones outdated):
# eza, dust, mcfly, fnm, docker, kubectl, helm, kustomize,
# sops, krew, kubecolor, dyff, tenv, ghostty, git-delta, yq, tlrc
# → ver scripts/install/linux-source.sh
