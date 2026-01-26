#!/usr/bin/env bats
# Tests for lib/common.sh

setup() {
    # Load the library
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    source "${SCRIPT_DIR}/lib/common.sh"
}

# ==============================================================================
# Platform Detection Tests
# ==============================================================================

@test "detect_os returns valid value" {
    run detect_os
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(macos|linux|windows|unknown)$ ]]
}

@test "detect_arch returns valid value" {
    run detect_arch
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(arm64|x64|.+)$ ]]
}

@test "detect_platform returns os-arch format" {
    run detect_platform
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[a-z]+-[a-z0-9]+$ ]]
}

@test "is_macos returns correct value on macOS" {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        run is_macos
        [ "$status" -eq 0 ]
    else
        run is_macos
        [ "$status" -eq 1 ]
    fi
}

# ==============================================================================
# Command Utilities Tests
# ==============================================================================

@test "command_exists returns true for existing command" {
    run command_exists bash
    [ "$status" -eq 0 ]
}

@test "command_exists returns false for non-existing command" {
    run command_exists nonexistent_command_12345
    [ "$status" -eq 1 ]
}

@test "require_command succeeds for existing command" {
    run require_command bash
    [ "$status" -eq 0 ]
}

# ==============================================================================
# String Utilities Tests
# ==============================================================================

@test "trim removes leading whitespace" {
    run trim "  hello"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "trim removes trailing whitespace" {
    run trim "hello  "
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "trim removes both leading and trailing whitespace" {
    run trim "  hello  "
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "is_blank returns true for empty string" {
    run is_blank ""
    [ "$status" -eq 0 ]
}

@test "is_blank returns true for whitespace only" {
    run is_blank "   "
    [ "$status" -eq 0 ]
}

@test "is_blank returns false for non-empty string" {
    run is_blank "hello"
    [ "$status" -eq 1 ]
}

@test "to_lower converts uppercase to lowercase" {
    run to_lower "HELLO"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "to_upper converts lowercase to uppercase" {
    run to_upper "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "HELLO" ]
}

# ==============================================================================
# Array Utilities Tests
# ==============================================================================

@test "array_contains finds element in array" {
    local arr=("one" "two" "three")
    run array_contains "two" "${arr[@]}"
    [ "$status" -eq 0 ]
}

@test "array_contains returns false for missing element" {
    local arr=("one" "two" "three")
    run array_contains "four" "${arr[@]}"
    [ "$status" -eq 1 ]
}

@test "array_join joins array with delimiter" {
    run array_join "," "a" "b" "c"
    [ "$status" -eq 0 ]
    [ "$output" = "a,b,c" ]
}

# ==============================================================================
# Path Utilities Tests
# ==============================================================================

@test "get_absolute_path handles relative path" {
    run get_absolute_path "test"
    [ "$status" -eq 0 ]
    [[ "$output" == /* ]]  # Should start with /
}

@test "get_absolute_path handles absolute path" {
    run get_absolute_path "/absolute/path"
    [ "$status" -eq 0 ]
    [ "$output" = "/absolute/path" ]
}
