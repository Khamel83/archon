#!/usr/bin/env bash
set -euo pipefail

# OOS Module Runner - Execute and compose modules
# This is the foundation of the "everything is module composition" philosophy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES_DIR="$PROJECT_ROOT/modules"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function: Run a single module
run_module() {
    local module_path="$1"
    shift || true

    if [[ ! -f "$module_path" ]]; then
        echo -e "${RED}❌ Module not found: $module_path${NC}" >&2
        return 1
    fi

    if [[ ! -x "$module_path" ]]; then
        echo -e "${RED}❌ Module not executable: $module_path${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}🧩 Running module: $(basename "$module_path")${NC}"

    if bash "$module_path" "$@"; then
        echo -e "${GREEN}✅ Module completed: $(basename "$module_path")${NC}"
        return 0
    else
        local exit_code=$?
        case $exit_code in
            1)
                echo -e "${RED}❌ Module failed: $(basename "$module_path")${NC}" >&2
                return 1
                ;;
            2)
                echo -e "${YELLOW}⚠️  Module warning: $(basename "$module_path")${NC}" >&2
                return 2
                ;;
            *)
                echo -e "${RED}❌ Module error ($exit_code): $(basename "$module_path")${NC}" >&2
                return $exit_code
                ;;
        esac
    fi
}

# Function: Find module by category/name
find_module() {
    local category="$1"
    local name="$2"

    local module_path="$MODULES_DIR/$category/$name.sh"
    echo "$module_path"
}

# Function: List available modules
list_modules() {
    if [[ ! -d "$MODULES_DIR" ]]; then
        echo "No modules directory found"
        return 1
    fi

    echo -e "${BLUE}📦 Available OOS Modules:${NC}"
    find "$MODULES_DIR" -name "*.sh" -type f | while read -r module; do
        local rel_path="${module#$MODULES_DIR/}"
        local category="${rel_path%/*}"
        local name="${rel_path##*/}"
        name="${name%.sh}"

        echo "  $category/$name"
    done
}

# Function: Compose multiple modules (sequential execution)
compose_sequential() {
    local modules=("$@")
    local failed_modules=()
    local warning_modules=()

    for module_spec in "${modules[@]}"; do
        if [[ "$module_spec" == */* ]]; then
            # Format: category/name
            local category="${module_spec%/*}"
            local name="${module_spec#*/}"
            local module_path=$(find_module "$category" "$name")
        else
            # Direct path
            local module_path="$module_spec"
        fi

        if run_module "$module_path"; then
            continue
        else
            local exit_code=$?
            if [[ $exit_code -eq 2 ]]; then
                warning_modules+=("$module_spec")
            else
                failed_modules+=("$module_spec")
                break  # Stop on first failure
            fi
        fi
    done

    # Report results
    if [[ ${#warning_modules[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Modules with warnings: ${warning_modules[*]}${NC}"
    fi

    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Failed modules: ${failed_modules[*]}${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ All modules completed successfully${NC}"
    return 0
}

# Main execution
main() {
    case "${1:-help}" in
        "run")
            shift
            local category="$1"
            local name="$2"
            shift 2 || true
            local module_path=$(find_module "$category" "$name")
            run_module "$module_path" "$@"
            ;;
        "compose")
            shift
            compose_sequential "$@"
            ;;
        "list")
            list_modules
            ;;
        "help"|*)
            echo "OOS Module Runner"
            echo ""
            echo "Usage:"
            echo "  $0 run <category> <name> [args...]     - Run single module"
            echo "  $0 compose <mod1> <mod2> [mod3...]     - Run modules sequentially"
            echo "  $0 list                                - List available modules"
            echo ""
            echo "Examples:"
            echo "  $0 run security check_1password"
            echo "  $0 compose security/check_1password python/setup_uv git/check_status"
            echo "  $0 list"
            ;;
    esac
}

main "$@"