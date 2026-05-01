#!/usr/bin/env bats
# Integration tests for hist-hygiene.sh
#
# Tests run with HOME mocked to a tmpdir so the real history is never touched.

setup() {
    SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    SCRIPT="${SCRIPTS_DIR}/hist-hygiene.sh"
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
    export XDG_STATE_HOME="${TEST_HOME}/.local/state"
    export XDG_DATA_HOME="${TEST_HOME}/.local/share"
    # Disable color output for cleaner assertions
    export NO_COLOR=1
}

teardown() {
    [[ -n "${TEST_HOME:-}" && -d "$TEST_HOME" ]] && rm -rf "$TEST_HOME"
}

# ==============================================================================
# Help and basic invocation
# ==============================================================================

@test "--help exits 0 and contains USAGE" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"USAGE"* ]]
}

@test "--version prints version" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"v1.0.0"* ]]
}

@test "unknown flag exits 1" {
    run "$SCRIPT" --bogus
    [ "$status" -eq 1 ]
}

# ==============================================================================
# History detection
# ==============================================================================

@test "no history files: exits 0 with info message" {
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *"No history files detected"* ]]
}

@test "detects ~/.zsh_history" {
    echo ": 1700000000:0;ls" > "$HOME/.zsh_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *".zsh_history"* ]]
}

@test "detects ~/.bash_history" {
    echo "ls" > "$HOME/.bash_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *".bash_history"* ]]
}

@test "detects fish history (XDG path)" {
    mkdir -p "$HOME/.local/share/fish"
    echo "- cmd: ls" > "$HOME/.local/share/fish/fish_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *"fish_history"* ]]
}

# ==============================================================================
# Find mode
# ==============================================================================

@test "find: clean history reports clean" {
    cat > "$HOME/.zsh_history" <<'EOF'
: 1700000000:0;ls -la
: 1700000001:0;cd /tmp
EOF
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *"clean"* ]]
}

@test "find: detects AKIA AWS key" {
    echo ": 1700000000:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > "$HOME/.zsh_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *"aws_access_key_id"* ]]
}

@test "find: detects ghp_ token" {
    echo ": 1700000000:0;git push https://ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA@github.com/x" > "$HOME/.zsh_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *"github_token"* ]]
}

@test "find: does NOT print full secret value" {
    echo ": 1700000000:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > "$HOME/.zsh_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" != *"AKIAIOSFODNN7EXAMPLE"* ]]
}

# ==============================================================================
# Clear mode — atomic redaction
# ==============================================================================

@test "clear --dry-run does NOT modify file" {
    local target="$HOME/.zsh_history"
    cat > "$target" <<'EOF'
: 1700000000:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
EOF
    local before
    before="$(cat "$target")"
    run "$SCRIPT" --clear --dry-run --yes
    [ "$status" -eq 0 ]
    [ "$(cat "$target")" = "$before" ]
}

@test "clear --yes redacts AWS key in-place, preserves command" {
    local target="$HOME/.zsh_history"
    cat > "$target" <<'EOF'
: 1700000000:0;ls -la
: 1700000001:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
EOF
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    grep -q "ls -la" "$target"
    grep -q "AWS_ACCESS_KEY_ID=AKIA\*\*\*REDACTED\*\*\*" "$target"
    ! grep -q "AKIAIOSFODNN7EXAMPLE" "$target"
}

@test "clear --yes preserves zsh extended-history format" {
    local target="$HOME/.zsh_history"
    cat > "$target" <<'EOF'
: 1700000000:0;ls -la
: 1700000001:0;cd /tmp
EOF
    local before
    before="$(cat "$target")"
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    [ "$(cat "$target")" = "$before" ]
}

@test "clear does NOT create .bak files" {
    local target="$HOME/.zsh_history"
    echo ": 1700000000:0;export PASSWORD=hunter2pass" > "$target"
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    # No backup files should exist
    run find "$HOME" -name "*.bak*" -o -name "*.backup*"
    [ -z "$output" ]
}

@test "clear preserves file permissions" {
    local target="$HOME/.zsh_history"
    echo ": 1700000000:0;export PASSWORD=hunter2pass" > "$target"
    chmod 600 "$target"
    local mode_before
    if [[ "$(uname -s)" == "Darwin" ]]; then
        mode_before=$(stat -f '%Mp%Lp' "$target")
    else
        mode_before=$(stat -c '%a' "$target")
    fi
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    local mode_after
    if [[ "$(uname -s)" == "Darwin" ]]; then
        mode_after=$(stat -f '%Mp%Lp' "$target")
    else
        mode_after=$(stat -c '%a' "$target")
    fi
    [ "$mode_before" = "$mode_after" ]
}

@test "fish history: clear skips with warning" {
    mkdir -p "$HOME/.local/share/fish"
    local target="$HOME/.local/share/fish/fish_history"
    echo "- cmd: export PASSWORD=hunter2pass" > "$target"
    local before
    before="$(cat "$target")"
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    # File unchanged (fish unsupported for redaction)
    [ "$(cat "$target")" = "$before" ]
}

# ==============================================================================
# Cron mode — metadata-only logging
# ==============================================================================

@test "cron: writes metadata log, no stdout" {
    echo ": 1700000000:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > "$HOME/.zsh_history"
    run "$SCRIPT" --cron
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ -f "$HOME/.local/state/hist-hygiene/run.log" ]
}

@test "cron: log contains metadata, NOT secret values" {
    echo ": 1700000000:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > "$HOME/.zsh_history"
    run "$SCRIPT" --cron
    [ "$status" -eq 0 ]
    local log="$HOME/.local/state/hist-hygiene/run.log"
    grep -q "redacted=" "$log"
    grep -q "aws_access_key_id" "$log"
    # The actual secret value must NEVER appear in the log
    ! grep -q "AKIAIOSFODNN7EXAMPLE" "$log"
}

@test "cron: clean history logs status=clean" {
    echo ": 1700000000:0;ls" > "$HOME/.zsh_history"
    run "$SCRIPT" --cron
    [ "$status" -eq 0 ]
    grep -q "status=clean" "$HOME/.local/state/hist-hygiene/run.log"
}

# ==============================================================================
# Idempotency
# ==============================================================================

@test "second clear on already-redacted file does not corrupt content" {
    local target="$HOME/.zsh_history"
    echo ": 1700000000:0;export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" > "$target"
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    local after_first
    after_first="$(cat "$target")"
    run "$SCRIPT" --clear --yes
    [ "$status" -eq 0 ]
    # AWS key should still be redacted, command preserved
    grep -q "AWS_ACCESS_KEY_ID=AKIA\*\*\*REDACTED\*\*\*" "$target"
    ! grep -q "AKIAIOSFODNN7EXAMPLE" "$target"
}

# ==============================================================================
# Paranoid mode
# ==============================================================================

@test "paranoid: matches 40+ char base64 string" {
    echo ": 1700000000:0;echo abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG" > "$HOME/.zsh_history"
    run "$SCRIPT" --find --paranoid
    [ "$status" -eq 0 ]
    [[ "$output" == *"high_entropy"* ]]
}

@test "default mode: does NOT match 40-char hex hash" {
    echo ": 1700000000:0;git checkout deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" > "$HOME/.zsh_history"
    run "$SCRIPT" --find
    [ "$status" -eq 0 ]
    [[ "$output" == *"clean"* ]]
}
