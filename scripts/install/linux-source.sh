#!/bin/bash
# scripts/install/linux-source.sh — Source/binary installers para herramientas
# ausentes en repos oficiales de Arch / apt o con versiones outdated.
#
# Strategy:
#   1. fetch_latest_versions() — UN solo batch al inicio (evita rate limit 60/h).
#   2. install_with_fallback NAME FN — wrap each installer; failures no matan script.
#   3. Cada install_X_impl es idempotente (skip si ya instalado).
#
# Auth opcional: export GITHUB_TOKEN=... para subir rate limit a 5000/h.

set -uo pipefail  # NO -e: per-installer fault tolerance.

declare -gA LATEST_VERSIONS=()

# -----------------------------------------------------------------------------
# GitHub API helpers
# -----------------------------------------------------------------------------
gh_api() {
    local endpoint="$1"
    local -a auth_header=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && auth_header=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl -fsSL "${auth_header[@]}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/$endpoint"
}

gh_latest_tag() {
    local repo="$1"
    gh_api "repos/$repo/releases/latest" 2>/dev/null | jq -r '.tag_name // empty'
}

# -----------------------------------------------------------------------------
# Version cache (1 batch at start)
# -----------------------------------------------------------------------------
fetch_latest_versions() {
    log_section "Fetching upstream versions (cached batch)"
    if ! command_exists jq; then
        log_warn "jq no instalado — versiones latest no disponibles"
        return 0
    fi
    LATEST_VERSIONS[kubectl]=$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "")
    LATEST_VERSIONS[helm]=$(gh_latest_tag "helm/helm")
    LATEST_VERSIONS[kustomize]=$(gh_api "repos/kubernetes-sigs/kustomize/releases" 2>/dev/null \
        | jq -r '[.[] | select(.tag_name | startswith("kustomize/"))][0].tag_name // empty')
    LATEST_VERSIONS[sops]=$(gh_latest_tag "getsops/sops")
    LATEST_VERSIONS[tenv]=$(gh_latest_tag "tofuutils/tenv")
    LATEST_VERSIONS[cosign]=$(gh_latest_tag "sigstore/cosign")
    LATEST_VERSIONS[dust]=$(gh_latest_tag "bootandy/dust")
    LATEST_VERSIONS[mcfly]=$(gh_latest_tag "cantino/mcfly")
    LATEST_VERSIONS[kubecolor]=$(gh_latest_tag "kubecolor/kubecolor")
    LATEST_VERSIONS[fnm]=$(gh_latest_tag "Schniz/fnm")
    LATEST_VERSIONS[eza]=$(gh_latest_tag "eza-community/eza")
    LATEST_VERSIONS[delta]=$(gh_latest_tag "dandavison/delta")
    LATEST_VERSIONS[yq]=$(gh_latest_tag "mikefarah/yq")
    LATEST_VERSIONS[dyff]=$(gh_latest_tag "homeport/dyff")

    local k
    for k in "${!LATEST_VERSIONS[@]}"; do
        log_debug "  $k → ${LATEST_VERSIONS[$k]:-MISSING}"
    done
}

# -----------------------------------------------------------------------------
# Fault tolerance wrapper
# -----------------------------------------------------------------------------
install_with_fallback() {
    local name="$1"; shift
    if command_exists "$name"; then
        log_info "$name ya instalado — skip"
        PKG_SKIPPED=$((PKG_SKIPPED + 1))
        return 0
    fi
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] would install $name"
        return 0
    fi
    log_info "Instalando $name"
    if "$@"; then
        log_success "$name instalado"
        PKG_INSTALLED=$((PKG_INSTALLED + 1))
    else
        log_warn "$name falló — continúo"
        PKG_FAILED=$((PKG_FAILED + 1))
    fi
    return 0
}

# Detect arch suffix usado por la mayoría de releases
arch_suffix() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l)  echo "armv7" ;;
        *) echo "unknown" ;;
    esac
}

arch_x86_64_or_aarch64() {
    case "$(uname -m)" in
        x86_64)  echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) echo "unknown" ;;
    esac
}

# -----------------------------------------------------------------------------
# Individual installers
# -----------------------------------------------------------------------------

install_fnm_impl() {
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.local/share/fnm"
    export PATH="$HOME/.local/share/fnm:$PATH"
}

install_kubectl_impl() {
    local v="${LATEST_VERSIONS[kubectl]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_suffix)
    sudo curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$v/bin/linux/$a/kubectl"
    sudo chmod +x /usr/local/bin/kubectl
}

install_helm_impl() {
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

install_kustomize_impl() {
    curl -fsSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" \
        | bash -s -- "" /usr/local/bin
    sudo mv -f /usr/local/bin/kustomize /usr/local/bin/kustomize 2>/dev/null || true
}

install_sops_impl() {
    local v="${LATEST_VERSIONS[sops]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_suffix)
    sudo curl -fsSL -o /usr/local/bin/sops "https://github.com/getsops/sops/releases/download/$v/sops-$v.linux.$a"
    sudo chmod +x /usr/local/bin/sops
}

install_tenv_impl() {
    local v="${LATEST_VERSIONS[tenv]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_suffix)
    local tmp; tmp=$(mktemp -d)
    curl -fsSL "https://github.com/tofuutils/tenv/releases/download/$v/tenv_${v}_linux_${a}.tar.gz" \
        | tar -xz -C "$tmp"
    sudo install -m 0755 "$tmp"/tenv "$tmp"/terraform "$tmp"/tofu "$tmp"/atmos /usr/local/bin/ 2>/dev/null || true
    rm -rf "$tmp"
}

install_cosign_impl() {
    local v="${LATEST_VERSIONS[cosign]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_suffix)
    sudo curl -fsSL -o /usr/local/bin/cosign "https://github.com/sigstore/cosign/releases/download/$v/cosign-linux-$a"
    sudo chmod +x /usr/local/bin/cosign
}

install_dust_impl() {
    local v="${LATEST_VERSIONS[dust]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_x86_64_or_aarch64)
    local tmp; tmp=$(mktemp -d)
    curl -fsSL "https://github.com/bootandy/dust/releases/download/$v/dust-$v-${a}-unknown-linux-gnu.tar.gz" \
        | tar -xz -C "$tmp"
    sudo install -m 0755 "$tmp"/dust-*/dust /usr/local/bin/dust
    rm -rf "$tmp"
}

install_mcfly_impl() {
    curl -fsSL https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh \
        | sudo bash -s -- --git cantino/mcfly --to /usr/local/bin
}

install_kubecolor_impl() {
    local v="${LATEST_VERSIONS[kubecolor]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_suffix)
    local vnum="${v#v}"
    local tmp; tmp=$(mktemp -d)
    curl -fsSL "https://github.com/kubecolor/kubecolor/releases/download/$v/kubecolor_${vnum}_linux_${a}.tar.gz" \
        | tar -xz -C "$tmp"
    sudo install -m 0755 "$tmp"/kubecolor /usr/local/bin/kubecolor
    rm -rf "$tmp"
}

install_eza_impl() {
    local v="${LATEST_VERSIONS[eza]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_x86_64_or_aarch64)
    local tmp; tmp=$(mktemp -d)
    curl -fsSL "https://github.com/eza-community/eza/releases/download/$v/eza_${a}-unknown-linux-gnu.tar.gz" \
        | tar -xz -C "$tmp"
    sudo install -m 0755 "$tmp"/eza /usr/local/bin/eza
    rm -rf "$tmp"
}

install_delta_impl() {
    local v="${LATEST_VERSIONS[delta]:-}"
    [[ -z "$v" ]] && return 1
    local vnum="${v#v}"
    local a; a=$(arch_x86_64_or_aarch64)
    local tmp; tmp=$(mktemp -d)
    curl -fsSL "https://github.com/dandavison/delta/releases/download/$v/delta-${vnum}-${a}-unknown-linux-gnu.tar.gz" \
        | tar -xz -C "$tmp"
    sudo install -m 0755 "$tmp"/delta-*/delta /usr/local/bin/delta
    rm -rf "$tmp"
}

install_yq_impl() {
    local v="${LATEST_VERSIONS[yq]:-}"
    [[ -z "$v" ]] && return 1
    local a; a=$(arch_suffix)
    sudo curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/$v/yq_linux_$a"
    sudo chmod +x /usr/local/bin/yq
}

install_dyff_impl() {
    local v="${LATEST_VERSIONS[dyff]:-}"
    [[ -z "$v" ]] && return 1
    local vnum="${v#v}"
    local a; a=$(arch_suffix)
    local tmp; tmp=$(mktemp -d)
    curl -fsSL "https://github.com/homeport/dyff/releases/download/$v/dyff_${vnum}_linux_${a}.tar.gz" \
        | tar -xz -C "$tmp"
    sudo install -m 0755 "$tmp"/dyff /usr/local/bin/dyff
    rm -rf "$tmp"
}

install_docker_impl() {
    # Docker oficial install script (Linux multi-distro).
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER" || true
}

install_krew_impl() {
    local tmp; tmp=$(mktemp -d)
    local a; a=$(arch_suffix)
    (
        cd "$tmp" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${a}.tar.gz" &&
        tar -xzf "krew-linux_${a}.tar.gz" &&
        "./krew-linux_${a}" install krew
    )
    rm -rf "$tmp"
}

install_fonts_linux_impl() {
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    local v="v3.2.1"  # MesloLGS NF — recommended por Powerlevel10k
    local f
    for f in "Regular" "Bold" "Italic" "Bold Italic"; do
        local fname="MesloLGS NF $f.ttf"
        [[ -f "$font_dir/$fname" ]] && continue
        curl -fsSL -o "$font_dir/$fname" \
            "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${f// /%20}.ttf"
    done
    fc-cache -f "$font_dir" 2>/dev/null || true
    log_info "Powerlevel10k fonts (MesloLGS NF $v) instaladas en $font_dir"
}

# -----------------------------------------------------------------------------
# Public entry — orchestration
# -----------------------------------------------------------------------------
install_linux_source_tools() {
    log_section "Source/binary installers"

    fetch_latest_versions

    # Core CLI (siempre, also --minimal)
    install_with_fallback "fnm"     install_fnm_impl
    install_with_fallback "delta"   install_delta_impl
    install_with_fallback "yq"      install_yq_impl

    # Pi/raspbian: eza/dust/mcfly desde source (no en apt)
    if [[ "${OS_FAMILY:-}" == "raspbian" ]]; then
        install_with_fallback "eza"   install_eza_impl
        install_with_fallback "dust"  install_dust_impl
        install_with_fallback "mcfly" install_mcfly_impl
    fi

    # Fonts (UI desktop, skip en --minimal headless)
    [[ "${MINIMAL:-0}" != "1" ]] && install_with_fallback "MesloLGS-NF" install_fonts_linux_impl

    # DevOps tools — skip en --minimal
    if [[ "${MINIMAL:-0}" != "1" ]]; then
        install_with_fallback "docker"    install_docker_impl
        install_with_fallback "kubectl"   install_kubectl_impl
        install_with_fallback "helm"      install_helm_impl
        install_with_fallback "kustomize" install_kustomize_impl
        install_with_fallback "kubecolor" install_kubecolor_impl
        install_with_fallback "krew"      install_krew_impl
        install_with_fallback "sops"      install_sops_impl
        install_with_fallback "tenv"      install_tenv_impl
        install_with_fallback "cosign"    install_cosign_impl
        install_with_fallback "dyff"      install_dyff_impl
    fi
}
