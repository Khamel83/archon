#!/usr/bin/env bash
# OOS Template Manager - Create projects from templates
# Implements Unix Philosophy: focused templates for rapid project creation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Function: List available templates
list_templates() {
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        echo "No templates directory found"
        return 1
    fi

    echo -e "${BLUE}📋 Available OOS Project Templates:${NC}"
    find "$TEMPLATES_DIR" -name "*.sh" -type f | while read -r template; do
        local name="${template##*/}"
        name="${name%.sh}"
        echo "  $name"
    done
}

# Function: Create project from template
create_project() {
    local template_name="$1"
    local project_name="$2"
    local project_path="${3:-$project_name}"

    local template_file="$TEMPLATES_DIR/$template_name.sh"

    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}❌ Template not found: $template_name${NC}"
        echo "Available templates:"
        list_templates
        return 1
    fi

    if [[ ! -x "$template_file" ]]; then
        echo -e "${RED}❌ Template not executable: $template_file${NC}"
        return 1
    fi

    echo -e "${BLUE}🏗️ Creating project from template: $template_name${NC}"
    bash "$template_file" "$project_name" "$project_path"
}

# Function: Show template info
show_template_info() {
    local template_name="$1"
    local template_file="$TEMPLATES_DIR/$template_name.sh"

    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}❌ Template not found: $template_name${NC}"
        return 1
    fi

    echo -e "${BLUE}📖 Template Info: $template_name${NC}"
    head -10 "$template_file" | grep "^#" | sed 's/^# //'
}

# Main execution
main() {
    case "${1:-help}" in
        "list")
            list_templates
            ;;
        "create")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 create <template> <project_name> [project_path]"
                echo ""
                echo "Available templates:"
                list_templates
                exit 1
            fi
            create_project "$2" "$3" "${4:-}"
            ;;
        "info")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 info <template>"
                exit 1
            fi
            show_template_info "$2"
            ;;
        "help"|*)
            echo "OOS Template Manager"
            echo ""
            echo "Usage:"
            echo "  $0 list                                    - List available templates"
            echo "  $0 create <template> <name> [path]        - Create project from template"
            echo "  $0 info <template>                        - Show template information"
            echo ""
            echo "Examples:"
            echo "  $0 list"
            echo "  $0 create python-project my-app"
            echo "  $0 create python-project my-app /path/to/my-app"
            echo "  $0 info python-project"
            ;;
    esac
}

main "$@"