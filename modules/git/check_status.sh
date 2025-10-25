#!/usr/bin/env bash
# Module: git/check_status
# Purpose: Check git repository status
# Input: none
# Output: status summary to stdout
# Exit codes: 0=clean, 1=not a repo, 2=has changes

set -euo pipefail

if [[ ! -d ".git" ]]; then
    echo "Not a git repository"
    exit 1
fi

if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "Working directory clean"
    exit 0
else
    echo "Working directory has uncommitted changes"
    exit 2
fi