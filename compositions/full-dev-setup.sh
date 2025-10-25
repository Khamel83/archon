#!/usr/bin/env bash
# Composition: full-dev-setup
# Purpose: Complete development environment validation
# Modules: security/check_1password, python/check_uv, git/check_status, security/check_permissions

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

echo -e "${BOLD}${BLUE}🚀 Full Development Environment Setup${NC}"
echo "====================================="

# Store results
security_status="unknown"
python_status="unknown"
git_status="unknown"
permissions_status="unknown"

# Step 1: Security validation
echo -e "\n${BLUE}🔐 Security Environment${NC}"
if "$MODULE_RUNNER" run security check_1password; then
    security_status="ready"
    echo -e "${GREEN}✅ 1Password authenticated${NC}"
else
    security_status="warning"
    echo -e "${YELLOW}⚠️  1Password not authenticated${NC}"
fi

# Step 2: Python environment
echo -e "\n${BLUE}🐍 Python Environment${NC}"
if "$MODULE_RUNNER" run python check_uv; then
    python_status="ready"
    echo -e "${GREEN}✅ Python environment ready${NC}"
else
    python_status="failed"
    echo -e "${RED}❌ Python environment issues${NC}"
fi

# Step 3: Git status
echo -e "\n${BLUE}📚 Git Repository${NC}"
exit_code=0
"$MODULE_RUNNER" run git check_status || exit_code=$?

case $exit_code in
    0)
        git_status="clean"
        echo -e "${GREEN}✅ Git repository clean${NC}"
        ;;
    1)
        git_status="not-repo"
        echo -e "${YELLOW}⚠️  Not a git repository${NC}"
        ;;
    2)
        git_status="dirty"
        echo -e "${YELLOW}⚠️  Uncommitted changes${NC}"
        ;;
esac

# Step 4: File permissions
echo -e "\n${BLUE}🔒 File Permissions${NC}"
if "$MODULE_RUNNER" run security check_permissions; then
    permissions_status="secure"
    echo -e "${GREEN}✅ File permissions secure${NC}"
else
    permissions_status="issues"
    echo -e "${YELLOW}⚠️  Permission issues found${NC}"
fi

# Development workflow suggestions
echo -e "\n${BLUE}🛠️  Development Workflow${NC}"
echo "Available compositions:"
echo "• /modules compose security/scan_secrets testing/lint_code  # Quick validation"
echo "• ./compositions/pre-commit.sh                              # Before committing"
echo "• /modules run ai explain_code <file>                       # Understand code"

# Environment summary
echo -e "\n${BOLD}📊 Environment Status${NC}"
echo "===================="
echo "Security:     $security_status"
echo "Python:       $python_status"
echo "Git:          $git_status"
echo "Permissions:  $permissions_status"

# Overall status
critical_issues=0
[[ "$python_status" == "failed" ]] && critical_issues=1
[[ "$permissions_status" == "issues" ]] && critical_issues=1

if [[ $critical_issues -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 Development environment ready!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  Some issues found, but you can still develop${NC}"
    exit 0
fi