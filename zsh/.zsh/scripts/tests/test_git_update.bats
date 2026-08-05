#!/usr/bin/env bats
# Tests for git-branch-update.sh

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    SCRIPT="$SCRIPT_DIR/git-branch-update.sh"

    # Bare "remote" repo
    REMOTE_DIR="$(mktemp -d)"
    git init -q --bare "$REMOTE_DIR"

    # Local clone acting as the working repo under test
    TEST_DIR="$(mktemp -d)"
    git clone -q "$REMOTE_DIR" "$TEST_DIR"
    cd "$TEST_DIR"
    git config user.email "test@test.com"
    git config user.name "Test User"

    echo "initial" > README.md
    git add README.md
    git commit -q -m "Initial commit"
    git branch -M main
    git push -q -u origin main
}

teardown() {
    cd /
    rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

# ==============================================================================
# Help and Version Tests
# ==============================================================================

@test "shows help with -h flag" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"USAGE"* ]]
}

@test "shows help with --help flag" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"git-branch-update"* ]]
}

@test "shows version with -v flag" {
    run "$SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"version"* ]]
}

@test "shows version with --version flag" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"1.0.0"* ]]
}

# ==============================================================================
# Argument Validation Tests
# ==============================================================================

@test "fails gracefully outside git repository" {
    cd /tmp
    run "$SCRIPT" main
    [ "$status" -ne 0 ]
    [[ "$output" == *"git repository"* ]] || [[ "$output" == *"Not inside"* ]]
}

@test "fails without a base branch argument" {
    run "$SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Base branch required"* ]]
}

@test "fails on unknown option" {
    run "$SCRIPT" --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "fails on unexpected extra argument" {
    run "$SCRIPT" main extra
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unexpected argument"* ]]
}

@test "fails when base branch does not exist on remote" {
    run "$SCRIPT" no-such-branch
    [ "$status" -ne 0 ]
    [[ "$output" == *"Could not fetch"* ]]
}

# ==============================================================================
# Up To Date Tests
# ==============================================================================

@test "reports already up to date when nothing to rebase" {
    git checkout -q -b feature
    run "$SCRIPT" main
    [ "$status" -eq 0 ]
    [[ "$output" == *"up to date"* ]]
}

# ==============================================================================
# Dry Run Tests
# ==============================================================================

@test "dry run shows behind count without rebasing" {
    git checkout -q -b feature

    # Advance remote main without updating local feature branch
    git checkout -q main
    echo "remote change" >> README.md
    git add README.md
    git commit -q -m "Remote-only change"
    git push -q origin main
    git checkout -q feature

    run "$SCRIPT" main --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 commit"*"behind"* ]]
    [[ "$output" == *"Dry run"* ]] || [[ "$output" == *"dry run"* ]]

    # feature branch must be untouched — no rebase happened
    run git log --oneline feature
    [[ "$output" != *"Remote-only change"* ]]
}

# ==============================================================================
# Rebase Tests
# ==============================================================================

@test "rebases current branch onto updated origin base" {
    git checkout -q -b feature
    echo "feature change" >> feature.txt
    git add feature.txt
    git commit -q -m "Feature commit"

    git checkout -q main
    echo "remote change" >> README.md
    git add README.md
    git commit -q -m "Remote-only change"
    git push -q origin main
    git checkout -q feature

    run "$SCRIPT" main
    [ "$status" -eq 0 ]
    [[ "$output" == *"rebased onto origin/main"* ]]

    run git log --oneline feature
    [[ "$output" == *"Remote-only change"* ]]
    [[ "$output" == *"Feature commit"* ]]
}

@test "preserves uncommitted changes via autostash" {
    git checkout -q -b feature

    git checkout -q main
    echo "remote change" >> README.md
    git add README.md
    git commit -q -m "Remote-only change"
    git push -q origin main
    git checkout -q feature

    echo "dirty" >> untracked-work.txt

    run "$SCRIPT" main
    [ "$status" -eq 0 ]

    [ -f untracked-work.txt ]
    run cat untracked-work.txt
    [[ "$output" == *"dirty"* ]]
}

@test "fails when a rebase is already in progress" {
    git checkout -q -b feature
    echo "conflict" > README.md
    git add README.md
    git commit -q -m "Local conflicting change"

    git checkout -q main
    echo "remote conflict" > README.md
    git add README.md
    git commit -q -m "Remote conflicting change"
    git push -q origin main
    git checkout -q feature

    # Trigger a real conflicting rebase and leave it mid-flight
    git fetch -q origin main
    run git rebase origin/main
    [ "$status" -ne 0 ]

    run "$SCRIPT" main
    [ "$status" -ne 0 ]
    [[ "$output" == *"rebase is already in progress"* ]]

    git rebase --abort
}

@test "exits 3 and leaves recovery instructions on conflict" {
    git checkout -q -b feature
    echo "conflict" > README.md
    git add README.md
    git commit -q -m "Local conflicting change"

    git checkout -q main
    echo "remote conflict" > README.md
    git add README.md
    git commit -q -m "Remote conflicting change"
    git push -q origin main
    git checkout -q feature

    run "$SCRIPT" main
    [ "$status" -eq 3 ]
    [[ "$output" == *"Rebase stopped on conflicts"* ]]
    [[ "$output" == *"git rebase --abort"* ]]

    git rebase --abort
}
