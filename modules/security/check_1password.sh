#!/usr/bin/env bash
# Module: security/check_1password
# Purpose: Check if 1Password CLI is authenticated
# Input: none
# Output: status message to stdout
# Exit codes: 0=authenticated, 1=not authenticated, 2=not installed

set -euo pipefail

# Check if 1Password CLI is installed
if ! command -v op >/dev/null 2>&1; then
    echo "1Password CLI not installed"
    exit 2
fi

# Check if authenticated
if op whoami >/dev/null 2>&1; then
    echo "1Password CLI authenticated"
    exit 0
else
    echo "1Password CLI not authenticated"
    exit 1
fi