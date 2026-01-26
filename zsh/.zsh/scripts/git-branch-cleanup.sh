#!/bin/bash
# git-branch-cleanup.sh - Safe local branch cleanup utility
#
# This script helps clean up local git branches that are no longer needed.
# It protects important branches and requires confirmation before deletion.
#
# Usage: gbc [OPTIONS]
#   -n, --dry-run     Show branches that would be deleted without deleting
#   -f, --force       Force delete unmerged branches (use -D instead of -d)
#   -a, --all         Include remote-tracking branches (prune)
#   -p, --protected   Additional protected branches (comma-separated)
#   -q, --quiet       Suppress non-essential output
#   -h, --help        Show this help
#
# Protected branches (never deleted):
#   - main, master, develop, staging, production, release (defaults)
#   - Current branch (marked with *)
#   - Any branch specified with --protected
#
# Examples:
#   gbc                         # Interactive cleanup
#   gbc -n                      # Dry run (preview only)
#   gbc -f                      # Force delete (including unmerged)
#   gbc -a                      # Also prune remote-tracking branches
#   gbc -p staging,prod         # Protect additional branches

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default protected branches (comma-separated)
readonly DEFAULT_PROTECTED="main,master,develop,staging,production,release"

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
FORCE_DELETE=false
PRUNE_REMOTE=false
QUIET=false
EXTRA_PROTECTED=""

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}git-branch-cleanup${NC} v${VERSION} - Safe local branch cleanup utility

${BOLD}USAGE${NC}
    $SCRIPT_NAME [OPTIONS]

${BOLD}OPTIONS${NC}
    -n, --dry-run     Show branches that would be deleted without deleting
    -f, --force       Force delete unmerged branches (use -D instead of -d)
    -a, --all         Also prune remote-tracking branches
    -p, --protected   Additional protected branches (comma-separated)
    -q, --quiet       Suppress non-essential output
    -h, --help        Show this help message
    -v, --version     Show version number

${BOLD}PROTECTED BRANCHES${NC}
    The following branches are never deleted:
    - ${CYAN}main, master, develop, staging, production, release${NC} (defaults)
    - Current branch (the one you're on)
    - Any branch specified with --protected

${BOLD}EXAMPLES${NC}
    # Interactive cleanup (shows confirmation prompt)
    $SCRIPT_NAME

    # Preview what would be deleted (safe)
    $SCRIPT_NAME --dry-run

    # Force delete branches with unmerged changes
    $SCRIPT_NAME --force

    # Also clean up stale remote-tracking branches
    $SCRIPT_NAME --all

    # Protect additional branches
    $SCRIPT_NAME --protected feature/keep-this,hotfix/important

    # Combine options
    $SCRIPT_NAME -nf -p staging,prod

${BOLD}NOTES${NC}
    - By default, uses ${CYAN}git branch -d${NC} which only deletes merged branches
    - Use ${YELLOW}--force${NC} to delete unmerged branches (${YELLOW}git branch -D${NC})
    - Always review the branch list before confirming deletion
    - Deleted local branches can be recovered if they exist on remote

${BOLD}EXIT CODES${NC}
    0    Success (or nothing to delete)
    1    Error (not a git repo, invalid options, etc.)
    2    User cancelled operation

EOF
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

# Get current branch name
get_current_branch() {
    git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Build regex pattern for protected branches
build_protected_pattern() {
    local current_branch="$1"
    local extra="$2"
    
    # Start with default protected branches
    local protected="$DEFAULT_PROTECTED"
    
    # Add current branch
    protected="${protected},${current_branch}"
    
    # Add extra protected branches if specified
    if [[ -n "$extra" ]]; then
        protected="${protected},${extra}"
    fi
    
    # Convert comma-separated list to regex pattern
    # Also escape special regex characters in branch names
    echo "$protected" | tr ',' '\n' | sed 's/[.[\*^$()+?{|]/\\&/g' | tr '\n' '|' | sed 's/|$//'
}

# Get list of branches that can be deleted
get_deletable_branches() {
    local protected_pattern="$1"
    
    # Get all local branches except protected ones
    # Using --format to get clean branch names without leading spaces or asterisks
    git branch --format='%(refname:short)' 2>/dev/null | \
        grep -vE "^(${protected_pattern})$" || true
}

# Get stale remote-tracking branches
get_stale_remote_branches() {
    git remote prune origin --dry-run 2>/dev/null | \
        grep '\[would prune\]' | \
        awk '{print $NF}' || true
}

# Delete a single branch
delete_branch() {
    local branch="$1"
    local delete_flag="$2"
    
    if git branch "$delete_flag" "$branch" 2>/dev/null; then
        log_success "Deleted: $branch"
        return 0
    else
        log_error "Failed: $branch (has unmerged changes - use --force to delete anyway)"
        return 1
    fi
}

# Prune remote-tracking branches
prune_remote_branches() {
    log_info "Pruning stale remote-tracking branches..."
    
    if git remote prune origin 2>/dev/null; then
        log_success "Remote branches pruned"
    else
        log_warn "Failed to prune remote branches"
    fi
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
            -f|--force)
                FORCE_DELETE=true
                shift
                ;;
            -a|--all)
                PRUNE_REMOTE=true
                shift
                ;;
            -p|--protected)
                if [[ -z "${2:-}" ]]; then
                    die "Option --protected requires an argument"
                fi
                EXTRA_PROTECTED="$2"
                shift 2
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
                # Handle combined short flags like -nf
                local flags="${1#-}"
                shift
                for (( i=0; i<${#flags}; i++ )); do
                    local flag="${flags:$i:1}"
                    case "$flag" in
                        n) DRY_RUN=true ;;
                        f) FORCE_DELETE=true ;;
                        a) PRUNE_REMOTE=true ;;
                        q) QUIET=true; LOG_QUIET=true ;;
                        h) show_help; exit 0 ;;
                        v) show_version; exit 0 ;;
                        p)
                            # -p requires an argument, which should be next
                            if [[ $# -gt 0 ]]; then
                                EXTRA_PROTECTED="$1"
                                shift
                            else
                                die "Option -p requires an argument"
                            fi
                            ;;
                        *) die "Unknown option: -$flag. Use --help for usage." ;;
                    esac
                done
                ;;
            *)
                die "Unknown argument: $1. Use --help for usage."
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    # Print header
    if [[ "$QUIET" != "true" ]]; then
        print_info "Git Branch Cleanup v${VERSION}"
        echo ""
    fi
    
    # Validate git repository
    validate_git_repo
    
    # Get current branch
    local current_branch
    current_branch="$(get_current_branch)"
    
    if [[ -z "$current_branch" ]]; then
        die "Could not determine current branch"
    fi
    
    log_debug "Current branch: $current_branch"
    log_debug "Protected pattern: $DEFAULT_PROTECTED,$current_branch${EXTRA_PROTECTED:+,$EXTRA_PROTECTED}"
    
    # Build protected pattern
    local protected_pattern
    protected_pattern="$(build_protected_pattern "$current_branch" "$EXTRA_PROTECTED")"
    
    # Get branches to delete
    local branches
    branches="$(get_deletable_branches "$protected_pattern")"
    
    # Check if there are branches to delete
    if [[ -z "$branches" ]]; then
        log_success "No branches to delete"
        
        # Still prune remote if requested
        if [[ "$PRUNE_REMOTE" == "true" ]]; then
            echo ""
            prune_remote_branches
        fi
        
        exit 0
    fi
    
    # Count branches
    local branch_count
    branch_count="$(echo "$branches" | wc -l | tr -d ' ')"
    
    # Show branches to delete
    echo "${YELLOW}Branches to delete ($branch_count):${NC}"
    echo "$branches" | while read -r branch; do
        echo "  ${RED}✗${NC} $branch"
    done
    echo ""
    
    # Show mode
    if [[ "$FORCE_DELETE" == "true" ]]; then
        log_warn "Force mode: Will delete even unmerged branches (git branch -D)"
    else
        print_info "Safe mode: Only merged branches will be deleted (git branch -d)"
    fi
    
    # Dry run - exit here
    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        log_warn "Dry run mode - no branches deleted"
        exit 0
    fi
    
    # Confirm deletion
    echo ""
    if ! confirm "Delete these $branch_count branches?"; then
        log_warn "Operation cancelled"
        exit 2
    fi
    
    echo ""
    
    # Delete branches
    local delete_flag="-d"
    [[ "$FORCE_DELETE" == "true" ]] && delete_flag="-D"
    
    local deleted=0
    local failed=0
    
    while read -r branch; do
        if delete_branch "$branch" "$delete_flag"; then
            ((deleted++))
        else
            ((failed++))
        fi
    done <<< "$branches"
    
    # Prune remote if requested
    if [[ "$PRUNE_REMOTE" == "true" ]]; then
        echo ""
        prune_remote_branches
    fi
    
    # Summary
    echo ""
    print_line 40
    
    if [[ $failed -eq 0 ]]; then
        log_success "Cleanup complete: $deleted branches deleted"
    else
        log_warn "Cleanup complete: $deleted deleted, $failed failed"
        if [[ "$FORCE_DELETE" != "true" ]]; then
            print_info "Tip: Use --force to delete unmerged branches"
        fi
    fi
}

# ==============================================================================
# Entry Point
# ==============================================================================

main "$@"
