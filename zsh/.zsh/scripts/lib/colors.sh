#!/bin/bash
# lib/colors.sh - Terminal color utilities
#
# This library provides ANSI color codes and styled output functions.
# Colors are automatically disabled when:
#   - Output is not a terminal (piping)
#   - NO_COLOR environment variable is set
#   - TERM is "dumb"
#
# Source this file before logging.sh:
#   source "${SCRIPT_DIR}/lib/colors.sh"
#   source "${SCRIPT_DIR}/lib/logging.sh"

# Prevent double-sourcing
[[ -n "${_LIB_COLORS_LOADED:-}" ]] && return 0
readonly _LIB_COLORS_LOADED=1

# ==============================================================================
# Color Detection
# ==============================================================================

# Check if colors should be enabled
_should_use_colors() {
    # Respect NO_COLOR standard (https://no-color.org/)
    [[ -n "${NO_COLOR:-}" ]] && return 1
    
    # Check if terminal is dumb
    [[ "${TERM:-}" == "dumb" ]] && return 1
    
    # Check if stdout is a terminal
    [[ -t 1 ]] || return 1
    
    # Check if terminal supports colors
    local colors
    colors="$(tput colors 2>/dev/null)" || return 1
    [[ "$colors" -ge 8 ]] || return 1
    
    return 0
}

# ==============================================================================
# Color Definitions
# ==============================================================================

# Initialize colors based on terminal support
init_colors() {
    if _should_use_colors; then
        # Basic colors
        readonly RED='\033[0;31m'
        readonly GREEN='\033[0;32m'
        readonly YELLOW='\033[1;33m'
        readonly BLUE='\033[0;34m'
        readonly MAGENTA='\033[0;35m'
        readonly CYAN='\033[0;36m'
        readonly WHITE='\033[1;37m'
        readonly GRAY='\033[0;90m'
        
        # Styles
        readonly BOLD='\033[1m'
        readonly DIM='\033[2m'
        readonly ITALIC='\033[3m'
        readonly UNDERLINE='\033[4m'
        readonly BLINK='\033[5m'
        readonly REVERSE='\033[7m'
        readonly HIDDEN='\033[8m'
        readonly STRIKETHROUGH='\033[9m'
        
        # Background colors
        readonly BG_RED='\033[41m'
        readonly BG_GREEN='\033[42m'
        readonly BG_YELLOW='\033[43m'
        readonly BG_BLUE='\033[44m'
        readonly BG_MAGENTA='\033[45m'
        readonly BG_CYAN='\033[46m'
        readonly BG_WHITE='\033[47m'
        
        # Bright colors
        readonly BRIGHT_RED='\033[0;91m'
        readonly BRIGHT_GREEN='\033[0;92m'
        readonly BRIGHT_YELLOW='\033[0;93m'
        readonly BRIGHT_BLUE='\033[0;94m'
        readonly BRIGHT_MAGENTA='\033[0;95m'
        readonly BRIGHT_CYAN='\033[0;96m'
        
        # Reset
        readonly NC='\033[0m'  # No Color / Reset
        readonly RESET='\033[0m'
        
        # Semantic colors (aliases)
        readonly SUCCESS="$GREEN"
        readonly WARNING="$YELLOW"
        readonly ERROR="$RED"
        readonly INFO="$BLUE"
        readonly MUTED="$GRAY"
        
        COLORS_ENABLED=true
    else
        # No colors - define empty strings
        readonly RED=''
        readonly GREEN=''
        readonly YELLOW=''
        readonly BLUE=''
        readonly MAGENTA=''
        readonly CYAN=''
        readonly WHITE=''
        readonly GRAY=''
        
        readonly BOLD=''
        readonly DIM=''
        readonly ITALIC=''
        readonly UNDERLINE=''
        readonly BLINK=''
        readonly REVERSE=''
        readonly HIDDEN=''
        readonly STRIKETHROUGH=''
        
        readonly BG_RED=''
        readonly BG_GREEN=''
        readonly BG_YELLOW=''
        readonly BG_BLUE=''
        readonly BG_MAGENTA=''
        readonly BG_CYAN=''
        readonly BG_WHITE=''
        
        readonly BRIGHT_RED=''
        readonly BRIGHT_GREEN=''
        readonly BRIGHT_YELLOW=''
        readonly BRIGHT_BLUE=''
        readonly BRIGHT_MAGENTA=''
        readonly BRIGHT_CYAN=''
        
        readonly NC=''
        readonly RESET=''
        
        readonly SUCCESS=''
        readonly WARNING=''
        readonly ERROR=''
        readonly INFO=''
        readonly MUTED=''
        
        COLORS_ENABLED=false
    fi
}

# ==============================================================================
# Output Functions
# ==============================================================================

# Print colored text
# Usage: cecho "red" "Error message"
cecho() {
    local color="$1"
    shift
    local message="$*"
    
    local color_code=""
    case "$color" in
        red)     color_code="$RED" ;;
        green)   color_code="$GREEN" ;;
        yellow)  color_code="$YELLOW" ;;
        blue)    color_code="$BLUE" ;;
        magenta) color_code="$MAGENTA" ;;
        cyan)    color_code="$CYAN" ;;
        white)   color_code="$WHITE" ;;
        gray)    color_code="$GRAY" ;;
        *)       color_code="" ;;
    esac
    
    printf '%b%s%b\n' "$color_code" "$message" "$NC"
}

# Print success message
# Usage: print_success "Operation completed"
print_success() {
    printf '%b✓%b %s\n' "$GREEN" "$NC" "$*"
}

# Print warning message
# Usage: print_warning "Something might be wrong"
print_warning() {
    printf '%b⚠%b %s\n' "$YELLOW" "$NC" "$*" >&2
}

# Print error message
# Usage: print_error "Something went wrong"
print_error() {
    printf '%b✗%b %s\n' "$RED" "$NC" "$*" >&2
}

# Print info message
# Usage: print_info "Processing files..."
print_info() {
    printf '%bℹ%b %s\n' "$BLUE" "$NC" "$*"
}

# Print debug message (gray/dim)
# Usage: print_debug "Variable value: $var"
print_debug() {
    printf '%b%s%b\n' "$DIM" "$*" "$NC"
}

# ==============================================================================
# Formatting Functions
# ==============================================================================

# Print a horizontal line
# Usage: print_line [width] [char]
print_line() {
    local width="${1:-80}"
    local char="${2:-─}"
    local line=""
    
    for ((i = 0; i < width; i++)); do
        line+="$char"
    done
    
    printf '%b%s%b\n' "$GRAY" "$line" "$NC"
}

# Print a header with lines
# Usage: print_header "Section Title"
print_header() {
    local title="$*"
    local width=80
    local title_len=${#title}
    local padding=$(( (width - title_len - 2) / 2 ))
    
    echo ""
    printf '%b' "$BLUE"
    printf '═%.0s' $(seq 1 $width)
    printf '%b\n' "$NC"
    
    printf '%b' "$BLUE"
    printf ' %.0s' $(seq 1 $padding)
    printf '%s' "$title"
    printf ' %.0s' $(seq 1 $padding)
    [[ $(( (width - title_len) % 2 )) -eq 1 ]] && printf ' '
    printf '%b\n' "$NC"
    
    printf '%b' "$BLUE"
    printf '═%.0s' $(seq 1 $width)
    printf '%b\n' "$NC"
    echo ""
}

# Print a box around text
# Usage: print_box "Title" "Content line 1" "Content line 2"
print_box() {
    local title="$1"
    shift
    local content=("$@")
    local width=60
    
    printf '%b╔' "$BLUE"
    printf '═%.0s' $(seq 1 $((width - 2)))
    printf '╗%b\n' "$NC"
    
    printf '%b║%b %-*s %b║%b\n' "$BLUE" "$BOLD" $((width - 4)) "$title" "$BLUE" "$NC"
    
    printf '%b╠' "$BLUE"
    printf '═%.0s' $(seq 1 $((width - 2)))
    printf '╣%b\n' "$NC"
    
    for line in "${content[@]}"; do
        printf '%b║%b %-*s %b║%b\n' "$BLUE" "$NC" $((width - 4)) "$line" "$BLUE" "$NC"
    done
    
    printf '%b╚' "$BLUE"
    printf '═%.0s' $(seq 1 $((width - 2)))
    printf '╝%b\n' "$NC"
}

# Print a spinner (for long operations)
# Usage: spin_start "Loading..."; do_something; spin_stop
_SPINNER_PID=""

spin_start() {
    local message="${1:-Processing...}"
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    # Don't show spinner if not a terminal
    [[ ! -t 1 ]] && return 0
    
    (
        while true; do
            for (( i=0; i<${#chars}; i++ )); do
                printf '\r%b%s%b %s' "$CYAN" "${chars:$i:1}" "$NC" "$message"
                sleep 0.1
            done
        done
    ) &
    _SPINNER_PID=$!
    
    # Hide cursor
    tput civis 2>/dev/null || true
}

spin_stop() {
    local success="${1:-true}"
    
    [[ -z "$_SPINNER_PID" ]] && return 0
    
    # Kill spinner
    kill "$_SPINNER_PID" 2>/dev/null
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    
    # Show cursor
    tput cnorm 2>/dev/null || true
    
    # Clear line
    printf '\r%*s\r' "$(tput cols 2>/dev/null || echo 80)" ""
}

# ==============================================================================
# Progress Functions
# ==============================================================================

# Print progress bar
# Usage: print_progress 50 100 "Downloading"
print_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-Progress}"
    local width=40
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf '\r%s [' "$label"
    printf '%b' "$GREEN"
    printf '█%.0s' $(seq 1 $filled) 2>/dev/null || true
    printf '%b' "$GRAY"
    printf '░%.0s' $(seq 1 $empty) 2>/dev/null || true
    printf '%b] %3d%%' "$NC" "$percent"
}

# Complete progress bar
# Usage: print_progress_done "Download complete"
print_progress_done() {
    local message="${1:-Done}"
    printf '\r%*s\r' "$(tput cols 2>/dev/null || echo 80)" ""
    print_success "$message"
}

# ==============================================================================
# Strip ANSI codes
# ==============================================================================

# Remove ANSI escape codes from string
# Usage: clean=$(strip_ansi "$colored_string")
strip_ansi() {
    local text="$*"
    # shellcheck disable=SC2001
    echo "$text" | sed 's/\x1b\[[0-9;]*m//g'
}

# ==============================================================================
# Initialize
# ==============================================================================

# Auto-initialize colors when sourced
init_colors
