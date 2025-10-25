#!/usr/bin/env bash
# Composition: pre-commit
# Purpose: Complete pre-commit validation workflow
# Modules: security/scan_secrets, testing/lint_code, testing/run_pytest, ai/generate_commit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE_RUNNER="$PROJECT_ROOT/bin/oos-module-runner.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}🔍 Pre-Commit Validation${NC}"
echo "========================"

failed_checks=()
warning_checks=()

# Step 1: Security scan
echo -e "\n${BLUE}🔒 Security Check${NC}"
if "$MODULE_RUNNER" run security scan_secrets; then
    echo -e "${GREEN}✅ No secrets detected${NC}"
else
    failed_checks+=("security")
    echo -e "${RED}❌ Security issues found${NC}"
fi

# Step 2: Code linting
echo -e "\n${BLUE}🧹 Code Linting${NC}"
if "$MODULE_RUNNER" run testing lint_code; then
    echo -e "${GREEN}✅ Code style is clean${NC}"
else
    warning_checks+=("linting")
    echo -e "${YELLOW}⚠️  Linting issues found${NC}"
fi

# Step 3: Run tests (if tests exist)
echo -e "\n${BLUE}🧪 Running Tests${NC}"
if [[ -d "tests" ]] || [[ -f "test_*.py" ]] || [[ -f "*_test.py" ]]; then
    if "$MODULE_RUNNER" run testing run_pytest; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        failed_checks+=("tests")
        echo -e "${RED}❌ Tests failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No tests found${NC}"
    warning_checks+=("no-tests")
fi

# Step 4: Generate commit message
echo -e "\n${BLUE}💬 Generating Commit Message${NC}"
if COMMIT_MSG=$("$MODULE_RUNNER" run ai generate_commit); then
    echo -e "${GREEN}📝 Suggested commit message:${NC}"
    echo "   $COMMIT_MSG"
    echo ""
    echo "To commit with this message:"
    echo "   git commit -m \"$COMMIT_MSG\""
else
    echo -e "${YELLOW}⚠️  No changes staged for commit${NC}"
fi

# Summary
echo -e "\n${BOLD}📋 Pre-Commit Summary${NC}"
echo "===================="

if [[ ${#failed_checks[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ Ready to commit!${NC}"

    if [[ ${#warning_checks[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Warnings: ${warning_checks[*]}${NC}"
    fi

    exit 0
else
    echo -e "${RED}❌ Fix these issues before committing:${NC}"
    for check in "${failed_checks[@]}"; do
        echo "   - $check"
    done
    exit 1
fi