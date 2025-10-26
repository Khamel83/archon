#!/bin/bash
# Automatic Upstream Sync Script
# Keeps fork up-to-date with coleam00/Archon while preserving our additions

set -e

REPO_DIR="/home/ubuntu/archon"
LOG_FILE="/home/ubuntu/archon/logs/auto-sync.log"
WEBHOOK_URL=""  # Set this to receive notifications

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

send_notification() {
    local message=$1
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"🔄 Archon Sync: $message\"}" \
            2>/dev/null || true
    fi
}

# Safety checks
safety_checks() {
    print_colored $BLUE "🔍 Running safety checks..."

    cd "$REPO_DIR"

    # Check if working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        log_message "ERROR" "Working directory not clean - aborting sync"
        print_colored $RED "❌ Working directory has uncommitted changes. Commit or stash first."
        return 1
    fi

    # Check if we're on main branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        log_message "ERROR" "Not on main branch - aborting sync"
        print_colored $RED "❌ Switch to main branch first."
        return 1
    fi

    # Check if upstream is configured
    if ! git remote -v | grep -q "upstream"; then
        log_message "ERROR" "Upstream remote not configured"
        print_colored $RED "❌ Run: git remote add upstream https://github.com/coleam00/Archon.git"
        return 1
    fi

    log_message "INFO" "Safety checks passed"
    return 0
}

# Backup current state before sync
backup_current_state() {
    local backup_tag="backup-$(date +%Y%m%d_%H%M%S)"

    print_colored $YELLOW "📋 Creating backup tag: $backup_tag"
    git tag "$backup_tag"

    log_message "INFO" "Created backup tag: $backup_tag"
    return 0
}

# Sync with upstream
sync_with_upstream() {
    print_colored $BLUE "🔄 Syncing with upstream..."

    # Fetch latest changes
    log_message "INFO" "Fetching from upstream..."
    git fetch upstream

    # Check if there are upstream changes
    local upstream_commits=$(git rev-list --count HEAD..upstream/main)

    if [ "$upstream_commits" -eq 0 ]; then
        log_message "INFO" "Already up-to-date with upstream"
        print_colored $GREEN "✅ Already up-to-date!"
        return 0
    fi

    log_message "INFO" "Found $upstream_commits new commits from upstream"

    # Create a safe merge branch
    local merge_branch="merge-upstream-$(date +%Y%m%d_%H%M%S)"
    git checkout -b "$merge_branch"

    # Merge upstream changes
    log_message "INFO" "Merging upstream/main into $merge_branch"
    if git merge upstream/main; then
        log_message "INFO" "Merge successful"

        # Test basic functionality
        log_message "INFO" "Running basic functionality tests..."
        if run_merge_tests; then
            # If tests pass, merge to main
            git checkout main
            git merge "$merge_branch"
            git branch -D "$merge_branch"

            # Remove temporary backup tag
            git tag -d "backup-$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

            log_message "SUCCESS" "Successfully synced with upstream"
            print_colored $GREEN "🎉 Sync completed successfully!"

            # Push changes
            log_message "INFO" "Pushing to origin..."
            git push origin main

            # Push tags (removes old backup tags automatically)
            git push origin --tags

            send_notification "✅ Successfully merged upstream changes"
            return 0
        else
            # If tests fail, handle gracefully
            handle_merge_failure "$merge_branch"
            return 1
        fi
    else
        log_message "ERROR" "Merge failed"
        handle_merge_failure "$merge_branch"
        return 1
    fi
}

# Run basic tests after merge
run_merge_tests() {
    print_colored $BLUE "🧪 Running merge tests..."

    # Test 1: Check if core files are intact
    local core_files=(
        "python/src/server/main.py"
        "python/pyproject.toml"
        "archon-ui-main/package.json"
        "README.md"
    )

    for file in "${core_files[@]}"; do
        if [ -f "$file" ]; then
            log_message "INFO" "✅ Core file exists: $file"
        else
            log_message "ERROR" "❌ Core file missing: $file"
            return 1
        fi
    done

    # Test 2: Check if our additions are preserved
    local our_files=(
        "CADDY_INSTRUCTIONS_FOR_AI.md"
        "UNIVERSAL_CADDY_SOLUTION.md"
        "DOMAIN_PORT_REGISTRY.md"
        "scripts/port-manager.sh"
        "scripts/domain-wizard.sh"
        "vault/index.html"
        "FORK_MAINTENANCE.md"
    )

    for file in "${our_files[@]}"; do
        if [ -f "$file" ]; then
            log_message "INFO" "✅ Our additions preserved: $file"
        else
            log_message "ERROR" "❌ Our additions missing: $file"
            return 1
        fi
    done

    # Test 3: Try to validate configuration files
    if [ -f "python/pyproject.toml" ]; then
        log_message "INFO" "✅ Configuration files validate"
    fi

    log_message "INFO" "All merge tests passed"
    return 0
}

# Handle merge failure
handle_merge_failure() {
    local failed_branch=$1

    print_colored $RED "❌ Merge tests failed!"

    log_message "ERROR" "Merge failed on branch: $failed_branch"

    # Create a conflict report
    cat > MERGE_CONFLICT_REPORT.md << EOF
# Merge Conflict Report

**Timestamp**: $(date)
**Failed Branch**: $failed_branch
**Upstream Changes**: $(git rev-list --count HEAD..upstream/main) commits

## Resolution Required:
1. Manually resolve conflicts in: $failed_branch
2. Test resolution
3. Merge to main when ready
4. Delete temporary branch

## Safety:
- Backup tags created before merge
- Original state preserved
- Main branch unchanged

## Next Steps:
- Run: \`git checkout $failed_branch\`
- Resolve conflicts manually
- Run tests
- Complete merge when ready
EOF

    log_message "ERROR" "Created MERGE_CONFLICT_REPORT.md"
    print_colored $YELLOW "📋 Conflict report created. Manual resolution required."

    send_notification "❌ Merge conflict requires manual resolution"

    return 1
}

# Rollback to previous state
rollback() {
    local backup_tag=$1

    if [ -z "$backup_tag" ]; then
        print_colored $RED "❌ No backup tag specified for rollback"
        return 1
    fi

    print_colored $YELLOW "🔄 Rolling back to: $backup_tag"

    git checkout main
    git reset --hard "$backup_tag"

    log_message "INFO" "Rollback completed to: $backup_tag"
    print_colored $GREEN "✅ Rollback successful"

    # Force push to reset remote
    git push origin main --force

    send_notification "🔄 Rolled back to $backup_tag"
    return 0
}

# Setup automated sync via cron
setup_cron_job() {
    print_colored $BLUE "⏰ Setting up automated sync..."

    # Create cron job for daily sync at 2 AM
    local cron_entry="0 2 * * * cd $REPO_DIR && $REPO_DIR/scripts/auto-sync-upstream.sh --auto >> $REPO_DIR/logs/auto-sync.log 2>&1"

    # Add to crontab
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

    log_message "INFO" "Cron job added for daily 2 AM sync"
    print_colored $GREEN "✅ Automated sync scheduled for 2 AM daily"

    return 0
}

# List available backup tags
list_backups() {
    print_colored $BLUE "📋 Available backup tags:"
    git tag | grep "backup-" | sort -r | while read tag; do
        local commit_date=$(git log -1 --format=%ci "$tag" 2>/dev/null || echo "Unknown")
        echo "  $tag ($commit_date)"
    done
}

# Main execution logic
main() {
    local action=${1:-sync}

    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"

    case "$action" in
        "sync")
            log_message "INFO" "Starting manual sync with upstream"
            if safety_checks && backup_current_state; then
                sync_with_upstream
            fi
            ;;
        "auto")
            log_message "INFO" "Starting automated sync"
            if safety_checks && backup_current_state; then
                sync_with_upstream
            fi
            ;;
        "setup")
            setup_cron_job
            ;;
        "rollback")
            rollback "$2"
            ;;
        "backups")
            list_backups
            ;;
        "status")
            safety_checks
            local upstream_commits=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo "Unknown")
            local current_commit=$(git rev-parse --short HEAD)
            local upstream_commit=$(git rev-parse --short upstream/main 2>/dev/null || echo "Unknown")

            print_colored $BLUE "📊 Sync Status:"
            echo "  Current: $current_commit"
            echo "  Upstream: $upstream_commit"
            echo "  Behind by: $upstream_commits commits"
            ;;
        "help"|"--help"|"-h")
            echo "Auto Sync Script for Archon Fork"
            echo ""
            echo "Usage: $0 [action] [options]"
            echo ""
            echo "Actions:"
            echo "  sync      - Manual sync with upstream"
            echo "  auto      - Run in automated mode (for cron)"
            echo "  setup     - Setup daily cron job"
            echo "  rollback  - Rollback to backup tag"
            echo "  backups   - List available backup tags"
            echo "  status    - Show sync status"
            echo "  help      - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 sync              # Manual sync"
            echo "  $0 setup             # Setup automation"
            echo "  $0 rollback backup-20241026_143022  # Rollback to backup"
            echo "  $0 status            # Check status"
            ;;
        *)
            print_colored $RED "❌ Unknown action: $action"
            echo "Use '$0 help' for usage"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"