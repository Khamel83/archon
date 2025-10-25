#!/usr/bin/env bash
# Module: security/scan_secrets
# Purpose: Scan for exposed secrets in code
# Input: directory path (default: current directory)
# Output: list of potential secrets found
# Exit codes: 0=clean, 1=secrets found, 2=scanner not available

set -euo pipefail

SCAN_DIR="${1:-.}"

# Common secret patterns
SECRET_PATTERNS=(
    "password\s*=\s*['\"][^'\"]{8,}"
    "api[_-]?key\s*=\s*['\"][^'\"]{16,}"
    "secret[_-]?key\s*=\s*['\"][^'\"]{16,}"
    "token\s*=\s*['\"][^'\"]{20,}"
    "auth[_-]?token\s*=\s*['\"][^'\"]{20,}"
    "private[_-]?key\s*=\s*['\"][^'\"]{32,}"
    "-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----"
)

# Files to skip
SKIP_PATTERNS=(
    "*.git/*"
    "*.env.template"
    "*.env.example"
    "*node_modules/*"
    "*.venv/*"
    "__pycache__/*"
)

secrets_found=0

echo "Scanning for secrets in: $SCAN_DIR"

for pattern in "${SECRET_PATTERNS[@]}"; do
    # Build exclude arguments
    exclude_args=()
    for skip in "${SKIP_PATTERNS[@]}"; do
        exclude_args+=(--exclude="$skip")
    done

    # Search for pattern
    if grep -r -i -E "${exclude_args[@]}" "$pattern" "$SCAN_DIR" 2>/dev/null; then
        secrets_found=1
    fi
done

if [[ $secrets_found -eq 1 ]]; then
    echo "⚠️  Potential secrets found! Review the above results."
    exit 1
else
    echo "✅ No secrets detected"
    exit 0
fi