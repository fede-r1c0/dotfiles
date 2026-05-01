# Shell Scripts

Professional shell scripts for system administration and development workflows.

## Layout

```
scripts/
├── brew-update.sh          # Homebrew package management
├── git-branch-cleanup.sh   # Git branch cleanup utility
├── hist-hygiene.sh         # Shell history secret redaction
├── docs/                   # Per-script reference
├── lib/                    # Shared libraries (colors/common/logging/validation/hist-patterns)
└── tests/                  # Bats test suite
```

## Scripts

| Script | Doc | One-liner |
|--------|-----|-----------|
| `brew-update.sh` | [docs/brew-update.md](docs/brew-update.md) | Homebrew update + Brewfile sync; cron-friendly |
| `git-branch-cleanup.sh` | [docs/git-branch-cleanup.md](docs/git-branch-cleanup.md) | Safe local branch cleanup with protections |
| `hist-hygiene.sh` | [docs/hist-hygiene.md](docs/hist-hygiene.md) | Detect + redact secrets in shell history |

## Aliases

Configured in `~/.zsh/aliases.zsh`:

| Alias | Target | Description |
|-------|--------|-------------|
| `bu` | `brew-update.sh` | Homebrew package management |
| `gbc` | `git-branch-cleanup.sh` | Git branch cleanup |
| `histfind` | `hist-hygiene.sh --find` | Scan shell history for secrets (read-only) |
| `histclear` | `hist-hygiene.sh --clear` | Redact secrets in shell history (in-place) |
| `histstop` | zsh function | Pause history recording in current session |
| `histstart` | zsh function | Resume history recording in current session |

## Shared Libraries

Source order: `colors → common → logging → validation`.

| Library | Purpose |
|---------|---------|
| [`lib/colors.sh`](lib/colors.sh) | Terminal colors, NO_COLOR-aware, formatting helpers |
| [`lib/common.sh`](lib/common.sh) | OS detection, command checks, string/array utils, prompts |
| [`lib/logging.sh`](lib/logging.sh) | Structured logging with optional file output |
| [`lib/validation.sh`](lib/validation.sh) | Input/state validation (strings, paths, git, network, brew) |
| [`lib/hist-patterns.sh`](lib/hist-patterns.sh) | Regex catalog for `hist-hygiene.sh` |

Skeleton for new scripts:

```bash
#!/bin/bash
set -euo pipefail

readonly VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; readonly SCRIPT_DIR

# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/validation.sh
source "${SCRIPT_DIR}/lib/validation.sh"
```

## Testing

```bash
brew install bats-core
bats tests/                                 # all
bats tests/test_common.bats                 # one file
bats tests/test_common.bats --filter "trim" # one test
```

## Linting

```bash
shellcheck --severity=warning -x \
  --source-path=zsh/.zsh/scripts \
  zsh/.zsh/scripts/*.sh zsh/.zsh/scripts/lib/*.sh
```

Style: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html). `set -euo pipefail`, `readonly` constants, `local` function vars, `[[ ]]` over `[ ]`, quote all expansions.

## Adding a Script

1. Create `<name>.sh` with shebang + library sources
2. Write tests in `tests/test_<name>.bats`
3. Document in `docs/<name>.md` (use existing docs as template)
4. Add row to **Scripts** table above
5. Add alias to `zsh/.zsh/aliases.zsh` if relevant
6. Add to CI shellcheck step in `.github/workflows/install-test.yml`
