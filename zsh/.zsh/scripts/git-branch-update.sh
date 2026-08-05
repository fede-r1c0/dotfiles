#!/bin/bash
# git-branch-update.sh - Update current branch onto a remote base branch
#
# Fetches the base branch from origin and rebases the current branch on top,
# preserving uncommitted local changes via autostash.
# Never writes to the remote (no push).
#
# Usage: gbu <base-branch> [OPTIONS]
#   -n, --dry-run     Show how far behind/ahead the branch is without rebasing
#   -q, --quiet       Suppress non-essential output
#   -h, --help        Show this help
#   -v, --version     Show version number
#
# Examples:
#   gbu main                    # Rebase current branch onto origin/main
#   gbu develop -n              # Preview only (fetch + counts, no rebase)
#
# Safety guarantees:
#   - Remote is never modified (fetch is read-only for the remote)
#   - Uncommitted changes are preserved via git rebase --autostash
#   - On conflict: git rebase --abort restores the exact previous state
#   - Pre-rebase commits remain recoverable via ORIG_HEAD / git reflog

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

readonly VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"; readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; readonly SCRIPT_DIR

# ==============================================================================
# Load Libraries
# ==============================================================================

# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/validation.sh
source "${SCRIPT_DIR}/lib/validation.sh"

# ==============================================================================
# Configuration Variables
# ==============================================================================

DRY_RUN=false
QUIET=false
BASE_BRANCH=""

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}git-branch-update${NC} v${VERSION} - Update current branch onto a remote base branch

${BOLD}USAGE${NC}
    $SCRIPT_NAME <base-branch> [OPTIONS]

${BOLD}OPTIONS${NC}
    -n, --dry-run     Show how far behind/ahead the branch is without rebasing
    -q, --quiet       Suppress non-essential output
    -h, --help        Show this help message
    -v, --version     Show version number

${BOLD}WHAT IT DOES${NC}
    1. ${CYAN}git fetch origin <base-branch>${NC}   (read-only for the remote)
    2. ${CYAN}git rebase --autostash origin/<base-branch>${NC}

    Uncommitted changes are stashed automatically and re-applied after
    the rebase. The remote is never modified — this script never pushes.

${BOLD}EXAMPLES${NC}
    # Rebase current branch onto the latest origin/main
    $SCRIPT_NAME main

    # Preview how far behind origin/develop you are (no changes)
    $SCRIPT_NAME develop --dry-run

${BOLD}IF CONFLICTS HAPPEN${NC}
    The rebase pauses on the conflicting commit. Resolve and run
    ${CYAN}git rebase --continue${NC}, or run ${YELLOW}git rebase --abort${NC} to restore
    the exact previous state (including stashed changes).

${BOLD}EXIT CODES${NC}
    0    Success (or already up to date)
    1    Error (not a git repo, missing base branch, etc.)
    3    Rebase stopped on conflicts (resolve or abort manually)

EOF
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

# Get current branch name
get_current_branch() {
    git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Detect an unfinished rebase left by a previous operation
rebase_in_progress() {
    local git_dir
    git_dir="$(git rev-parse --git-dir)"
    [[ -d "${git_dir}/rebase-merge" || -d "${git_dir}/rebase-apply" ]]
}

# ==============================================================================
# Main Logic
# ==============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                LOG_QUIET=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -*)
                die "Unknown option: $1. Use --help for usage."
                ;;
            *)
                if [[ -z "$BASE_BRANCH" ]]; then
                    BASE_BRANCH="$1"
                else
                    die "Unexpected argument: $1. Use --help for usage."
                fi
                shift
                ;;
        esac
    done
}

main() {
    parse_args "$@"

    if [[ "$QUIET" != "true" ]]; then
        print_info "Git Branch Update v${VERSION}"
        echo ""
    fi

    validate_git_repo

    if [[ -z "$BASE_BRANCH" ]]; then
        die "Base branch required. Usage: $SCRIPT_NAME <base-branch> (e.g. $SCRIPT_NAME main)"
    fi

    if rebase_in_progress; then
        die "A rebase is already in progress. Finish it (git rebase --continue) or cancel it (git rebase --abort) first."
    fi

    local current_branch
    current_branch="$(get_current_branch)"

    if [[ -z "$current_branch" ]]; then
        die "Could not determine current branch (detached HEAD?)"
    fi

    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
        log_warn "Already on '$BASE_BRANCH' — this will fast-forward it to origin/$BASE_BRANCH"
    fi

    log_info "Fetching origin/${BASE_BRANCH}..."
    if ! git fetch origin "$BASE_BRANCH"; then
        die "Could not fetch 'origin/$BASE_BRANCH'. Does the branch exist on the remote?"
    fi

    local behind ahead
    behind="$(git rev-list --count "HEAD..origin/${BASE_BRANCH}")"
    ahead="$(git rev-list --count "origin/${BASE_BRANCH}..HEAD")"

    if [[ "$behind" -eq 0 ]]; then
        log_success "Already up to date with origin/$BASE_BRANCH"
        exit 0
    fi

    print_info "Branch '$current_branch': $behind commit(s) behind, $ahead ahead of origin/$BASE_BRANCH"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        git log --oneline --no-decorate "HEAD..origin/${BASE_BRANCH}"
        echo ""
        log_warn "Dry run mode - no rebase performed"
        exit 0
    fi

    if [[ -n "$(git status --porcelain)" ]]; then
        log_info "Uncommitted changes detected — autostash will preserve them"
    fi

    echo ""
    if git rebase --autostash "origin/${BASE_BRANCH}"; then
        echo ""
        log_success "Branch '$current_branch' rebased onto origin/$BASE_BRANCH"
        print_info "Previous state recoverable via: git reflog"
    else
        echo ""
        log_error "Rebase stopped on conflicts"
        print_info "Resolve conflicts, then: git rebase --continue"
        print_info "Or restore the previous state with: git rebase --abort"
        exit 3
    fi
}

# ==============================================================================
# Entry Point
# ==============================================================================

main "$@"
