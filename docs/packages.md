# Package Matrix

What gets installed, where, and why.

## macOS

Single source: `Brewfile` at the repo root, applied via `brew bundle`.

```bash
brew bundle --file=~/dotfiles/Brewfile
```

Refer to the Brewfile directly for specifics.

## Arch Linux

Source: `packages/arch.sh` (bash arrays).

| Group | Manager | List |
|-------|---------|------|
| `ARCH_CORE` | `pacman` | zsh, git, stow, gnupg, curl, wget, iptables, fail2ban, ca-certificates, base-devel |
| `ARCH_CLI` | `pacman` | neovim, jq, yq, bat, eza, fd, ripgrep, fzf, zoxide, dust, btop, mcfly, thefuck, git-delta, pre-commit, docker, kubectl, helm, kustomize |
| `ARCH_DESKTOP` | `pacman` | ghostty, i3-wm, picom, polybar, rofi (skipped with `--minimal`) |
| `ARCH_AUR` | `yay` | kubecolor, tlrc |

`yay` is bootstrapped automatically only when `ARCH_AUR` is non-empty.

`linux-source.sh` covers tooling absent from official repos: fnm, sops, tenv, cosign, dyff, krew, MesloLGS NF fonts.

## Raspberry Pi OS / Debian / Ubuntu

Source: `packages/raspbian.sh` + `scripts/install/linux-source.sh`.

| Group | Manager | List |
|-------|---------|------|
| `RASPBIAN_CORE` | `apt` | zsh, git, stow, curl, wget, gnupg, apt-transport-https, iptables, fail2ban, ca-certificates, build-essential |
| `RASPBIAN_CLI` | `apt` | neovim, jq, bat, fd-find, ripgrep, fzf, zoxide, btop, thefuck, pre-commit, age, tree |
| `RASPBIAN_DESKTOP` | `apt` | i3, picom, polybar, rofi (skipped with `--minimal`) |
| **Source installers** | curl/binary | eza, dust, mcfly, fnm, delta, yq, docker, kubectl, helm, kustomize, kubecolor, krew, sops, tenv, cosign, dyff, MesloLGS NF |

Notes:

- `bat` from apt installs as `batcat`. `linux-source.sh` does not reinstall — alias in `aliases.zsh` covers the rename if needed.
- `fd-find` installs as `fdfind`, aliased to `fd`.
- Docker is installed via `get.docker.com` (official multi-distro script).

## Source-installer internals

`scripts/install/linux-source.sh` follows three patterns:

### Cached versions

`fetch_latest_versions()` runs once at startup, populating `LATEST_VERSIONS[X]`.

Unauthenticated: 60 GitHub API req/h. With `export GITHUB_TOKEN=...`: 5000/h.

### Fault tolerance

```bash
install_with_fallback "kubectl" install_kubectl_impl
```

The wrapper:

1. Skips if `command_exists "$NAME"`.
2. Runs the installer.
3. On failure: `log_warn` + `((PKG_FAILED++))`. Does not kill the script.

### Architecture detection

```bash
arch_suffix              # amd64 / arm64 / armv7
arch_x86_64_or_aarch64   # x86_64 / aarch64 (Rust binary convention)
```

## Tools NOT installed automatically

User-specific, not part of the repo provisioning:

- AWS CLI — official install varies by arch; install manually.
- gcloud SDK — same; `zsh/.zsh/config.zsh` already wires PATH/completion if present.
- Bun — repo assumes `~/.bun/`. Install via `curl -fsSL https://bun.sh/install | bash`.
- Antigravity — same path convention in `config.zsh`.

## `--minimal` mode

Linux skip list:

- ❌ Desktop (i3, picom, polybar, rofi, ghostty)
- ❌ DevOps tooling (docker, kubectl, helm, kustomize, kubecolor, krew, sops, tenv, cosign, dyff)
- ❌ Fonts (MesloLGS NF)

Keeps CORE + base CLI. Pi-friendly footprint.

## Auditing what was installed

```bash
# Tail the most recent log
tail -50 "$(ls -t /tmp/dotfiles-install-*.log | head -1)"

# Counters from the final summary
grep -E "Pkg (success|skipped|failed)" "$(ls -t /tmp/dotfiles-install-*.log | head -1)"
```
