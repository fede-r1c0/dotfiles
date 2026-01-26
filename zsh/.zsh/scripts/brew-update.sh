#!/bin/bash
# brew-update.sh - Comprehensive Homebrew package management script
#
# This script provides a unified interface for managing Homebrew packages,
# including brew formulas, casks, Mac App Store apps, and VSCode extensions.
#
# Features:
#   - Interactive menu for manual updates
#   - Automated modes for cron/scheduled execution
#   - Brewfile synchronization
#   - Package addition with auto-categorization
#   - Comprehensive logging
#
# Prerequisites:
#   - Homebrew installed (https://brew.sh)
#   - For Mac App Store apps: Sign in to App Store app with your Apple ID
#
# Usage:
#   Interactive mode:  bu
#   Daily update:      bu -d
#   Full update:       bu -f
#   Quiet mode:        bu -dq or bu -fq
#   Add package:       bu add <package> [--cask|--brew|--mas|--vscode]
#
# Environment Variables:
#   BREW_UPDATE_LOG_DIR   Directory for log files (default: /tmp)
#   BREW_UPDATE_LOG       Full path to specific log file
#   BREWFILE              Path to Brewfile (default: ~/dotfiles/Brewfile)

set -euo pipefail

# ==============================================================================
# Script Metadata
# ==============================================================================

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
# Configuration
# ==============================================================================

# Ensure Homebrew is in PATH (important for cron)
if is_apple_silicon; then
    export PATH="/opt/homebrew/bin:$PATH"
else
    export PATH="/usr/local/bin:$PATH"
fi

# Default paths (can be overridden via environment)
readonly DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
readonly BREWFILE="${BREWFILE:-$DOTFILES_ROOT/Brewfile}"

# Logging configuration
readonly LOG_DIR="${BREW_UPDATE_LOG_DIR:-/tmp}"
readonly LOG_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly DEFAULT_LOG_FILE="${LOG_DIR}/brew-update_${LOG_TIMESTAMP}.log"

# Temp directory for intermediate files
readonly TEMP_DIR="$(mktemp -d)"

# ==============================================================================
# Global State
# ==============================================================================

# Mode flags
QUIET_MODE=false
CRON_MODE=false
ACTION=""

# Add package state
ADD_PACKAGE_NAME=""
ADD_PACKAGE_TYPE="brew"

# ==============================================================================
# Cleanup
# ==============================================================================

cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# ==============================================================================
# Homebrew Utility Functions
# ==============================================================================

# Check if Homebrew is available
check_homebrew() {
    if ! command_exists brew; then
        die "Homebrew is not installed. Install from: https://brew.sh"
    fi
}

# Check if Brewfile exists
check_brewfile() {
    if [[ ! -f "$BREWFILE" ]]; then
        die "Brewfile not found at: $BREWFILE"
    fi
}

# Check Mac App Store CLI status
check_mas_status() {
    # Check if Brewfile contains any mas packages
    if ! grep -qE '^mas ' "$BREWFILE" 2>/dev/null; then
        return 0
    fi
    
    if ! command_exists mas; then
        log_warn "mas CLI not installed. Mac App Store apps will be skipped."
        return 0
    fi
    
    log_info "Mac App Store apps will be installed via 'mas' CLI"
    log_debug "Ensure you're signed in to the App Store app if installation fails"
}

# ==============================================================================
# Package Analysis
# ==============================================================================

# Get installed brew formulas (leaves only)
get_installed_formulas() {
    brew leaves 2>/dev/null | sed 's/@.*$//' | sort -u || true
}

# Get installed casks
get_installed_casks() {
    brew list --cask 2>/dev/null | sort || true
}

# Get installed mas apps (by ID)
get_installed_mas() {
    if command_exists mas; then
        mas list 2>/dev/null | awk '{print $1}' | sort || true
    fi
}

# Extract package names from Brewfile
extract_brewfile_formulas() {
    grep -E '^brew "' "$BREWFILE" 2>/dev/null | \
        sed 's/^brew "\([^"]*\)".*/\1/' | \
        sed 's/@[^/]*$//' | \
        sort -u || true
}

extract_brewfile_casks() {
    grep -E '^cask "' "$BREWFILE" 2>/dev/null | \
        sed 's/^cask "\([^"]*\)".*/\1/' | \
        sort || true
}

extract_brewfile_mas() {
    grep -E '^mas ' "$BREWFILE" 2>/dev/null | \
        sed -n 's/.*id: *\([0-9]*\).*/\1/p' | \
        sort || true
}

# Show package analysis
show_package_analysis() {
    log_section "Package Analysis"
    
    # Temp files for comparison
    local installed_brew="$TEMP_DIR/installed_brew.txt"
    local installed_cask="$TEMP_DIR/installed_cask.txt"
    local installed_mas="$TEMP_DIR/installed_mas.txt"
    local brewfile_brew="$TEMP_DIR/brewfile_brew.txt"
    local brewfile_cask="$TEMP_DIR/brewfile_cask.txt"
    local brewfile_mas="$TEMP_DIR/brewfile_mas.txt"
    
    # Gather data
    get_installed_formulas > "$installed_brew"
    get_installed_casks > "$installed_cask"
    get_installed_mas > "$installed_mas"
    extract_brewfile_formulas > "$brewfile_brew"
    extract_brewfile_casks > "$brewfile_cask"
    extract_brewfile_mas > "$brewfile_mas"
    
    # Brew packages
    local brew_installed brew_brewfile
    brew_installed="$(wc -l < "$installed_brew" | tr -d ' ')"
    brew_brewfile="$(wc -l < "$brewfile_brew" | tr -d ' ')"
    
    printf '%b%s%b\n' "$YELLOW" "Brew Packages:" "$NC"
    printf '   Brewfile: %s packages\n' "$brew_brewfile"
    printf '   Installed: %s packages\n' "$brew_installed"
    
    local missing_brew
    missing_brew="$(comm -23 "$brewfile_brew" "$installed_brew" 2>/dev/null | head -5)"
    if [[ -n "$missing_brew" ]]; then
        printf '   %bMissing:%b\n' "$YELLOW" "$NC"
        echo "$missing_brew" | sed 's/^/      - /'
    fi
    
    echo ""
    
    # Cask packages
    local cask_installed cask_brewfile
    cask_installed="$(wc -l < "$installed_cask" | tr -d ' ')"
    cask_brewfile="$(wc -l < "$brewfile_cask" | tr -d ' ')"
    
    printf '%b%s%b\n' "$YELLOW" "Cask Packages:" "$NC"
    printf '   Brewfile: %s packages\n' "$cask_brewfile"
    printf '   Installed: %s packages\n' "$cask_installed"
    
    echo ""
    
    # Outdated packages
    local outdated_brew outdated_cask
    outdated_brew="$(brew outdated --formula 2>/dev/null | wc -l | tr -d ' ')"
    outdated_cask="$(brew outdated --cask 2>/dev/null | wc -l | tr -d ' ')"
    
    printf '%b%s%b\n' "$YELLOW" "Outdated Packages:" "$NC"
    
    if [[ "$outdated_brew" -gt 0 ]] || [[ "$outdated_cask" -gt 0 ]]; then
        printf '   Brew: %s outdated\n' "$outdated_brew"
        printf '   Cask: %s outdated\n' "$outdated_cask"
    else
        print_success "All packages are up to date"
    fi
    
    print_line 60
}

# ==============================================================================
# Update Functions
# ==============================================================================

# Update Homebrew itself
update_homebrew() {
    log_info "Updating Homebrew..."
    
    if brew update; then
        log_success "Homebrew updated"
    else
        die "Failed to update Homebrew"
    fi
}

# Upgrade all brew formulas
upgrade_formulas() {
    log_info "Upgrading brew packages..."
    
    if brew upgrade --formula; then
        log_success "Brew packages upgraded"
    else
        log_warn "Some brew packages failed to upgrade"
    fi
}

# Upgrade all casks
upgrade_casks() {
    log_info "Upgrading cask packages..."
    
    if brew upgrade --cask; then
        log_success "Cask packages upgraded"
    else
        log_warn "Some cask packages failed to upgrade"
    fi
}

# Install problematic mas apps separately (workaround for brew bundle bug)
install_mas_workarounds() {
    if ! command_exists mas; then
        return 0
    fi
    
    # Xcode has known issues with brew bundle - install it separately
    local xcode_id
    xcode_id="$(grep -E '^mas "Xcode"' "$BREWFILE" 2>/dev/null | grep -oE '[0-9]+' || echo "")"
    
    if [[ -z "$xcode_id" ]]; then
        return 0
    fi
    
    # Check if already installed
    if mas list 2>/dev/null | grep -q "^$xcode_id "; then
        log_debug "Xcode already installed"
        return 0
    fi
    
    log_warn "Xcode detected - installing separately (brew bundle has issues with large mas apps)"
    log_info "Installing Xcode via mas..."
    
    if mas install "$xcode_id"; then
        log_success "Xcode installed"
    else
        log_warn "Xcode installation failed. Install manually from App Store."
    fi
}

# Install/update packages from Brewfile
install_brewfile_packages() {
    local upgrade_flag="${1:---upgrade}"
    
    log_info "Installing packages from Brewfile..."
    
    # Install problematic mas apps first
    install_mas_workarounds
    
    # Run brew bundle
    # Use direct execution when terminal is available for sudo/mas prompts
    if [[ -t 0 ]] && [[ -t 1 ]]; then
        log_debug "Running brew bundle with direct terminal access"
        
        if brew bundle install --file="$BREWFILE" "$upgrade_flag"; then
            log_success "Brewfile packages installed/updated"
        else
            log_warn "Some Brewfile packages failed. Check output above."
        fi
    else
        # Non-interactive mode - capture output
        log_debug "Running brew bundle in non-interactive mode"
        log_warn "Non-interactive mode: sudo/mas prompts may fail"
        
        local output_file="$TEMP_DIR/bundle_output.txt"
        
        if brew bundle install --file="$BREWFILE" "$upgrade_flag" > "$output_file" 2>&1; then
            log_success "Brewfile packages installed/updated"
        else
            log_warn "Some Brewfile packages failed"
            
            # Analyze failures
            if grep -q "has failed!" "$output_file" 2>/dev/null; then
                local failed_count
                failed_count="$(grep -c "has failed!" "$output_file" || echo 0)"
                log_warn "Failed packages: $failed_count"
            fi
        fi
        
        # Show output in non-quiet mode
        if [[ "$QUIET_MODE" != "true" ]] && [[ -f "$output_file" ]]; then
            cat "$output_file"
        fi
    fi
}

# Cleanup old versions
cleanup_packages() {
    log_info "Cleaning up old versions..."
    
    if brew cleanup -s 2>/dev/null; then
        log_success "Cleanup completed"
    else
        log_warn "Cleanup had some issues"
    fi
}

# ==============================================================================
# Update Modes
# ==============================================================================

# Daily update: update Homebrew and upgrade all packages
run_daily_update() {
    log_section "Daily Update"
    
    update_homebrew
    upgrade_formulas
    upgrade_casks
    cleanup_packages
    
    log_success "Daily update completed"
}

# Full update: sync with Brewfile, install missing, upgrade all
run_full_update() {
    log_section "Full Update"
    
    check_mas_status
    update_homebrew
    install_brewfile_packages --upgrade
    upgrade_formulas
    upgrade_casks
    cleanup_packages
    
    log_success "Full update completed"
}

# ==============================================================================
# Add Package Functions
# ==============================================================================

# Get package description from brew info
get_package_description() {
    local package="$1"
    local package_type="${2:-brew}"
    
    if [[ "$package_type" == "cask" ]]; then
        brew info --cask "$package" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' || echo ""
    else
        brew info "$package" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' || echo ""
    fi
}

# Find alphabetical insertion point in Brewfile section
find_insertion_line() {
    local package_name="$1"
    local package_type="$2"
    local section_pattern="$3"
    
    local section_start
    section_start="$(grep -n "^${section_pattern}" "$BREWFILE" 2>/dev/null | head -1 | cut -d: -f1 || echo "")"
    
    if [[ -z "$section_start" ]]; then
        # Section doesn't exist, append to end
        wc -l < "$BREWFILE" | tr -d ' '
        return
    fi
    
    # Find alphabetical position within section
    local package_lower
    package_lower="$(to_lower "$package_name")"
    
    local line_num="$((section_start + 1))"
    local total_lines
    total_lines="$(wc -l < "$BREWFILE" | tr -d ' ')"
    
    while [[ $line_num -le $total_lines ]]; do
        local line_content
        line_content="$(sed -n "${line_num}p" "$BREWFILE")"
        
        # Stop at next section
        [[ "$line_content" =~ ^#[^[:space:]] ]] && break
        
        # Skip empty lines and comments
        [[ -z "$line_content" || "$line_content" =~ ^[[:space:]]*# ]] && { ((line_num++)); continue; }
        
        # Extract existing package name
        local existing_package
        existing_package="$(echo "$line_content" | sed -n "s/.*${package_type} \"\([^\"]*\)\".*/\1/p")"
        
        if [[ -n "$existing_package" ]]; then
            local existing_lower
            existing_lower="$(to_lower "$existing_package")"
            
            if [[ "$package_lower" < "$existing_lower" ]]; then
                echo "$line_num"
                return
            fi
        fi
        
        ((line_num++))
    done
    
    echo "$line_num"
}

# Add package to Brewfile
add_package_to_brewfile() {
    local package_name="$1"
    local package_type="${2:-brew}"
    
    # Validate package exists
    if [[ "$package_type" == "cask" ]]; then
        if ! brew info --cask "$package_name" &>/dev/null; then
            die "Cask not found: $package_name"
        fi
    elif [[ "$package_type" == "brew" ]]; then
        if ! brew info "$package_name" &>/dev/null; then
            die "Formula not found: $package_name"
        fi
    fi
    
    # Check if already in Brewfile
    if grep -qE "^${package_type} \"${package_name}\"" "$BREWFILE" 2>/dev/null; then
        log_warn "Package already in Brewfile: $package_name"
        return 1
    fi
    
    # Get description
    local description
    description="$(get_package_description "$package_name" "$package_type")"
    
    # Determine section
    local section_pattern=""
    case "$package_type" in
        brew)   section_pattern="# Binaries" ;;
        cask)
            if [[ "$package_name" =~ ^font- ]]; then
                section_pattern="# Fonts"
            else
                section_pattern="# Apps"
            fi
            ;;
        mas)    section_pattern="# Mac App Store" ;;
        vscode) section_pattern="# VSCode extensions" ;;
    esac
    
    # Find insertion point
    local insert_line
    insert_line="$(find_insertion_line "$package_name" "$package_type" "$section_pattern")"
    
    # Format the new line
    local new_line
    if [[ "$package_type" == "mas" ]]; then
        new_line="mas \"${package_name}\", id: PLACEHOLDER_ID # ${description}"
        log_warn "MAS packages require an ID. Update PLACEHOLDER_ID manually."
    elif [[ "$package_type" == "vscode" ]]; then
        new_line="vscode \"${package_name}\""
    else
        new_line="${package_type} \"${package_name}\" # ${description}"
    fi
    
    # Create backup
    cp "$BREWFILE" "${BREWFILE}.bak"
    
    # Insert line
    local total_lines
    total_lines="$(wc -l < "$BREWFILE" | tr -d ' ')"
    
    if [[ "$insert_line" -gt "$total_lines" ]]; then
        echo "$new_line" >> "$BREWFILE"
    else
        awk -v line="$insert_line" -v new="$new_line" \
            'NR == line {print new} {print}' \
            "$BREWFILE" > "${BREWFILE}.tmp" && mv "${BREWFILE}.tmp" "$BREWFILE"
    fi
    
    rm -f "${BREWFILE}.bak"
    
    log_success "Added $package_type '$package_name' to Brewfile (line $insert_line)"
}

# ==============================================================================
# Interactive Mode
# ==============================================================================

show_menu() {
    echo ""
    print_box "Homebrew Package Manager" \
        "1) Daily Update - Upgrade all installed packages" \
        "2) Full Update  - Sync Brewfile + upgrade all" \
        "3) Exit"
    echo ""
}

run_interactive_mode() {
    print_header "Homebrew Package Manager v${VERSION}"
    
    log_info "Brewfile: $BREWFILE"
    echo ""
    
    show_package_analysis
    check_mas_status
    
    while true; do
        show_menu
        
        local choice
        read -p "Select option [1-3]: " -r choice
        echo ""
        
        case "$choice" in
            1) run_daily_update ;;
            2) run_full_update ;;
            3)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please select 1-3."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..." -r
    done
}

# ==============================================================================
# CLI Argument Parsing
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}brew-update${NC} v${VERSION} - Homebrew Package Manager

${BOLD}USAGE${NC}
    $SCRIPT_NAME [OPTIONS]
    $SCRIPT_NAME add [--cask|--brew|--mas|--vscode] PACKAGE

${BOLD}OPTIONS${NC}
    -d, --daily       Run daily update (upgrade all installed packages)
    -f, --full        Run full update (sync Brewfile + upgrade all)
    -q, --quiet       Suppress colored output and progress messages
    -h, --help        Show this help message
    -v, --version     Show version number

${BOLD}ADD PACKAGE${NC}
    add PACKAGE       Add package to Brewfile
    --cask            Add as cask package
    --brew            Add as brew formula (default)
    --mas             Add as Mac App Store app
    --vscode          Add as VSCode extension

${BOLD}ENVIRONMENT VARIABLES${NC}
    BREW_UPDATE_LOG_DIR   Log directory (default: /tmp)
    BREW_UPDATE_LOG       Full path to log file
    BREWFILE              Path to Brewfile (default: ~/dotfiles/Brewfile)

${BOLD}EXAMPLES${NC}
    # Interactive mode
    $SCRIPT_NAME

    # Automated updates
    $SCRIPT_NAME -d          # Daily update
    $SCRIPT_NAME -f          # Full update
    $SCRIPT_NAME -dq         # Daily + quiet (for cron)
    $SCRIPT_NAME -fq         # Full + quiet (for cron)

    # Add packages
    $SCRIPT_NAME add vim                    # Add brew formula
    $SCRIPT_NAME add --cask docker          # Add cask
    $SCRIPT_NAME add --mas Xcode            # Add Mac App Store app

${BOLD}CRON EXAMPLES${NC}
    # Daily update at 9am
    0 9 * * * ~/.zsh/scripts/brew-update.sh -dq

    # Full update every Sunday at 10am
    0 10 * * 0 ~/.zsh/scripts/brew-update.sh -fq

EOF
}

parse_args() {
    local add_mode=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--daily)
                CRON_MODE=true
                ACTION="daily"
                shift
                ;;
            -f|--full)
                CRON_MODE=true
                ACTION="full"
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=true
                LOG_QUIET=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            -a|--add|add)
                add_mode=true
                shift
                ;;
            --cask)
                ADD_PACKAGE_TYPE="cask"
                shift
                ;;
            --brew)
                ADD_PACKAGE_TYPE="brew"
                shift
                ;;
            --mas)
                ADD_PACKAGE_TYPE="mas"
                shift
                ;;
            --vscode)
                ADD_PACKAGE_TYPE="vscode"
                shift
                ;;
            -*)
                # Handle combined short flags like -dq, -fq
                local flags="${1#-}"
                shift
                for (( i=0; i<${#flags}; i++ )); do
                    local flag="${flags:$i:1}"
                    case "$flag" in
                        d) CRON_MODE=true; ACTION="daily" ;;
                        f) CRON_MODE=true; ACTION="full" ;;
                        q) QUIET_MODE=true; LOG_QUIET=true ;;
                        h) show_help; exit 0 ;;
                        v) echo "$SCRIPT_NAME version $VERSION"; exit 0 ;;
                        a) add_mode=true ;;
                        *) die "Unknown option: -$flag" ;;
                    esac
                done
                ;;
            *)
                if [[ "$add_mode" == "true" ]] && [[ -z "$ADD_PACKAGE_NAME" ]]; then
                    ADD_PACKAGE_NAME="$1"
                    shift
                else
                    die "Unknown argument: $1"
                fi
                ;;
        esac
    done
    
    # Handle add action
    if [[ "$add_mode" == "true" ]]; then
        if [[ -z "$ADD_PACKAGE_NAME" ]]; then
            die "Package name required. Usage: $SCRIPT_NAME add [--cask|--brew] PACKAGE"
        fi
        ACTION="add"
    fi
}

# ==============================================================================
# Main Entry Point
# ==============================================================================

main() {
    parse_args "$@"
    
    # Initialize logging
    local log_file="${BREW_UPDATE_LOG:-$DEFAULT_LOG_FILE}"
    log_init "$log_file"
    
    # Check prerequisites
    check_homebrew
    check_brewfile
    
    log_start "$SCRIPT_NAME"
    log_debug "Brewfile: $BREWFILE"
    log_debug "Mode: ${ACTION:-interactive}"
    
    # Handle add action
    if [[ "$ACTION" == "add" ]]; then
        add_package_to_brewfile "$ADD_PACKAGE_NAME" "$ADD_PACKAGE_TYPE"
        log_end "$SCRIPT_NAME"
        exit 0
    fi
    
    # Handle cron/automated modes
    if [[ "$CRON_MODE" == "true" ]]; then
        case "$ACTION" in
            daily) run_daily_update ;;
            full)
                show_package_analysis
                run_full_update
                ;;
        esac
        
        log_end "$SCRIPT_NAME"
        exit 0
    fi
    
    # Interactive mode (default)
    run_interactive_mode
}

# ==============================================================================
# Entry Point
# ==============================================================================

main "$@"
