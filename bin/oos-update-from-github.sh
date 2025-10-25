#!/usr/bin/env bash
set -euo pipefail

# OOS Subfolder Operating System - GitHub Update System
# Always pulls latest OOS from GitHub and updates current project
# This is the foundation of the "one command to rule them all" philosophy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
OOS_REPO_URL="https://github.com/Khamel83/oos.git"
OOS_CACHE_DIR="$HOME/.oos-cache"
OOS_UPDATE_INTERVAL=3600  # 1 hour in seconds

# Global state
SLASH_COMMANDS_CHANGED=false

echo -e "${BOLD}${CYAN}🌐 OOS Subfolder Operating System - GitHub Update${NC}"
echo "=================================================="

# Function: Check if we need to update OOS cache
needs_update() {
    local cache_marker="$OOS_CACHE_DIR/.last_update"

    # No cache exists
    if [[ ! -f "$cache_marker" ]]; then
        return 0
    fi

    # Check if cache is older than update interval
    local last_update=$(cat "$cache_marker" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local age=$((current_time - last_update))

    if [[ $age -gt $OOS_UPDATE_INTERVAL ]]; then
        return 0
    fi

    return 1
}

# Function: Update OOS cache from GitHub
update_oos_cache() {
    echo -e "${BLUE}📦 Updating OOS cache from GitHub...${NC}"

    mkdir -p "$OOS_CACHE_DIR"

    if [[ -d "$OOS_CACHE_DIR/oos" ]]; then
        echo "• Pulling latest changes..."
        cd "$OOS_CACHE_DIR/oos"
        git fetch origin master >/dev/null 2>&1
        git reset --hard origin/master >/dev/null 2>&1
        echo "✅ OOS cache updated"
    else
        echo "• Cloning OOS repository..."
        cd "$OOS_CACHE_DIR"
        git clone "$OOS_REPO_URL" oos >/dev/null 2>&1
        echo "✅ OOS repository cloned"
    fi

    # Mark update time
    date +%s > "$OOS_CACHE_DIR/.last_update"
    cd "$PROJECT_ROOT"
}

# Function: Get current project type
detect_project_type() {
    if [[ -f "pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        echo "node"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    else
        echo "generic"
    fi
}

# Function: Update current project with OOS features
update_current_project() {
    local project_type=$(detect_project_type)
    echo -e "${BLUE}🔧 Updating current project (type: $project_type)...${NC}"

    local oos_source="$OOS_CACHE_DIR/oos"

    # Create necessary directories
    mkdir -p bin .claude

    # Always copy core OOS scripts
    echo "• Installing core OOS scripts..."
    cp "$oos_source/bin/dev-gate.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/claude-dev-gate.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/claude-require-gate.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/claude-start-coding.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/claude-dev-python.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/claude-dev-test.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/claude-dev-uv.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/setup-uv-environment.sh" bin/ 2>/dev/null || true
    cp "$oos_source/bin/install-mandatory-hooks.sh" bin/ 2>/dev/null || true

    # Copy this update script itself
    cp "$oos_source/bin/oos-update-from-github.sh" bin/ 2>/dev/null || true

    # Make scripts executable
    chmod +x bin/*.sh 2>/dev/null || true

    # Update working slash commands (ALWAYS - this is the key requirement)
    echo "• Updating Claude Code slash commands..."
    if [[ -f "$oos_source/.claude/project_commands.json" ]]; then
        # Check if slash commands actually changed
        if [[ -f ".claude/slash_commands.json" ]]; then
            if ! diff -q "$oos_source/.claude/project_commands.json" ".claude/slash_commands.json" >/dev/null 2>&1; then
                SLASH_COMMANDS_CHANGED=true
            fi
        else
            SLASH_COMMANDS_CHANGED=true
        fi

        # Always copy to ensure latest working commands
        cp "$oos_source/.claude/project_commands.json" .claude/slash_commands.json
        echo "✅ Slash commands updated"
    fi

    # Update auto patterns
    if [[ -f "$oos_source/.claude/auto_patterns.json" ]]; then
        cp "$oos_source/.claude/auto_patterns.json" .claude/ 2>/dev/null || true
    fi

    # Copy ops/ directory if it exists in OOS (for Agent-OS integration)
    if [[ -d "$oos_source/ops" ]]; then
        echo "• Updating ops/ directory..."
        cp -r "$oos_source/ops" . 2>/dev/null || true
        echo "✅ ops/ directory updated"
    fi

    # Project-specific updates
    case "$project_type" in
        python)
            echo "• Updating Python project configuration..."
            if [[ ! -f "pyproject.toml" ]]; then
                cp "$oos_source/pyproject.toml" . 2>/dev/null || true
            fi
            ;;
        node)
            echo "• Node.js project detected"
            # Add node-specific OOS integrations here
            ;;
        *)
            echo "• Generic project type"
            ;;
    esac

    echo "✅ Project updated with latest OOS features"
}

# Function: Install git hooks
install_git_hooks() {
    if [[ -d ".git" ]] && [[ -f "bin/install-mandatory-hooks.sh" ]]; then
        echo -e "${BLUE}🎣 Installing git hooks...${NC}"
        bash bin/install-mandatory-hooks.sh >/dev/null 2>&1 || true
        echo "✅ Git hooks installed"
    fi
}

# Function: Show summary
show_summary() {
    echo -e "\n${PURPLE}📋 Update Summary:${NC}"
    echo "✅ OOS cache updated from GitHub"
    echo "✅ Core development scripts installed"
    echo "✅ Claude Code slash commands updated"
    echo "✅ Project configuration updated"

    if [[ -d "ops" ]]; then
        echo "✅ Agent-OS ops/ directory available"
    fi

    echo -e "\n${YELLOW}💡 Next Steps:${NC}"
    if [[ "$SLASH_COMMANDS_CHANGED" == "true" ]]; then
        echo -e "${BOLD}${RED}🔄 IMPORTANT: Slash commands changed - RESTART Claude Code now!${NC}"
        echo "• Exit Claude Code and restart to load new commands"
        echo "• After restart, run: /start-coding to validate everything"
    else
        echo "• Run: /start-coding to validate everything"
    fi

    if [[ -d "ops" ]]; then
        echo "• Use /oos-start if you have ops/ directory"
    fi

    echo -e "\n${BOLD}${GREEN}🎉 OOS subfolder operating system updated!${NC}"
}

# Main execution
main() {
    # Check if we need to update
    if needs_update; then
        update_oos_cache
    else
        echo -e "${GREEN}✅ OOS cache is up to date${NC}"
    fi

    # Always update current project (slash commands must be current)
    update_current_project

    # Install git hooks if available
    install_git_hooks

    # Show summary
    show_summary
}

# Run main function
main "$@"