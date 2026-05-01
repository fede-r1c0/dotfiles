# Package Matrix

Qué se instala, dónde, y por qué.

## macOS

Source único: `Brewfile` en raíz del repo. Instalado vía `brew bundle`.

```bash
brew bundle --file=~/dotfiles/Brewfile
```

Para detalles ver el Brewfile directamente.

## Arch Linux

Source: `packages/arch.sh` — bash arrays.

| Group | Manager | Lista |
|-------|---------|-------|
| `ARCH_CORE` | `pacman` | zsh, git, stow, gnupg, curl, wget, iptables, fail2ban, ca-certificates, base-devel |
| `ARCH_CLI` | `pacman` | neovim, jq, yq, bat, eza, fd, ripgrep, fzf, zoxide, dust, btop, mcfly, thefuck, git-delta, pre-commit, docker, kubectl, helm, kustomize |
| `ARCH_DESKTOP` | `pacman` | ghostty, i3-wm, picom, polybar, rofi (skip en `--minimal`) |
| `ARCH_AUR` | `yay` | kubecolor, tlrc |

`yay` se instala automáticamente solo si `ARCH_AUR` no está vacío.

`linux-source.sh` cubre tools no en repos oficiales: fnm, sops, tenv, cosign, dyff, krew, MesloLGS NF fonts.

## Raspberry Pi OS / Debian / Ubuntu

Source: `packages/raspbian.sh` + `scripts/install/linux-source.sh`.

| Group | Manager | Lista |
|-------|---------|-------|
| `RASPBIAN_CORE` | `apt` | zsh, git, stow, curl, wget, gnupg, apt-transport-https, iptables, fail2ban, ca-certificates, build-essential |
| `RASPBIAN_CLI` | `apt` | neovim, jq, bat, fd-find, ripgrep, fzf, zoxide, btop, thefuck, pre-commit, age, tree |
| `RASPBIAN_DESKTOP` | `apt` | i3, picom, polybar, rofi (skip en `--minimal`) |
| **Source installers** | curl/binary | eza, dust, mcfly, fnm, delta, yq, docker, kubectl, helm, kustomize, kubecolor, krew, sops, tenv, cosign, dyff, MesloLGS NF |

Notas:

- `bat` en apt instala como `batcat` (binary), no `bat`. `linux-source.sh` no lo reinstala — el alias en `aliases.zsh` lo cubre si querés.
- `fd-find` instala `fdfind`, alias a `fd`.
- Docker desde `get.docker.com` (oficial multi-distro).

## Source installers detail

`scripts/install/linux-source.sh` usa estos patrones:

### Cached versions

`fetch_latest_versions()` corre UN batch al inicio. Llena `LATEST_VERSIONS[X]` array.

Sin auth: 60 GitHub API requests/h. Con auth (`export GITHUB_TOKEN=...`): 5000/h.

### Fault tolerance

```bash
install_with_fallback "kubectl" install_kubectl_impl
```

Wrapper:
1. Skip si `command_exists "$NAME"`.
2. Run installer.
3. Failures → `log_warn` + `((PKG_FAILED++))`, NO mata script.

### Architecture detection

```bash
arch_suffix         # amd64 / arm64 / armv7
arch_x86_64_or_aarch64   # x86_64 / aarch64 (Rust binary convention)
```

## Tools NO instalados automáticamente

(Casos específicos del usuario, no del repo)

- AWS CLI: instalación oficial varía por arch — instalar manualmente
- gcloud SDK: idem (config en `zsh/.zsh/config.zsh` ya cubre paths si está)
- Bun: el repo asume `~/.bun/` — instalar con `curl -fsSL https://bun.sh/install | bash`
- Antigravity: idem path en `config.zsh`

## --minimal mode

Skip estos en Linux:

- ❌ Desktop (i3, picom, polybar, rofi, ghostty)
- ❌ DevOps tools (docker, kubectl, helm, kustomize, kubecolor, krew, sops, tenv, cosign, dyff)
- ❌ Fonts (MesloLGS NF)

Mantiene CORE + CLI básico. Footprint Pi-friendly.

## Auditar qué se instaló

```bash
# Tail del último log
tail -50 $(ls -t /tmp/dotfiles-install-*.log | head -1)

# Counters del summary final
grep -E "Pkg (success|skipped|failed)" $(ls -t /tmp/dotfiles-install-*.log | head -1)
```
