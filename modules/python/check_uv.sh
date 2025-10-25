#!/usr/bin/env bash
# Module: python/check_uv
# Purpose: Check if uv is installed and working
# Input: none
# Output: version to stdout
# Exit codes: 0=installed, 1=not installed

set -euo pipefail

if command -v uv >/dev/null 2>&1; then
    uv --version
    exit 0
else
    echo "uv not installed"
    exit 1
fi