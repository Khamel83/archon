#!/usr/bin/env bash
# Module: testing/lint_code
# Purpose: Lint code with appropriate linter for file type
# Input: file/directory path (default: current directory)
# Output: linting results
# Exit codes: 0=clean, 1=issues found, 2=linter not available

set -euo pipefail

TARGET="${1:-.}"

issues_found=0

echo "Linting code in: $TARGET"

# Python files
if find "$TARGET" -name "*.py" -type f | head -1 >/dev/null 2>&1; then
    echo "Linting Python files..."

    if command -v ruff >/dev/null 2>&1; then
        if ! ruff check "$TARGET"; then
            issues_found=1
        fi
    elif command -v uv >/dev/null 2>&1; then
        if ! uv run ruff check "$TARGET"; then
            issues_found=1
        fi
    elif command -v flake8 >/dev/null 2>&1; then
        if ! flake8 "$TARGET"; then
            issues_found=1
        fi
    else
        echo "⚠️  No Python linter found (ruff/flake8)"
    fi
fi

# JavaScript/TypeScript files
if find "$TARGET" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -type f | head -1 >/dev/null 2>&1; then
    echo "Linting JavaScript/TypeScript files..."

    if command -v eslint >/dev/null 2>&1; then
        if ! eslint "$TARGET" --ext .js,.ts,.jsx,.tsx; then
            issues_found=1
        fi
    else
        echo "⚠️  No JavaScript linter found (eslint)"
    fi
fi

# Shell scripts
if find "$TARGET" -name "*.sh" -type f | head -1 >/dev/null 2>&1; then
    echo "Linting shell scripts..."

    if command -v shellcheck >/dev/null 2>&1; then
        if ! find "$TARGET" -name "*.sh" -type f -exec shellcheck {} +; then
            issues_found=1
        fi
    else
        echo "⚠️  No shell linter found (shellcheck)"
    fi
fi

if [[ $issues_found -eq 0 ]]; then
    echo "✅ No linting issues found"
    exit 0
else
    echo "❌ Linting issues detected"
    exit 1
fi