#!/bin/bash
# PORT CLEARING HOUSE - Automated Port Management System
# Prevents port conflicts and manages domain assignments

set -e

REGISTRY_FILE="/home/ubuntu/archon/DOMAIN_PORT_REGISTRY.md"
CADDY_FILE="/etc/caddy/Caddyfile"
LOG_FILE="/home/ubuntu/archon/logs/port-manager.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    print_colored $BLUE "
╔══════════════════════════════════════════════════╗
║              PORT CLEARING HOUSE                 ║
║         Domain & Port Management System          ║
╚══════════════════════════════════════════════════╝"
}

# Check if port is available
check_port_available() {
    local port=$1
    if sudo ss -tlnp | grep -q ":${port} "; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

# Get next available port starting from a base
get_next_available_port() {
    local start_port=${1:-8200}
    local port=$start_port

    while ! check_port_available $port; do
        ((port++))
        if [ $port -gt 9999 ]; then
            print_colored $RED "ERROR: No available ports found in range ${start_port}-9999"
            exit 1
        fi
    done

    echo $port
}

# Show current port usage
show_port_status() {
    print_header
    print_colored $BLUE "\n📊 CURRENT PORT STATUS"
    print_colored $BLUE "════════════════════════"

    echo -e "\n${YELLOW}🚀 ACTIVE SERVICES:${NC}"
    sudo ss -tlnp | grep -E ':(22|80|443|8000|8051|8052|8181|3737) ' | while read line; do
        port=$(echo $line | awk '{print $4}' | cut -d: -f2)
        case $port in
            22) echo "  Port $port: SSH (System)" ;;
            80) echo "  Port $port: HTTP (Caddy)" ;;
            443) echo "  Port $port: HTTPS (Caddy)" ;;
            8000) echo "  Port $port: dada.khamel.com backend" ;;
            8051) echo "  Port $port: Archon MCP Server" ;;
            8052) echo "  Port $port: Archon Agents Server" ;;
            8181) echo "  Port $port: Archon Backend API" ;;
            3737) echo "  Port $port: Archon Frontend Dev" ;;
            *) echo "  Port $port: Unknown service" ;;
        esac
    done

    echo -e "\n${GREEN}✅ NEXT AVAILABLE PORTS:${NC}"
    for start in 8200 8300 8400 8500; do
        next_port=$(get_next_available_port $start)
        echo "  Starting from $start: Port $next_port"
    done
}

# Verify all critical domains
verify_domains() {
    print_colored $BLUE "\n🔍 DOMAIN HEALTH CHECK"
    print_colored $BLUE "════════════════════════"

    local all_good=true

    # Check dada.khamel.com (PRIORITY #1)
    print_colored $YELLOW "\n🚨 Checking dada.khamel.com (PRIORITY #1)..."
    local dada_status=$(curl -I https://dada.khamel.com 2>/dev/null | head -n1 | cut -d' ' -f2)
    if [ "$dada_status" = "200" ] || [ "$dada_status" = "405" ]; then
        print_colored $GREEN "  ✅ dada.khamel.com: HEALTHY (HTTP $dada_status)"
    else
        print_colored $RED "  ❌ dada.khamel.com: FAILED (HTTP $dada_status)"
        all_good=false
    fi

    # Check archon.khamel.com frontend
    print_colored $YELLOW "\n🏠 Checking archon.khamel.com frontend..."
    if curl -I https://archon.khamel.com 2>/dev/null | grep -q "HTTP/2 200"; then
        print_colored $GREEN "  ✅ archon.khamel.com frontend: HEALTHY"
    else
        print_colored $RED "  ❌ archon.khamel.com frontend: FAILED"
        all_good=false
    fi

    # Check archon API
    print_colored $YELLOW "\n🔌 Checking archon.khamel.com API..."
    local api_health=$(curl -s https://archon.khamel.com/api/health 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unhealthy")
    if [ "$api_health" = "healthy" ]; then
        print_colored $GREEN "  ✅ archon.khamel.com API: HEALTHY"
    else
        print_colored $RED "  ❌ archon.khamel.com API: FAILED (status: $api_health)"
        all_good=false
    fi

    # Check backend direct
    print_colored $YELLOW "\n🖥️  Checking backend direct..."
    local backend_health=$(curl -s http://localhost:8181/health 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unhealthy")
    if [ "$backend_health" = "healthy" ]; then
        print_colored $GREEN "  ✅ Backend direct: HEALTHY"
    else
        print_colored $RED "  ❌ Backend direct: FAILED (status: $backend_health)"
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        print_colored $GREEN "\n🎉 ALL DOMAINS HEALTHY!"
        log_message "All domains verified healthy"
    else
        print_colored $RED "\n⚠️  SOME DOMAINS HAVE ISSUES!"
        log_message "Domain health check found issues"
    fi

    return $([ "$all_good" = true ] && echo 0 || echo 1)
}

# Reserve a port for a new service
reserve_port() {
    local service_name=$1
    local preferred_port=$2

    if [ -z "$service_name" ]; then
        print_colored $RED "ERROR: Service name required"
        echo "Usage: $0 reserve <service_name> [preferred_port]"
        exit 1
    fi

    local port
    if [ -n "$preferred_port" ]; then
        if check_port_available $preferred_port; then
            port=$preferred_port
            print_colored $GREEN "✅ Reserved preferred port $port for $service_name"
        else
            print_colored $YELLOW "⚠️  Preferred port $preferred_port is in use"
            port=$(get_next_available_port $preferred_port)
            print_colored $GREEN "✅ Reserved next available port $port for $service_name"
        fi
    else
        port=$(get_next_available_port 8200)
        print_colored $GREEN "✅ Reserved port $port for $service_name"
    fi

    # Update registry
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "| $timestamp | Port $port reserved | $service_name | ⏳ Reserved |" >> "$REGISTRY_FILE"

    log_message "Reserved port $port for service: $service_name"
    echo "PORT_RESERVED=$port"
}

# Show help
show_help() {
    print_header
    echo -e "\n${BLUE}USAGE:${NC}"
    echo "  $0 status              - Show current port usage and domain health"
    echo "  $0 verify              - Verify all critical domains are working"
    echo "  $0 reserve <name> [port] - Reserve a port for a new service"
    echo "  $0 next [start_port]   - Get next available port"
    echo "  $0 backup              - Backup current Caddy configuration"
    echo "  $0 help                - Show this help"

    echo -e "\n${BLUE}EXAMPLES:${NC}"
    echo "  $0 status"
    echo "  $0 reserve \"my-api\" 8200"
    echo "  $0 next 8300"
    echo "  $0 verify"
}

# Backup Caddy configuration
backup_caddy() {
    local backup_file="/etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$CADDY_FILE" "$backup_file"
    print_colored $GREEN "✅ Caddy configuration backed up to: $backup_file"
    log_message "Caddy configuration backed up to: $backup_file"
    echo "BACKUP_FILE=$backup_file"
}

# Main command dispatcher
case "${1:-status}" in
    "status")
        show_port_status
        echo ""
        verify_domains
        ;;
    "verify")
        verify_domains
        ;;
    "reserve")
        reserve_port "$2" "$3"
        ;;
    "next")
        port=$(get_next_available_port "${2:-8200}")
        print_colored $GREEN "Next available port: $port"
        echo "NEXT_PORT=$port"
        ;;
    "backup")
        backup_caddy
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        print_colored $RED "Unknown command: $1"
        show_help
        exit 1
        ;;
esac