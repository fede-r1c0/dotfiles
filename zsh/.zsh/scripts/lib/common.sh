#!/bin/bash
# lib/common.sh - Shared utilities for shell scripts
#
# This library provides common functions used across multiple scripts.
# Source this file at the beginning of your script:
#   source "${SCRIPT_DIR}/lib/common.sh"
#
# Provides:
#   - Platform detection
#   - Command validation
#   - Safe error handling
#   - Path utilities

# Prevent double-sourcing
[[ -n "${_LIB_COMMON_LOADED:-}" ]] && return 0
readonly _LIB_COMMON_LOADED=1

# ==============================================================================
# Script Metadata
# ==============================================================================

# Get the directory of the script that sourced this library
# Usage: source "${SCRIPT_DIR}/lib/common.sh"
get_script_dir() {
    local source="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    local dir
    dir="$(cd "$(dirname "$source")" && pwd)"
    echo "$dir"
}

# ==============================================================================
# Platform Detection
# ==============================================================================

# Detect OS type
# Returns: macos, linux, windows, or unknown
detect_os() {
    local os
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    
    case "$os" in
        darwin)  echo "macos" ;;
        linux)   echo "linux" ;;
        mingw*|msys*|cygwin*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

# Detect CPU architecture
# Returns: arm64, x64, or the raw architecture
detect_arch() {
    local arch
    arch="$(uname -m)"
    
    case "$arch" in
        arm64|aarch64) echo "arm64" ;;
        x86_64|amd64)  echo "x64" ;;
        *)             echo "$arch" ;;
    esac
}

# Detect full platform string
# Returns: macos-arm64, linux-x64, etc.
detect_platform() {
    echo "$(detect_os)-$(detect_arch)"
}

# Check if running on macOS
is_macos() {
    [[ "$(detect_os)" == "macos" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(detect_os)" == "linux" ]]
}

# Check if running on Apple Silicon
is_apple_silicon() {
    is_macos && [[ "$(detect_arch)" == "arm64" ]]
}

# ==============================================================================
# Command Utilities
# ==============================================================================

# Check if a command exists
# Usage: command_exists brew && echo "Homebrew installed"
command_exists() {
    command -v "$1" &>/dev/null
}

# Require a command to exist, die if not found
# Usage: require_command brew "Install Homebrew from https://brew.sh"
require_command() {
    local cmd="$1"
    local install_hint="${2:-}"
    
    if ! command_exists "$cmd"; then
        local msg="Required command not found: $cmd"
        [[ -n "$install_hint" ]] && msg="$msg. $install_hint"
        die "$msg"
    fi
}

# Require multiple commands
# Usage: require_commands git brew mas
require_commands() {
    local cmd
    for cmd in "$@"; do
        require_command "$cmd"
    done
}

# ==============================================================================
# Error Handling
# ==============================================================================

# Die with an error message
# Usage: die "Something went wrong" [exit_code]
die() {
    local msg="${1:-Unknown error}"
    local code="${2:-1}"
    
    # Use log_error if available, otherwise plain echo
    if declare -f log_error &>/dev/null; then
        log_error "$msg"
    else
        printf 'ERROR: %s\n' "$msg" >&2
    fi
    
    exit "$code"
}

# Die if last command failed
# Usage: some_command || die_on_error "Command failed"
die_on_error() {
    local exit_code=$?
    local msg="${1:-Command failed}"
    
    if [[ $exit_code -ne 0 ]]; then
        die "$msg" "$exit_code"
    fi
}

# ==============================================================================
# Path Utilities
# ==============================================================================

# Get absolute path (works even if path doesn't exist)
# Usage: abs_path=$(get_absolute_path "./relative/path")
get_absolute_path() {
    local path="$1"
    
    # If it's already absolute, just normalize it
    if [[ "$path" == /* ]]; then
        echo "$path"
        return
    fi
    
    # Make it absolute
    echo "$(pwd)/$path"
}

# Check if a path is inside another path
# Usage: is_path_inside "/home/user/project" "/home/user" && echo "yes"
is_path_inside() {
    local child="$1"
    local parent="$2"
    
    # Normalize paths
    child="$(get_absolute_path "$child")"
    parent="$(get_absolute_path "$parent")"
    
    [[ "$child" == "$parent"/* ]] || [[ "$child" == "$parent" ]]
}

# ==============================================================================
# String Utilities
# ==============================================================================

# Trim whitespace from string
# Usage: trimmed=$(trim "  hello  ")
trim() {
    local str="$1"
    # Remove leading whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    # Remove trailing whitespace
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Check if string is empty or whitespace only
# Usage: is_blank "  " && echo "blank"
is_blank() {
    local str="$1"
    [[ -z "$(trim "$str")" ]]
}

# Convert string to lowercase
# Usage: lower=$(to_lower "HELLO")
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
# Usage: upper=$(to_upper "hello")
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# ==============================================================================
# Array Utilities
# ==============================================================================

# Check if array contains element
# Usage: array_contains "needle" "${haystack[@]}" && echo "found"
array_contains() {
    local needle="$1"
    shift
    local element
    for element in "$@"; do
        [[ "$element" == "$needle" ]] && return 0
    done
    return 1
}

# Join array elements with delimiter
# Usage: joined=$(array_join "," "${array[@]}")
array_join() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf '%s' "$first" "${@/#/$delimiter}"
}

# ==============================================================================
# User Interaction
# ==============================================================================

# Ask for confirmation
# Usage: confirm "Delete files?" && rm -rf files/
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    
    local yn_prompt
    if [[ "$default" == "y" ]]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi
    
    local reply
    read -p "$prompt $yn_prompt " -n 1 -r reply
    echo
    
    # Use default if empty
    [[ -z "$reply" ]] && reply="$default"
    
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Ask for input with default value
# Usage: name=$(prompt_input "Enter name" "default_name")
prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local reply
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " -r reply
        echo "${reply:-$default}"
    else
        read -p "$prompt: " -r reply
        echo "$reply"
    fi
}

# ==============================================================================
# File Utilities
# ==============================================================================

# Create backup of file
# Usage: backup_file "/path/to/file"
backup_file() {
    local file="$1"
    local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        echo "$backup"
    fi
}

# Check if file is readable
# Usage: require_readable_file "/path/to/file"
require_readable_file() {
    local file="$1"
    local desc="${2:-File}"
    
    if [[ ! -f "$file" ]]; then
        die "$desc not found: $file"
    fi
    
    if [[ ! -r "$file" ]]; then
        die "$desc is not readable: $file"
    fi
}

# Check if directory is writable
# Usage: require_writable_dir "/path/to/dir"
require_writable_dir() {
    local dir="$1"
    local desc="${2:-Directory}"
    
    if [[ ! -d "$dir" ]]; then
        die "$desc not found: $dir"
    fi
    
    if [[ ! -w "$dir" ]]; then
        die "$desc is not writable: $dir"
    fi
}
