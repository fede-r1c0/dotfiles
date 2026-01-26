#!/usr/bin/env bats
# Tests for lib/validation.sh

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    source "${SCRIPT_DIR}/lib/common.sh"
    source "${SCRIPT_DIR}/lib/validation.sh"
    
    # Create temp directory for file tests
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# ==============================================================================
# String Validation Tests
# ==============================================================================

@test "validate_regex matches valid pattern" {
    run validate_regex "test@example.com" '^[^@]+@[^@]+\.[^@]+$'
    [ "$status" -eq 0 ]
}

@test "validate_regex rejects invalid pattern" {
    run validate_regex "invalid-email" '^[^@]+@[^@]+\.[^@]+$'
    [ "$status" -eq 1 ]
}

@test "validate_alphanumeric accepts valid input" {
    run validate_alphanumeric "test123" "Test"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Numeric Validation Tests
# ==============================================================================

@test "validate_integer accepts valid integer" {
    run validate_integer "123" "Number"
    [ "$status" -eq 0 ]
}

@test "validate_integer accepts negative integer" {
    run validate_integer "-123" "Number"
    [ "$status" -eq 0 ]
}

@test "validate_positive_integer accepts positive number" {
    run validate_positive_integer "42" "Count"
    [ "$status" -eq 0 ]
}

@test "validate_range accepts value in range" {
    run validate_range "50" 1 100 "Value"
    [ "$status" -eq 0 ]
}

@test "validate_port accepts valid port" {
    run validate_port "8080" "Port"
    [ "$status" -eq 0 ]
}

@test "validate_port accepts port 443" {
    run validate_port "443" "Port"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# File System Validation Tests
# ==============================================================================

@test "validate_file succeeds for existing file" {
    local test_file="$TEST_DIR/test.txt"
    echo "test" > "$test_file"
    
    run validate_file "$test_file" "Test file"
    [ "$status" -eq 0 ]
}

@test "validate_directory succeeds for existing directory" {
    run validate_directory "$TEST_DIR" "Test dir"
    [ "$status" -eq 0 ]
}

@test "validate_safe_path rejects path traversal" {
    run validate_safe_path "../../../etc/passwd" "Path"
    [ "$status" -ne 0 ]
}

@test "validate_safe_path accepts normal path" {
    run validate_safe_path "/home/user/file.txt" "Path"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Git Validation Tests
# ==============================================================================

@test "validate_git_repo fails outside git repo" {
    cd "$TEST_DIR"
    run validate_git_repo
    [ "$status" -ne 0 ]
}

@test "validate_git_repo succeeds inside git repo" {
    cd "$TEST_DIR"
    git init -q
    run validate_git_repo
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Package Name Validation Tests
# ==============================================================================

@test "validate_brew_package accepts valid package name" {
    run validate_brew_package "vim"
    [ "$status" -eq 0 ]
}

@test "validate_brew_package accepts package with tap" {
    run validate_brew_package "homebrew/core/vim"
    [ "$status" -eq 0 ]
}

@test "validate_brew_package accepts package with version" {
    run validate_brew_package "python@3.11"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Network Validation Tests
# ==============================================================================

@test "validate_url accepts valid https URL" {
    run validate_url "https://example.com" "URL"
    [ "$status" -eq 0 ]
}

@test "validate_url accepts valid http URL" {
    run validate_url "http://example.com/path" "URL"
    [ "$status" -eq 0 ]
}

@test "validate_hostname accepts valid hostname" {
    run validate_hostname "example.com" "Host"
    [ "$status" -eq 0 ]
}

@test "validate_hostname accepts subdomain" {
    run validate_hostname "sub.example.com" "Host"
    [ "$status" -eq 0 ]
}

@test "validate_ipv4 accepts valid IP" {
    run validate_ipv4 "192.168.1.1" "IP"
    [ "$status" -eq 0 ]
}

@test "validate_ipv4 accepts localhost IP" {
    run validate_ipv4 "127.0.0.1" "IP"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Option Validation Tests
# ==============================================================================

@test "validate_option accepts valid option" {
    run validate_option "start" "Action" "start" "stop" "restart"
    [ "$status" -eq 0 ]
}

@test "validate_commands succeeds for existing commands" {
    run validate_commands bash cat
    [ "$status" -eq 0 ]
}
