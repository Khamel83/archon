#!/usr/bin/env bash
# Module: ai/generate_commit
# Purpose: Generate intelligent commit message from git diff
# Input: none (uses git diff)
# Output: commit message to stdout
# Exit codes: 0=success, 1=no changes, 2=git not available

set -euo pipefail

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not a git repository"
    exit 2
fi

# Check if there are changes to commit
if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "No changes to commit"
    exit 1
fi

# Get the diff
DIFF=$(git diff --cached --name-status 2>/dev/null || git diff --name-status)

if [[ -z "$DIFF" ]]; then
    echo "No staged changes found"
    exit 1
fi

# Count files by type
ADDED=$(echo "$DIFF" | grep -c "^A" || echo "0")
MODIFIED=$(echo "$DIFF" | grep -c "^M" || echo "0")
DELETED=$(echo "$DIFF" | grep -c "^D" || echo "0")
RENAMED=$(echo "$DIFF" | grep -c "^R" || echo "0")

# Get file types
FILES=$(echo "$DIFF" | cut -f2- | head -5)

# Generate commit message based on changes
if [[ $ADDED -gt 0 && $MODIFIED -eq 0 && $DELETED -eq 0 ]]; then
    if [[ $ADDED -eq 1 ]]; then
        echo "feat: add $(echo "$FILES" | head -1)"
    else
        echo "feat: add $ADDED new files"
    fi
elif [[ $MODIFIED -gt 0 && $ADDED -eq 0 && $DELETED -eq 0 ]]; then
    if [[ $MODIFIED -eq 1 ]]; then
        echo "fix: update $(echo "$FILES" | head -1)"
    else
        echo "fix: update $MODIFIED files"
    fi
elif [[ $DELETED -gt 0 && $ADDED -eq 0 && $MODIFIED -eq 0 ]]; then
    if [[ $DELETED -eq 1 ]]; then
        echo "remove: delete $(echo "$FILES" | head -1)"
    else
        echo "remove: delete $DELETED files"
    fi
else
    # Mixed changes
    TOTAL=$((ADDED + MODIFIED + DELETED))
    echo "chore: update $TOTAL files ($ADDED added, $MODIFIED modified, $DELETED deleted)"
fi

exit 0