#!/bin/bash
# brew-update.sh - Comprehensive Homebrew package management script
# Handles brew, cask, mas, taps, and VSCode extensions
# Supports both interactive mode and cron execution
#
# Usage:
#   Interactive mode:  ./brew-update.sh
#   Cron mode:         ./brew-update.sh --daily
#                      ./brew-update.sh --full
#                      ./brew-update.sh --daily --quiet
#
# Cron examples:
#   # Daily update at 9am
#   0 9 * * * /path/to/brew-update.sh --daily --quiet >> /tmp/brew-update.log 2>&1
#
#   # Full update every Sunday at 10am
#   0 10 * * 0 /path/to/brew-update.sh --full --quiet >> /tmp/brew-update.log 2>&1

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Ensure Homebrew is in PATH (important for cron)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Script configuration
readonly DOTFILES_ROOT="$HOME/dotfiles"
readonly BREWFILE="$DOTFILES_ROOT/Brewfile"
readonly TEMP_DIR=$(mktemp -d)
readonly INSTALLED_BREW_FILE="$TEMP_DIR/installed_brew.txt"
readonly INSTALLED_CASK_FILE="$TEMP_DIR/installed_cask.txt"
readonly INSTALLED_MAS_FILE="$TEMP_DIR/installed_mas.txt"
readonly BREWFILE_BREW_FILE="$TEMP_DIR/brewfile_brew.txt"
readonly BREWFILE_CASK_FILE="$TEMP_DIR/brewfile_cask.txt"
readonly BREWFILE_MAS_FILE="$TEMP_DIR/brewfile_mas.txt"

# Log configuration
readonly LOG_DIR="${BREW_UPDATE_LOG_DIR:-/tmp}"
readonly LOG_TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
readonly LOG_FILE="${BREW_UPDATE_LOG:-$LOG_DIR/brew-update_${LOG_TIMESTAMP}.log}"

# Ensure log directory exists (usually /tmp already exists, but check anyway)
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Mode flags
QUIET_MODE=false
CRON_MODE=false
ACTION=""

# Colors (disabled in quiet/cron mode)
setup_colors() {
    if [ "$QUIET_MODE" = true ] || [ ! -t 1 ]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        NC=''
    else
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        NC='\033[0m'
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Logging with timestamp (useful for cron)
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_msg="[$timestamp] $*"
    
    # Always write to log file
    echo "$log_msg" >> "$LOG_FILE"
    
    # Also print to stdout in non-quiet mode
    if [ "$QUIET_MODE" = false ]; then
        echo "$log_msg"
    fi
}

# Print with colors (respects quiet mode)
print_msg() {
    if [ "$QUIET_MODE" = false ]; then
        echo -e "$*"
    else
        # Strip ANSI codes for quiet mode
        echo -e "$*" | sed 's/\x1b\[[0-9;]*m//g'
    fi
}

# Error handling
error_exit() {
    log "ERROR: $1"
    print_msg "${RED}❌ Error: $1${NC}" >&2
    exit "${2:-1}"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v brew &> /dev/null; then
        error_exit "Homebrew is not installed. Please install it first: https://brew.sh"
    fi

    if [ ! -f "$BREWFILE" ]; then
        error_exit "Brewfile not found at $BREWFILE"
    fi
}

# ============================================================================
# Package Analysis Functions
# ============================================================================

# Extract package names from Brewfile
extract_brewfile_packages() {
    local brewfile="$1"
    grep -E '^brew "' "$brewfile" | sed 's/^brew "\([^"]*\)".*/\1/' | sed 's/@[^/]*$//' | sort -u > "$BREWFILE_BREW_FILE" || true
    grep -E '^cask "' "$brewfile" | sed 's/^cask "\([^"]*\)".*/\1/' | sort > "$BREWFILE_CASK_FILE" || true
    grep -E '^mas ' "$brewfile" | sed -n 's/.*id: *\([0-9]*\).*/\1/p' | sort > "$BREWFILE_MAS_FILE" || true
}

# Get installed packages
get_installed_packages() {
    print_msg "${BLUE}📦 Gathering installed package information...${NC}"
    brew leaves 2>/dev/null | sed 's/@.*$//' | sort -u > "$INSTALLED_BREW_FILE" || true
    brew list --cask 2>/dev/null | sort > "$INSTALLED_CASK_FILE" || true
    if command -v mas &> /dev/null; then
        mas list 2>/dev/null | awk '{print $1}' | sort > "$INSTALLED_MAS_FILE" || true
    else
        touch "$INSTALLED_MAS_FILE"
    fi
}

# Compare installed vs Brewfile (simplified for cron)
compare_packages() {
    local extra_installed=()
    
    print_msg "\n${BLUE}📊 Package Analysis${NC}"
    print_msg "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check brew packages
    print_msg "\n${YELLOW}🍺 Brew Packages:${NC}"
    local brewfile_count=$(wc -l < "$BREWFILE_BREW_FILE" | tr -d ' ')
    local installed_count=$(wc -l < "$INSTALLED_BREW_FILE" | tr -d ' ')
    print_msg "   Brewfile: $brewfile_count packages"
    print_msg "   Installed: $installed_count packages"
    
    local missing_install=$(comm -23 "$BREWFILE_BREW_FILE" "$INSTALLED_BREW_FILE" 2>/dev/null)
    local truly_missing=""
    local all_installed=$(brew list --formula 2>/dev/null | sed 's/@.*$//' | sort -u)
    
    if [ -n "$missing_install" ]; then
        while IFS= read -r pkg; do
            [ -z "$pkg" ] && continue
            local pkg_name="$pkg"
            if [[ "$pkg" == *"/"* ]]; then
                pkg_name="${pkg##*/}"
            fi
            pkg_name="${pkg_name%@*}"
            if ! echo "$all_installed" | grep -qE "^${pkg_name}$"; then
                truly_missing="${truly_missing}${pkg}\n"
            fi
        done <<< "$missing_install"
        
        if [ -n "$truly_missing" ]; then
            print_msg "   ${YELLOW}⚠️  Missing (will be installed):${NC}"
            echo -e "$truly_missing" | sed 's/^/      - /' | head -10
        fi
    fi
    
    local extra_brew=$(comm -13 "$BREWFILE_BREW_FILE" "$INSTALLED_BREW_FILE" 2>/dev/null)
    if [ -n "$extra_brew" ]; then
        print_msg "   ${YELLOW}⚠️  Installed but not in Brewfile:${NC}"
        echo "$extra_brew" | sed 's/^/      - /'
    fi
    
    # Check cask packages
    print_msg "\n${YELLOW}🍺 Cask Packages:${NC}"
    local caskfile_count=$(wc -l < "$BREWFILE_CASK_FILE" | tr -d ' ')
    local installed_cask_count=$(wc -l < "$INSTALLED_CASK_FILE" | tr -d ' ')
    print_msg "   Brewfile: $caskfile_count packages"
    print_msg "   Installed: $installed_cask_count packages"
    
    local missing_cask=$(comm -23 "$BREWFILE_CASK_FILE" "$INSTALLED_CASK_FILE" 2>/dev/null | head -10)
    if [ -n "$missing_cask" ]; then
        print_msg "   ${YELLOW}⚠️  Missing (will be installed):${NC}"
        echo "$missing_cask" | sed 's/^/      - /'
    fi
    
    local extra_cask=$(comm -13 "$BREWFILE_CASK_FILE" "$INSTALLED_CASK_FILE" 2>/dev/null)
    if [ -n "$extra_cask" ]; then
        print_msg "   ${YELLOW}⚠️  Installed but not in Brewfile:${NC}"
        echo "$extra_cask" | sed 's/^/      - /'
    fi
    
    # Check mas packages
    if [ -s "$BREWFILE_MAS_FILE" ] || [ -s "$INSTALLED_MAS_FILE" ]; then
        print_msg "\n${YELLOW}🍎 Mac App Store Packages:${NC}"
        local masfile_count=$(wc -l < "$BREWFILE_MAS_FILE" | tr -d ' ')
        local installed_mas_count=$(wc -l < "$INSTALLED_MAS_FILE" | tr -d ' ')
        print_msg "   Brewfile: $masfile_count packages"
        print_msg "   Installed: $installed_mas_count packages"
    fi
    
    # Check for outdated packages
    print_msg "\n${YELLOW}🔄 Outdated Packages:${NC}"
    local outdated_brew=$(brew outdated --formula 2>/dev/null | wc -l | tr -d ' ')
    local outdated_cask=$(brew outdated --cask 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$outdated_brew" -gt 0 ] || [ "$outdated_cask" -gt 0 ]; then
        print_msg "   ${YELLOW}Outdated brew packages: $outdated_brew${NC}"
        print_msg "   ${YELLOW}Outdated cask packages: $outdated_cask${NC}"
        
        if [ "$outdated_brew" -gt 0 ] && [ "$outdated_brew" -le 5 ]; then
            print_msg "\n   ${YELLOW}Outdated brew packages:${NC}"
            brew outdated --formula 2>/dev/null | sed 's/^/      - /'
        elif [ "$outdated_brew" -gt 5 ]; then
            print_msg "\n   ${YELLOW}Outdated brew packages (showing first 5):${NC}"
            brew outdated --formula 2>/dev/null | head -5 | sed 's/^/      - /'
            print_msg "      ... and $((outdated_brew - 5)) more"
        fi
        
        if [ "$outdated_cask" -gt 0 ] && [ "$outdated_cask" -le 5 ]; then
            print_msg "\n   ${YELLOW}Outdated cask packages:${NC}"
            brew outdated --cask 2>/dev/null | sed 's/^/      - /'
        elif [ "$outdated_cask" -gt 5 ]; then
            print_msg "\n   ${YELLOW}Outdated cask packages (showing first 5):${NC}"
            brew outdated --cask 2>/dev/null | head -5 | sed 's/^/      - /'
            print_msg "      ... and $((outdated_cask - 5)) more"
        fi
    else
        print_msg "   ${GREEN}✅ All packages are up to date${NC}"
    fi
    
    print_msg "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# Update Functions
# ============================================================================

# Update Homebrew
update_homebrew() {
    log "Starting Homebrew update"
    print_msg "\n${BLUE}🔄 Updating Homebrew...${NC}"
    if brew update; then
        log "Homebrew updated successfully"
        print_msg "${GREEN}✅ Homebrew updated successfully${NC}"
    else
        error_exit "Failed to update Homebrew"
    fi
}

# Daily update: update Homebrew and upgrade all packages
daily_update() {
    log "Starting daily update"
    print_msg "\n${BLUE}🔄 Daily Update: Updating Homebrew and upgrading packages...${NC}"
    
    # Update Homebrew
    if ! brew update; then
        error_exit "Failed to update Homebrew"
    fi
    log "Homebrew updated"
    print_msg "${GREEN}✅ Homebrew updated successfully${NC}"
    
    # Upgrade brew packages
    log "Upgrading brew packages"
    print_msg "\n${YELLOW}⬆️  Upgrading brew packages...${NC}"
    if brew upgrade --formula; then
        log "Brew packages upgraded successfully"
        print_msg "${GREEN}✅ Brew packages upgraded successfully${NC}"
    else
        log "WARNING: Some brew packages failed to upgrade"
        print_msg "${YELLOW}⚠️  Some brew packages failed to upgrade${NC}"
    fi
    
    # Upgrade cask packages
    log "Upgrading cask packages"
    print_msg "\n${YELLOW}⬆️  Upgrading cask packages...${NC}"
    if brew upgrade --cask; then
        log "Cask packages upgraded successfully"
        print_msg "${GREEN}✅ Cask packages upgraded successfully${NC}"
    else
        log "WARNING: Some cask packages failed to upgrade"
        print_msg "${YELLOW}⚠️  Some cask packages failed to upgrade${NC}"
    fi
    
    # Cleanup old versions
    cleanup_old_versions
    
    log "Daily update completed"
    print_msg "\n${GREEN}✅ Daily update completed${NC}"
    return 0
}

# Upgrade all packages (including those not in Brewfile)
upgrade_all_packages() {
    log "Upgrading all installed packages"
    print_msg "\n${BLUE}⬆️  Upgrading all installed packages...${NC}"
    
    local failed_packages=()
    
    print_msg "${YELLOW}   Upgrading brew packages...${NC}"
    if ! brew upgrade --formula; then
        failed_packages+=("brew packages")
    fi
    
    print_msg "${YELLOW}   Upgrading cask packages...${NC}"
    if ! brew upgrade --cask; then
        failed_packages+=("cask packages")
    fi
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log "WARNING: Some packages failed to upgrade: ${failed_packages[*]}"
        print_msg "${YELLOW}⚠️  Some packages failed to upgrade: ${failed_packages[*]}${NC}"
        return 1
    fi
    
    log "All packages upgraded successfully"
    print_msg "${GREEN}✅ All packages upgraded successfully${NC}"
    return 0
}

# Install/update packages from Brewfile
install_brewfile_packages() {
    local upgrade_flag="${1:---upgrade}"
    
    if [ "$upgrade_flag" = "--no-upgrade" ]; then
        log "Installing missing packages from Brewfile"
        print_msg "\n${BLUE}📦 Installing missing packages from Brewfile...${NC}"
    else
        log "Installing/updating packages from Brewfile"
        print_msg "\n${BLUE}📦 Installing/updating packages from Brewfile...${NC}"
    fi
    
    local bundle_output
    local bundle_exit_code
    
    bundle_output=$(brew bundle install --file="$BREWFILE" "$upgrade_flag" 2>&1)
    bundle_exit_code=$?
    
    if [ "$QUIET_MODE" = false ]; then
        echo "$bundle_output"
    fi
    
    if echo "$bundle_output" | grep -q "has failed!"; then
        local failed_count=$(echo "$bundle_output" | grep -c "has failed!" || echo "0")
        local tap_failures=$(echo "$bundle_output" | grep -c "Tapping.*has failed!" || echo "0")
        local extension_failures=$(echo "$bundle_output" | grep -c "Installing.*has failed!" || echo "0")
        
        if [ "$bundle_exit_code" -ne 0 ]; then
            log "WARNING: Some packages failed - taps: $tap_failures, extensions: $extension_failures, total: $failed_count"
            print_msg "\n${YELLOW}⚠️  Some packages failed to install/update${NC}"
            print_msg "${YELLOW}   Failed taps: $tap_failures${NC}"
            print_msg "${YELLOW}   Failed extensions: $extension_failures${NC}"
            
            if [ "$failed_count" -eq "$((tap_failures + extension_failures))" ]; then
                log "Core packages installed successfully (only taps/extensions failed)"
                print_msg "${GREEN}✅ Core packages (brew/cask/mas) installed/updated successfully${NC}"
                return 0
            fi
        fi
    fi
    
    if [ "$bundle_exit_code" -eq 0 ]; then
        log "Brewfile packages installed/updated successfully"
        print_msg "${GREEN}✅ All Brewfile packages installed/updated successfully${NC}"
        return 0
    else
        log "WARNING: Some packages from Brewfile failed to install/update"
        print_msg "${YELLOW}⚠️  Some packages from Brewfile failed to install/update${NC}"
        return 0
    fi
}

# Cleanup old versions
cleanup_old_versions() {
    log "Starting cleanup"
    print_msg "\n${BLUE}🧹 Cleaning up old Homebrew versions...${NC}"
    
    local cleanup_output=$(brew cleanup -s 2>&1)
    local freed_space=$(echo "$cleanup_output" | grep -E '^Pruned' | awk '{print $3, $4}' || echo "")
    
    if [ -n "$freed_space" ]; then
        log "Cleanup completed. Freed: $freed_space"
        print_msg "${GREEN}✅ Cleanup completed. Freed: $freed_space${NC}"
    else
        log "Cleanup completed"
        print_msg "${GREEN}✅ Cleanup completed${NC}"
    fi
}

# Full update
full_update() {
    log "Starting full update"
    print_msg "${BLUE}🚀 Starting full update...${NC}"
    
    update_homebrew
    install_brewfile_packages --upgrade
    upgrade_all_packages
    cleanup_old_versions
    
    log "Full update completed successfully"
    print_msg "\n${GREEN}✅ Full update completed successfully${NC}"
}

# ============================================================================
# Interactive Mode
# ============================================================================

show_menu() {
    print_msg "\n${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    print_msg "${BLUE}║                    Homebrew Package Manager                            ║${NC}"
    print_msg "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    print_msg ""
    print_msg "1) Daily Update - Update and upgrade all installed packages."
    print_msg "2) Full Update - Sync with Brewfile, install missing packages, upgrade all."
    print_msg "3) Exit"
    print_msg ""
    print_msg "${BLUE}ℹ️  Package analysis is shown above.${NC}"
    print_msg ""
}

interactive_mode() {
    print_msg "${GREEN}🍺 Homebrew Package Management Script${NC}"
    print_msg "${BLUE}Brewfile: $BREWFILE${NC}\n"
    
    get_installed_packages
    extract_brewfile_packages "$BREWFILE"
    compare_packages
    
    while true; do
        show_menu
        read -p "Select an option [1-3]: " choice
        echo ""
        
        case "$choice" in
            1)
                daily_update
                ;;
            2)
                full_update
                ;;
            3)
                print_msg "${GREEN}👋${NC}"
                exit 0
                ;;
            *)
                print_msg "${RED}Invalid option. Please select 1-3.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# ============================================================================
# Add Package to Brewfile
# ============================================================================

# Get package description from Homebrew using brew info (no curl needed)
get_package_description() {
    local package="$1"
    local package_type="${2:-brew}"
    local description=""
    local name=""
    local desc=""
    
    if [ "$package_type" = "cask" ]; then
        # Get info directly from brew info (no API call needed)
        local brew_info=$(brew info --cask "$package" 2>/dev/null)
        
        if [ -n "$brew_info" ]; then
            # Extract name (line after "==> Name")
            name=$(echo "$brew_info" | awk '/^==> Name$/{getline; print; exit}')
            
            # Extract description (line after "==> Description")
            desc=$(echo "$brew_info" | awk '/^==> Description$/{getline; print; exit}')
            
            # Format description: Name: Description (or just Description if no name)
            if [ -n "$name" ] && [ -n "$desc" ]; then
                description="$name: $desc"
            elif [ -n "$desc" ]; then
                description="$desc"
            elif [ -n "$name" ]; then
                description="$name"
            fi
        fi
        
        # Fallback if brew info fails
        if [ -z "$description" ]; then
            description=$(brew info --cask "$package" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' || echo "")
        fi
    else
        # For brew packages, use brew info
        description=$(brew info "$package" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' || echo "")
    fi
    
    echo "$description"
}

# Find insertion point in Brewfile for a package
find_insertion_point() {
    local brewfile="$1"
    local package_name="$2"
    local package_type="$3"
    local section_pattern="$4"
    
    # Find the section
    local section_start=$(grep -n "^${section_pattern}" "$brewfile" | head -1 | cut -d: -f1)
    if [ -z "$section_start" ]; then
        # Section doesn't exist, append to end
        echo $(($(wc -l < "$brewfile" | tr -d ' ') + 1))
        return
    fi
    
    # Find the end of the section (next comment line starting with # or end of file)
    local section_end=$(awk -v start="$section_start" 'NR > start && /^#[^ ]/ {print NR-1; exit}' "$brewfile")
    if [ -z "$section_end" ]; then
        section_end=$(wc -l < "$brewfile" | tr -d ' ')
    fi
    
    # Find alphabetical insertion point within section
    local last_package_line=$section_start
    local package_lower=$(echo "$package_name" | tr '[:upper:]' '[:lower:]')
    
    # First, find the last package line in the section
    for ((line=$section_start+1; line<=$section_end; line++)); do
        local line_content=$(sed -n "${line}p" "$brewfile")
        # Skip empty lines and comments
        if [[ "$line_content" =~ ^[[:space:]]*$ ]] || [[ "$line_content" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Check if this line contains a package of the same type
        if echo "$line_content" | grep -qE "^${package_type} \""; then
            last_package_line=$line
        fi
    done
    
    # Default: insert after the last package in the section
    local insert_line=$((last_package_line + 1))
    
    # Try to find alphabetical position
    for ((line=$section_start+1; line<=$section_end; line++)); do
        local line_content=$(sed -n "${line}p" "$brewfile")
        # Skip empty lines and comments
        if [[ "$line_content" =~ ^[[:space:]]*$ ]] || [[ "$line_content" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Extract package name from line (handle quotes and comments)
        local existing_package=$(echo "$line_content" | sed -n "s/.*${package_type} \"\([^\"]*\)\".*/\1/p" | head -1)
        if [ -n "$existing_package" ]; then
            local existing_lower=$(echo "$existing_package" | tr '[:upper:]' '[:lower:]')
            if [[ "$package_lower" < "$existing_lower" ]]; then
                insert_line=$line
                break
            fi
        fi
    done
    
    echo "$insert_line"
}

# Add package to Brewfile
add_package_to_brewfile() {
    local package_name="$1"
    local package_type="${2:-brew}"
    local description="${3:-}"
    
    # Validate package exists
    if [ "$package_type" = "cask" ]; then
        if ! brew info --cask "$package_name" &>/dev/null; then
            error_exit "Cask '$package_name' not found in Homebrew"
        fi
    elif [ "$package_type" = "brew" ]; then
        if ! brew info "$package_name" &>/dev/null; then
            error_exit "Formula '$package_name' not found in Homebrew"
        fi
    fi
    
    # Get description if not provided
    if [ -z "$description" ]; then
        description=$(get_package_description "$package_name" "$package_type")
    fi
    
    # Check if package already exists in Brewfile
    if grep -qE "^${package_type} \"${package_name}\"" "$BREWFILE"; then
        print_msg "${YELLOW}⚠️  Package '$package_name' already exists in Brewfile${NC}"
        return 1
    fi
    
    # Determine section based on package type
    local section_pattern=""
    case "$package_type" in
        brew)
            section_pattern="# Binaries"
            ;;
        cask)
            # Check if it's a font
            if [[ "$package_name" =~ ^font- ]]; then
                section_pattern="# Fonts"
            else
                section_pattern="# Apps"
            fi
            ;;
        mas)
            section_pattern="# Mac App Store"
            ;;
        vscode)
            section_pattern="# VSCode extensions"
            ;;
    esac
    
    # Find insertion point
    local insert_line=$(find_insertion_point "$BREWFILE" "$package_name" "$package_type" "$section_pattern")
    
    # Format the line
    local new_line=""
    if [ "$package_type" = "mas" ]; then
        # For MAS, we need the app ID - this is more complex, so we'll add a placeholder
        new_line="mas \"${package_name}\", id: PLACEHOLDER_ID # ${description}"
        print_msg "${YELLOW}⚠️  Note: MAS packages require an ID. Please update the PLACEHOLDER_ID manually.${NC}"
    elif [ "$package_type" = "vscode" ]; then
        new_line="vscode \"${package_name}\""
    else
        new_line="${package_type} \"${package_name}\" # ${description}"
    fi
    
    # Create backup
    cp "$BREWFILE" "${BREWFILE}.bak"
    
    # Insert the line using awk (more portable than sed -i)
    local total_lines=$(wc -l < "$BREWFILE" | tr -d ' ')
    
    if [ "$insert_line" -gt "$total_lines" ]; then
        # Append to end
        echo "$new_line" >> "$BREWFILE"
    else
        # Insert at specific line using awk (insert before the line)
        awk -v line="$insert_line" -v new="$new_line" '
            NR == line {print new}
            {print}
        ' "$BREWFILE" > "${BREWFILE}.tmp" && mv "${BREWFILE}.tmp" "$BREWFILE"
    fi
    
    # Remove backup
    rm -f "${BREWFILE}.bak"
    
    log "Added ${package_type} package '$package_name' to Brewfile"
    print_msg "${GREEN}✅ Added ${package_type} package '$package_name' to Brewfile${NC}"
    print_msg "${BLUE}   Location: line $insert_line${NC}"
    
    return 0
}

# ============================================================================
# CLI Argument Parsing
# ============================================================================

show_help() {
    cat << EOF
🍺 Homebrew Package Manager

Usage: $(basename "$0") [OPTIONS]

Options:
  -d, --daily   Run daily update (update + upgrade all + cleanup)
  -f, --full    Run full update (update + sync Brewfile + upgrade all + cleanup)
  -q, --quiet   Suppress colored output and progress messages (ideal for cron)
  -h, --help    Show this help message

Flags can be combined: -dq (daily + quiet), -fq (full + quiet)

Environment Variables:
  BREW_UPDATE_LOG_DIR   Directory for log files (default: /tmp)
  BREW_UPDATE_LOG       Full path to specific log file (overrides default)

Log Files:
  Logs are automatically saved to:
    /tmp/brew-update_YYYYMMDD_HHMMSS.log (default)
  
  Or use BREW_UPDATE_LOG to specify a custom location:
    BREW_UPDATE_LOG=/var/log/brew.log $(basename "$0") -fq

Examples:
  # Interactive mode
  $(basename "$0")

  # Daily update with short flags
  $(basename "$0") -d
  $(basename "$0") -dq    # daily + quiet

  # Full update with short flags
  $(basename "$0") -f
  $(basename "$0") -fq    # full + quiet

  # Custom log directory
  BREW_UPDATE_LOG_DIR=/var/log $(basename "$0") -dq

  # Cron job examples (add to crontab -e):
  # Daily update at 9am (logs saved to /tmp/)
  0 9 * * * ~/.zsh/scripts/brew-update.sh -dq

  # Full update every Sunday at 10am with custom log directory
  0 10 * * 0 BREW_UPDATE_LOG_DIR=$HOME/logs ~/.zsh/scripts/brew-update.sh -fq
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --daily|-d)
                CRON_MODE=true
                ACTION="daily"
                shift
                ;;
            --full|-f)
                CRON_MODE=true
                ACTION="full"
                shift
                ;;
            --quiet|-q)
                QUIET_MODE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                # Handle combined short flags like -dq, -fq
                local flags="${1#-}"
                shift
                for (( i=0; i<${#flags}; i++ )); do
                    local flag="${flags:$i:1}"
                    case "$flag" in
                        d)
                            CRON_MODE=true
                            ACTION="daily"
                            ;;
                        f)
                            CRON_MODE=true
                            ACTION="full"
                            ;;
                        q)
                            QUIET_MODE=true
                            ;;
                        h)
                            show_help
                            exit 0
                            ;;
                        *)
                            echo "Unknown option: -$flag"
                            show_help
                            exit 1
                            ;;
                    esac
                done
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    parse_args "$@"
    setup_colors
    check_prerequisites
    
    # Log script start
    log "=== Brew Update Script Started ==="
    log "Log file: $LOG_FILE"
    log "Brewfile: $BREWFILE"
    
    if [ "$CRON_MODE" = true ]; then
        # Non-interactive mode (cron)
        log "Mode: $ACTION (cron)"
        
        case "$ACTION" in
            daily)
                daily_update
                ;;
            full)
                get_installed_packages
                extract_brewfile_packages "$BREWFILE"
                full_update
                ;;
        esac
        
        log "=== Brew Update Script Completed ==="
        
        # Show log location in non-quiet mode
        if [ "$QUIET_MODE" = false ]; then
            print_msg "\n${BLUE}📋 Log saved to: $LOG_FILE${NC}"
        fi
    else
        # Interactive mode
        log "Mode: interactive"
        interactive_mode
        log "=== Brew Update Script Completed ==="
        print_msg "\n${BLUE}📋 Log saved to: $LOG_FILE${NC}"
    fi
}

main "$@"
