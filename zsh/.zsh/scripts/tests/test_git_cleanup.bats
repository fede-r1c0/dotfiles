#!/usr/bin/env bats
# Tests for git-branch-cleanup.sh

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    SCRIPT="$SCRIPT_DIR/git-branch-cleanup.sh"
    
    # Create temp git repo for testing
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    
    # Initialize git repo
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"
    
    # Create initial commit
    echo "initial" > README.md
    git add README.md
    git commit -q -m "Initial commit"
    
    # Ensure we're on main branch
    git branch -M main
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# ==============================================================================
# Help and Version Tests
# ==============================================================================

@test "shows help with -h flag" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"USAGE"* ]]
}

@test "shows help with --help flag" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"git-branch-cleanup"* ]]
}

@test "shows version with -v flag" {
    run "$SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"version"* ]]
}

@test "shows version with --version flag" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"2.0.0"* ]] || [[ "$output" == *"version"* ]]
}

# ==============================================================================
# Git Repository Tests
# ==============================================================================

@test "fails gracefully outside git repository" {
    cd /tmp
    run "$SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"git repository"* ]] || [[ "$output" == *"Not inside"* ]]
}

@test "succeeds inside git repository with no extra branches" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No branches to delete"* ]]
}

# ==============================================================================
# Branch Protection Tests
# ==============================================================================

@test "protects main branch" {
    # Create a test branch
    git checkout -q -b test-branch
    git checkout -q main
    
    run "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"test-branch"* ]]
    [[ "$output" != *"will delete"*"main"* ]]
}

@test "protects master branch" {
    # Rename main to master for this test
    git branch -m main master
    git checkout -q -b test-branch
    git checkout -q master
    
    run "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"will delete"*"master"* ]]
}

@test "protects current branch" {
    git checkout -q -b feature-branch
    
    run "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    # Should not list current branch for deletion
    [[ "$output" == *"No branches to delete"* ]]
}

@test "protects custom branches with --protected" {
    git checkout -q -b keep-me
    git checkout -q -b delete-me
    git checkout -q main
    
    run "$SCRIPT" --dry-run --protected keep-me
    [ "$status" -eq 0 ]
    [[ "$output" == *"delete-me"* ]]
    [[ "$output" != *"Branches to delete"*"keep-me"* ]]
}

# ==============================================================================
# Dry Run Tests
# ==============================================================================

@test "dry run does not delete branches" {
    git checkout -q -b test-branch
    git checkout -q main
    
    run "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run"* ]] || [[ "$output" == *"dry run"* ]]
    
    # Branch should still exist
    run git branch --list test-branch
    [ -n "$output" ]
}

@test "dry run shows branches that would be deleted" {
    git checkout -q -b feature/test
    git checkout -q -b bugfix/test
    git checkout -q main
    
    run "$SCRIPT" -n
    [ "$status" -eq 0 ]
    [[ "$output" == *"feature/test"* ]]
    [[ "$output" == *"bugfix/test"* ]]
}

# ==============================================================================
# Branch Deletion Tests
# ==============================================================================

@test "deletes merged branch with confirmation" {
    git checkout -q -b merged-branch
    echo "change" >> README.md
    git add README.md
    git commit -q -m "Change"
    git checkout -q main
    git merge -q merged-branch
    
    # Simulate 'y' input for confirmation
    run bash -c "echo 'y' | '$SCRIPT'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Deleted"* ]]
    
    # Branch should be gone
    run git branch --list merged-branch
    [ -z "$output" ]
}

@test "cancels on 'n' input" {
    git checkout -q -b test-branch
    git checkout -q main
    
    run bash -c "echo 'n' | '$SCRIPT'"
    [ "$status" -eq 2 ]  # Exit code 2 for cancelled
    [[ "$output" == *"cancelled"* ]] || [[ "$output" == *"Cancelled"* ]]
    
    # Branch should still exist
    run git branch --list test-branch
    [ -n "$output" ]
}

# ==============================================================================
# Force Delete Tests
# ==============================================================================

@test "force flag uses -D for deletion" {
    git checkout -q -b unmerged-branch
    echo "unmerged change" >> newfile.txt
    git add newfile.txt
    git commit -q -m "Unmerged change"
    git checkout -q main
    
    # Without force, should fail to delete unmerged branch
    run bash -c "echo 'y' | '$SCRIPT'"
    [[ "$output" == *"Failed"* ]] || [[ "$output" == *"unmerged"* ]]
    
    # With force, should succeed
    run bash -c "echo 'y' | '$SCRIPT' --force"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Deleted"* ]]
}

# ==============================================================================
# Combined Flags Tests
# ==============================================================================

@test "combined flags -nf work correctly" {
    git checkout -q -b test-branch
    git checkout -q main
    
    run "$SCRIPT" -nf
    [ "$status" -eq 0 ]
    [[ "$output" == *"test-branch"* ]]
    [[ "$output" == *"Dry run"* ]] || [[ "$output" == *"dry run"* ]]
}

@test "quiet flag suppresses output" {
    git checkout -q -b test-branch
    git checkout -q main
    
    run "$SCRIPT" -nq
    [ "$status" -eq 0 ]
    # Output should be minimal
}
