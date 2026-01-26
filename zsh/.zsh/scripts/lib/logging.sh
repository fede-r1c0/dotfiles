#!/bin/bash
# lib/logging.sh - Logging utilities for shell scripts
#
# This library provides consistent logging functions with support for:
#   - Multiple log levels (debug, info, warn, error)
#   - File and console output
#   - Timestamps
#   - Quiet mode
#
# Source this file after colors.sh:
#   source "${SCRIPT_DIR}/lib/colors.sh"
#   source "${SCRIPT_DIR}/lib/logging.sh"

# Prevent double-sourcing
[[ -n "${_LIB_LOGGING_LOADED:-}" ]] && return 0
readonly _LIB_LOGGING_LOADED=1

# ==============================================================================
# Configuration
# ==============================================================================

# Log levels (can be overridden before sourcing)
LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_FILE="${LOG_FILE:-}"
LOG_QUIET="${LOG_QUIET:-false}"
LOG_TIMESTAMPS="${LOG_TIMESTAMPS:-true}"
LOG_TO_FILE="${LOG_TO_FILE:-true}"

# Get numeric log level value
_get_log_level_value() {
    local level="$1"
    case "$level" in
        debug)  echo 0 ;;
        info)   echo 1 ;;
        warn)   echo 2 ;;
        error)  echo 3 ;;
        silent) echo 4 ;;
        *)      echo 1 ;;  # default to info
    esac
}

# ==============================================================================
# Internal Functions
# ==============================================================================

# Get current timestamp
_log_timestamp() {
    if [[ "$LOG_TIMESTAMPS" == "true" ]]; then
        date '+%Y-%m-%d %H:%M:%S'
    fi
}

# Check if log level should be printed
_should_log() {
    local level="$1"
    local current_level
    local message_level
    
    current_level="$(_get_log_level_value "$LOG_LEVEL")"
    message_level="$(_get_log_level_value "$level")"
    
    [[ $message_level -ge $current_level ]]
}

# Convert to uppercase (bash 3.2 compatible)
_to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Format log message
_format_log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    local level_upper
    
    timestamp="$(_log_timestamp)"
    level_upper="$(_to_upper "$level")"
    
    if [[ -n "$timestamp" ]]; then
        echo "[$timestamp] [$level_upper] $message"
    else
        echo "[$level_upper] $message"
    fi
}

# Write to log file
_write_to_log_file() {
    local message="$1"
    
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# ==============================================================================
# Public Functions
# ==============================================================================

# Initialize logging
# Usage: log_init "/path/to/logfile.log"
log_init() {
    local log_file="${1:-}"
    local log_dir
    
    if [[ -n "$log_file" ]]; then
        LOG_FILE="$log_file"
        log_dir="$(dirname "$LOG_FILE")"
        
        # Create log directory if it doesn't exist
        if [[ ! -d "$log_dir" ]]; then
            mkdir -p "$log_dir" 2>/dev/null || {
                echo "Warning: Cannot create log directory: $log_dir" >&2
                LOG_TO_FILE=false
                return 1
            }
        fi
        
        # Test if we can write to log file
        if ! touch "$LOG_FILE" 2>/dev/null; then
            echo "Warning: Cannot write to log file: $LOG_FILE" >&2
            LOG_TO_FILE=false
            return 1
        fi
    fi
}

# Set log level
# Usage: log_set_level "debug"
log_set_level() {
    local level="$1"
    
    case "$level" in
        debug|info|warn|error|silent)
            LOG_LEVEL="$level"
            ;;
        *)
            echo "Invalid log level: $level. Valid levels: debug, info, warn, error, silent" >&2
            return 1
            ;;
    esac
}

# Enable quiet mode (no console output)
# Usage: log_quiet_mode
log_quiet_mode() {
    LOG_QUIET=true
}

# Disable timestamps
# Usage: log_no_timestamps
log_no_timestamps() {
    LOG_TIMESTAMPS=false
}

# ==============================================================================
# Log Functions
# ==============================================================================

# Debug log (verbose, for troubleshooting)
# Usage: log_debug "Variable x = $x"
log_debug() {
    local message="$*"
    
    if ! _should_log "debug"; then
        return 0
    fi
    
    local formatted
    formatted="$(_format_log_message "debug" "$message")"
    
    _write_to_log_file "$formatted"
    
    if [[ "$LOG_QUIET" != "true" ]]; then
        # Use color if available
        if [[ -n "${DIM:-}" ]]; then
            printf '%b%s%b\n' "$DIM" "$formatted" "$NC"
        else
            echo "$formatted"
        fi
    fi
}

# Info log (general information)
# Usage: log_info "Starting process..."
log_info() {
    local message="$*"
    
    if ! _should_log "info"; then
        return 0
    fi
    
    local formatted
    formatted="$(_format_log_message "info" "$message")"
    
    _write_to_log_file "$formatted"
    
    if [[ "$LOG_QUIET" != "true" ]]; then
        if [[ -n "${GREEN:-}" ]]; then
            printf '%b✓%b %s\n' "$GREEN" "$NC" "$message"
        else
            echo "$formatted"
        fi
    fi
}

# Warning log (non-fatal issues)
# Usage: log_warn "Config file missing, using defaults"
log_warn() {
    local message="$*"
    
    if ! _should_log "warn"; then
        return 0
    fi
    
    local formatted
    formatted="$(_format_log_message "warn" "$message")"
    
    _write_to_log_file "$formatted"
    
    if [[ "$LOG_QUIET" != "true" ]]; then
        if [[ -n "${YELLOW:-}" ]]; then
            printf '%b⚠%b %s\n' "$YELLOW" "$NC" "$message" >&2
        else
            echo "$formatted" >&2
        fi
    fi
}

# Error log (fatal or serious issues)
# Usage: log_error "Failed to connect to database"
log_error() {
    local message="$*"
    
    if ! _should_log "error"; then
        return 0
    fi
    
    local formatted
    formatted="$(_format_log_message "error" "$message")"
    
    _write_to_log_file "$formatted"
    
    if [[ "$LOG_QUIET" != "true" ]]; then
        if [[ -n "${RED:-}" ]]; then
            printf '%b✗%b %s\n' "$RED" "$NC" "$message" >&2
        else
            echo "$formatted" >&2
        fi
    fi
}

# Success log (task completed successfully)
# Usage: log_success "Build completed"
log_success() {
    local message="$*"
    
    if ! _should_log "info"; then
        return 0
    fi
    
    local formatted
    formatted="$(_format_log_message "info" "$message")"
    
    _write_to_log_file "$formatted"
    
    if [[ "$LOG_QUIET" != "true" ]]; then
        if [[ -n "${GREEN:-}" ]]; then
            printf '%b✓%b %s\n' "$GREEN" "$NC" "$message"
        else
            echo "$formatted"
        fi
    fi
}

# Plain log (no prefix, always shown unless silent)
# Usage: log "Raw message"
log() {
    local message="$*"
    local timestamp
    
    timestamp="$(_log_timestamp)"
    local formatted
    
    if [[ -n "$timestamp" ]]; then
        formatted="[$timestamp] $message"
    else
        formatted="$message"
    fi
    
    _write_to_log_file "$formatted"
    
    if [[ "$LOG_QUIET" != "true" ]] && [[ "$LOG_LEVEL" != "silent" ]]; then
        echo "$message"
    fi
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Log a command and its output
# Usage: log_cmd "npm install"
log_cmd() {
    local cmd="$*"
    log_debug "Running: $cmd"
    
    if eval "$cmd"; then
        log_debug "Command succeeded: $cmd"
        return 0
    else
        local exit_code=$?
        log_error "Command failed (exit $exit_code): $cmd"
        return $exit_code
    fi
}

# Log section header
# Usage: log_section "Installing Dependencies"
log_section() {
    local title="$*"
    local line
    line="$(printf '=%.0s' {1..60})"
    
    log ""
    if [[ -n "${BLUE:-}" ]] && [[ "$LOG_QUIET" != "true" ]]; then
        printf '%b%s%b\n' "$BLUE" "$line" "$NC"
        printf '%b%s%b\n' "$BLUE" "$title" "$NC"
        printf '%b%s%b\n' "$BLUE" "$line" "$NC"
    else
        log "$line"
        log "$title"
        log "$line"
    fi
    log ""
    
    _write_to_log_file "$line"
    _write_to_log_file "$title"
    _write_to_log_file "$line"
}

# Log script start
# Usage: log_start "brew-update.sh"
log_start() {
    local script_name="${1:-$(basename "$0")}"
    
    log_section "Starting: $script_name"
    log_debug "Platform: $(detect_platform 2>/dev/null || echo 'unknown')"
    log_debug "Log file: ${LOG_FILE:-none}"
    log_debug "Log level: $LOG_LEVEL"
}

# Log script end
# Usage: log_end
log_end() {
    local script_name="${1:-$(basename "$0")}"
    local exit_code="${2:-0}"
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Completed: $script_name"
    else
        log_error "Failed: $script_name (exit code: $exit_code)"
    fi
    
    if [[ -n "$LOG_FILE" ]] && [[ "$LOG_QUIET" != "true" ]]; then
        log_info "Log saved to: $LOG_FILE"
    fi
}
