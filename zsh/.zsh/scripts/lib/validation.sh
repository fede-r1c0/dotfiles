#!/bin/bash
# lib/validation.sh - Input validation utilities
#
# This library provides functions for validating:
#   - User inputs
#   - File paths
#   - Git repositories
#   - Package names
#   - Network resources
#
# Source this file after common.sh:
#   source "${SCRIPT_DIR}/lib/common.sh"
#   source "${SCRIPT_DIR}/lib/validation.sh"

# Prevent double-sourcing
[[ -n "${_LIB_VALIDATION_LOADED:-}" ]] && return 0
readonly _LIB_VALIDATION_LOADED=1

# ==============================================================================
# String Validation
# ==============================================================================

# Check if string matches a regex pattern
# Usage: validate_regex "test@example.com" '^[^@]+@[^@]+\.[^@]+$' && echo "valid email"
validate_regex() {
    local value="$1"
    local pattern="$2"
    
    [[ "$value" =~ $pattern ]]
}

# Validate string is not empty
# Usage: validate_not_empty "$var" "Variable name"
validate_not_empty() {
    local value="$1"
    local name="${2:-Value}"
    
    if [[ -z "$value" ]]; then
        die "$name cannot be empty"
    fi
}

# Validate string length
# Usage: validate_length "$password" 8 64 "Password"
validate_length() {
    local value="$1"
    local min="${2:-0}"
    local max="${3:-999999}"
    local name="${4:-Value}"
    local len="${#value}"
    
    if [[ $len -lt $min ]]; then
        die "$name must be at least $min characters (got $len)"
    fi
    
    if [[ $len -gt $max ]]; then
        die "$name must be at most $max characters (got $len)"
    fi
}

# Validate alphanumeric string (with optional extras)
# Usage: validate_alphanumeric "$username" "Username" "-_"
validate_alphanumeric() {
    local value="$1"
    local name="${2:-Value}"
    local extra="${3:-}"
    
    local pattern="^[a-zA-Z0-9${extra}]+$"
    
    if ! [[ "$value" =~ $pattern ]]; then
        die "$name must contain only alphanumeric characters${extra:+ and: $extra}"
    fi
}

# ==============================================================================
# Numeric Validation
# ==============================================================================

# Validate integer
# Usage: validate_integer "$count" "Count"
validate_integer() {
    local value="$1"
    local name="${2:-Value}"
    
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        die "$name must be an integer"
    fi
}

# Validate positive integer
# Usage: validate_positive_integer "$port" "Port"
validate_positive_integer() {
    local value="$1"
    local name="${2:-Value}"
    
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" -le 0 ]]; then
        die "$name must be a positive integer"
    fi
}

# Validate integer range
# Usage: validate_range "$port" 1 65535 "Port"
validate_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local name="${4:-Value}"
    
    validate_integer "$value" "$name"
    
    if [[ "$value" -lt "$min" ]] || [[ "$value" -gt "$max" ]]; then
        die "$name must be between $min and $max (got $value)"
    fi
}

# ==============================================================================
# File System Validation
# ==============================================================================

# Validate file exists and is readable
# Usage: validate_file "$config_file" "Config file"
validate_file() {
    local path="$1"
    local name="${2:-File}"
    
    if [[ ! -e "$path" ]]; then
        die "$name does not exist: $path"
    fi
    
    if [[ ! -f "$path" ]]; then
        die "$name is not a file: $path"
    fi
    
    if [[ ! -r "$path" ]]; then
        die "$name is not readable: $path"
    fi
}

# Validate directory exists
# Usage: validate_directory "$output_dir" "Output directory"
validate_directory() {
    local path="$1"
    local name="${2:-Directory}"
    
    if [[ ! -e "$path" ]]; then
        die "$name does not exist: $path"
    fi
    
    if [[ ! -d "$path" ]]; then
        die "$name is not a directory: $path"
    fi
}

# Validate path is writable
# Usage: validate_writable "$log_file" "Log file"
validate_writable() {
    local path="$1"
    local name="${2:-Path}"
    
    # If file exists, check if writable
    if [[ -e "$path" ]]; then
        if [[ ! -w "$path" ]]; then
            die "$name is not writable: $path"
        fi
        return 0
    fi
    
    # If file doesn't exist, check if parent directory is writable
    local parent
    parent="$(dirname "$path")"
    
    if [[ ! -d "$parent" ]]; then
        die "Parent directory does not exist for $name: $parent"
    fi
    
    if [[ ! -w "$parent" ]]; then
        die "Cannot create $name in directory: $parent (not writable)"
    fi
}

# Validate safe path (no directory traversal)
# Usage: validate_safe_path "$user_input" "User path"
validate_safe_path() {
    local path="$1"
    local name="${2:-Path}"
    
    # Check for directory traversal attempts
    if [[ "$path" == *".."* ]]; then
        die "$name contains invalid path traversal: $path"
    fi
    
    # Check for null bytes (security)
    if [[ "$path" == *$'\0'* ]]; then
        die "$name contains invalid characters: $path"
    fi
}

# ==============================================================================
# Git Validation
# ==============================================================================

# Validate we're in a git repository
# Usage: validate_git_repo
validate_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        die "Not inside a git repository"
    fi
}

# Validate git branch exists
# Usage: validate_git_branch "main"
validate_git_branch() {
    local branch="$1"
    
    validate_git_repo
    
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        die "Branch does not exist: $branch"
    fi
}

# Validate git remote exists
# Usage: validate_git_remote "origin"
validate_git_remote() {
    local remote="$1"
    
    validate_git_repo
    
    if ! git remote | grep -qx "$remote"; then
        die "Remote does not exist: $remote"
    fi
}

# Validate clean git working tree
# Usage: validate_git_clean
validate_git_clean() {
    validate_git_repo
    
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        die "Git working tree has uncommitted changes"
    fi
}

# ==============================================================================
# Package Name Validation
# ==============================================================================

# Validate Homebrew package name
# Usage: validate_brew_package "vim"
validate_brew_package() {
    local package="$1"
    
    # Homebrew package names: lowercase, numbers, hyphens, underscores, @, /
    if ! [[ "$package" =~ ^[a-z0-9][a-z0-9@/_-]*$ ]]; then
        die "Invalid Homebrew package name: $package"
    fi
}

# Validate npm package name
# Usage: validate_npm_package "@scope/package"
validate_npm_package() {
    local package="$1"
    
    # npm package names: lowercase, numbers, hyphens, dots, underscores, @, /
    if ! [[ "$package" =~ ^(@[a-z0-9-]+/)?[a-z0-9][a-z0-9._-]*$ ]]; then
        die "Invalid npm package name: $package"
    fi
}

# ==============================================================================
# Network Validation
# ==============================================================================

# Validate URL format
# Usage: validate_url "https://example.com"
validate_url() {
    local url="$1"
    local name="${2:-URL}"
    
    # Basic URL validation
    if ! [[ "$url" =~ ^https?://[^[:space:]]+$ ]]; then
        die "Invalid $name format: $url"
    fi
}

# Validate hostname
# Usage: validate_hostname "example.com"
validate_hostname() {
    local hostname="$1"
    local name="${2:-Hostname}"
    
    # Basic hostname validation (RFC 1123)
    if ! [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        die "Invalid $name: $hostname"
    fi
}

# Validate port number
# Usage: validate_port "8080"
validate_port() {
    local port="$1"
    local name="${2:-Port}"
    
    validate_range "$port" 1 65535 "$name"
}

# Validate IP address (IPv4)
# Usage: validate_ipv4 "192.168.1.1"
validate_ipv4() {
    local ip="$1"
    local name="${2:-IP address}"
    
    # Basic IPv4 validation
    if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        die "Invalid $name format: $ip"
    fi
    
    # Validate each octet
    local IFS='.'
    read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ "$octet" -gt 255 ]]; then
            die "Invalid $name (octet > 255): $ip"
        fi
    done
}

# ==============================================================================
# Environment Validation
# ==============================================================================

# Validate environment variable is set
# Usage: validate_env "API_KEY" "API key"
validate_env() {
    local var_name="$1"
    local description="${2:-$var_name}"
    
    if [[ -z "${!var_name:-}" ]]; then
        die "Environment variable not set: $description ($var_name)"
    fi
}

# Validate required commands exist
# Usage: validate_commands git brew jq
validate_commands() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required commands: ${missing[*]}"
    fi
}

# ==============================================================================
# Option Validation
# ==============================================================================

# Validate option is one of allowed values
# Usage: validate_option "$action" "Action" "start" "stop" "restart"
validate_option() {
    local value="$1"
    local name="$2"
    shift 2
    local allowed=("$@")
    
    for option in "${allowed[@]}"; do
        [[ "$value" == "$option" ]] && return 0
    done
    
    die "Invalid $name: '$value'. Allowed values: ${allowed[*]}"
}

# ==============================================================================
# Composite Validators
# ==============================================================================

# Validate Homebrew is available and working
# Usage: validate_homebrew
validate_homebrew() {
    if ! command -v brew &>/dev/null; then
        die "Homebrew is not installed. Install from: https://brew.sh"
    fi
    
    # Check brew is functional
    if ! brew --version &>/dev/null; then
        die "Homebrew is installed but not working properly"
    fi
}

# Validate Brewfile exists and is valid
# Usage: validate_brewfile "/path/to/Brewfile"
validate_brewfile() {
    local brewfile="$1"
    
    validate_file "$brewfile" "Brewfile"
    
    # Basic syntax check - ensure file has valid entries
    if ! grep -qE '^(tap|brew|cask|mas|vscode) ' "$brewfile" 2>/dev/null; then
        die "Brewfile appears to be empty or invalid: $brewfile"
    fi
}
