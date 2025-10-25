#!/usr/bin/env bash
# Module: security/check_permissions
# Purpose: Check file and directory permissions for security issues
# Input: directory path (default: current directory)
# Output: permission issues found
# Exit codes: 0=secure, 1=issues found, 2=permission denied

set -euo pipefail

CHECK_DIR="${1:-.}"

issues_found=0

echo "Checking permissions in: $CHECK_DIR"

# Check for world-writable files
echo "Checking for world-writable files..."
if find "$CHECK_DIR" -type f -perm -o+w 2>/dev/null | head -5; then
    echo "⚠️  Found world-writable files"
    issues_found=1
fi

# Check for files with no owner restrictions
echo "Checking for overly permissive files..."
if find "$CHECK_DIR" -type f -perm -777 2>/dev/null | head -5; then
    echo "⚠️  Found files with 777 permissions"
    issues_found=1
fi

# Check for executable files in suspicious locations
echo "Checking for suspicious executables..."
if find "$CHECK_DIR" -name "*.sh" -o -name "*.py" -o -name "*.js" | xargs ls -la 2>/dev/null | grep -- "-rwxrwxrwx"; then
    echo "⚠️  Found overly permissive executables"
    issues_found=1
fi

# Check for sensitive files that should be protected
echo "Checking for unprotected sensitive files..."
sensitive_files=(".env" "*.key" "*.pem" "*.crt" "id_rsa" "id_dsa")
for pattern in "${sensitive_files[@]}"; do
    if find "$CHECK_DIR" -name "$pattern" -perm -o+r 2>/dev/null | head -3; then
        echo "⚠️  Found readable sensitive files: $pattern"
        issues_found=1
    fi
done

if [[ $issues_found -eq 0 ]]; then
    echo "✅ No permission issues found"
    exit 0
else
    echo "❌ Permission issues detected"
    exit 1
fi