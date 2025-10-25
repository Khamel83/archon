#!/usr/bin/env bash
# Module: testing/run_pytest
# Purpose: Run Python tests with pytest
# Input: test path (default: tests/)
# Output: test results
# Exit codes: 0=all passed, 1=tests failed, 2=no tests found

set -euo pipefail

TEST_PATH="${1:-tests/}"
COVERAGE_THRESHOLD="${2:-80}"

# Check if pytest is available
if ! command -v pytest >/dev/null 2>&1; then
    echo "pytest not found, trying with uv..."
    if command -v uv >/dev/null 2>&1; then
        PYTEST_CMD="uv run pytest"
    else
        echo "Neither pytest nor uv found"
        exit 2
    fi
else
    PYTEST_CMD="pytest"
fi

# Check if test directory exists
if [[ ! -d "$TEST_PATH" ]] && [[ ! -f "$TEST_PATH" ]]; then
    echo "Test path not found: $TEST_PATH"
    exit 2
fi

echo "Running tests with coverage..."

# Run pytest with coverage
if $PYTEST_CMD "$TEST_PATH" \
    --cov=. \
    --cov-report=term-missing \
    --cov-fail-under="$COVERAGE_THRESHOLD" \
    -v; then
    echo "✅ All tests passed with sufficient coverage"
    exit 0
else
    echo "❌ Tests failed or coverage below $COVERAGE_THRESHOLD%"
    exit 1
fi