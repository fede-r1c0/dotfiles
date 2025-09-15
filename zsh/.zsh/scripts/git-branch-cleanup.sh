#!/bin/bash
# git-cleanup-branches.sh - Compatible with grep and ripgrep

# Detect which search tool to use
if command -v rg &> /dev/null; then
    GREP_CMD="rg -v"
    PATTERN="main|master|\*"
else
    GREP_CMD="grep -v -E"
    PATTERN="(main|master|\*)"
fi
echo "🐙 Git branch cleanup script"

# List the branches that will be deleted
BRANCHES_TO_DELETE=$(git branch | $GREP_CMD "$PATTERN" | sed 's/^[ \t]*//')

if [ -z "$BRANCHES_TO_DELETE" ]; then
    echo "✅ No additional branches to delete"
    exit 0
fi

echo "🗑️  Git branches to be deleted:"
echo "$BRANCHES_TO_DELETE"

read -p "⚠️  WARNING: This will permanently delete the branches. Are you sure? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch | $GREP_CMD "$PATTERN" | xargs -n 1 git branch -d
    echo "✅ Cleanup completed"
else
    echo "❌ Operation cancelled"
fi