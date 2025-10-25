#!/bin/bash
# UNIVERSAL DOMAIN WIZARD - Add any domain to any server with zero config
# Works for static sites, APIs, SPAs, microservices - everything

set -e

REGISTRY_FILE="/home/ubuntu/archon/DOMAIN_PORT_REGISTRY.md"
CADDY_FILE="/etc/caddy/Caddyfile"
PORT_MANAGER="/home/ubuntu/archon/scripts/port-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    print_colored $CYAN "
╔══════════════════════════════════════════════════╗
║              UNIVERSAL DOMAIN WIZARD             ║
║        Add ANY domain to ANY server easily       ║
╚══════════════════════════════════════════════════╝"
}

# Interactive domain setup
add_domain_interactive() {
    print_header

    print_colored $BLUE "\n🌐 DOMAIN CONFIGURATION WIZARD"
    print_colored $BLUE "════════════════════════════════"

    # Get domain name
    while true; do
        echo -e "\n${YELLOW}Enter domain name (e.g., mysite.com):${NC}"
        read -r domain_name

        if [[ $domain_name =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_colored $RED "Invalid domain format. Please use format: example.com"
        fi
    done

    # Check if domain already exists
    if grep -q "$domain_name" "$CADDY_FILE" 2>/dev/null; then
        print_colored $RED "❌ Domain $domain_name already exists in Caddy configuration!"
        exit 1
    fi

    # Choose service type
    echo -e "\n${YELLOW}Select service type:${NC}"
    echo "1) Static website (HTML/CSS/JS files)"
    echo "2) API/Backend service (reverse proxy)"
    echo "3) SPA with API (React/Vue + backend)"
    echo "4) Multiple services/paths"
    echo "5) Custom configuration"

    while true; do
        echo -e "\n${YELLOW}Enter choice (1-5):${NC}"
        read -r service_type
        case $service_type in
            [1-5]) break ;;
            *) print_colored $RED "Please enter 1, 2, 3, 4, or 5" ;;
        esac
    done

    case $service_type in
        1) setup_static_site "$domain_name" ;;
        2) setup_api_service "$domain_name" ;;
        3) setup_spa_with_api "$domain_name" ;;
        4) setup_multiple_services "$domain_name" ;;
        5) setup_custom "$domain_name" ;;
    esac
}

# Setup static website
setup_static_site() {
    local domain=$1

    echo -e "\n${YELLOW}Enter path to static files (e.g., /var/www/mysite):${NC}"
    read -r static_path

    if [ ! -d "$static_path" ]; then
        echo -e "\n${YELLOW}Directory doesn't exist. Create it? (y/n):${NC}"
        read -r create_dir
        if [ "$create_dir" = "y" ]; then
            sudo mkdir -p "$static_path"
            sudo chown -R caddy:caddy "$static_path"
            print_colored $GREEN "✅ Created directory: $static_path"
        else
            print_colored $RED "❌ Cannot proceed without valid directory"
            exit 1
        fi
    fi

    local config="
$domain {
    root * $static_path
    file_server
    encode gzip
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
    }
}"

    deploy_domain "$domain" "Static Website" "N/A" "$static_path" "$config"
}

# Setup API/Backend service
setup_api_service() {
    local domain=$1

    # Get or assign port
    local port=$(get_port_for_service "$domain-api")

    local config="
$domain {
    reverse_proxy localhost:$port
    encode gzip
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
    }
}"

    deploy_domain "$domain" "API/Backend Service" "$port" "localhost:$port" "$config"

    print_colored $YELLOW "\n🚀 Next steps:"
    print_colored $BLUE "  1. Start your service on port $port"
    print_colored $BLUE "  2. Test: curl -I https://$domain"
}

# Setup SPA with API
setup_spa_with_api() {
    local domain=$1

    echo -e "\n${YELLOW}Enter path to SPA build files (e.g., /var/www/myapp/dist):${NC}"
    read -r spa_path

    local api_port=$(get_port_for_service "$domain-api")

    if [ ! -d "$spa_path" ]; then
        echo -e "\n${YELLOW}Directory doesn't exist. Create it? (y/n):${NC}"
        read -r create_dir
        if [ "$create_dir" = "y" ]; then
            sudo mkdir -p "$spa_path"
            sudo chown -R caddy:caddy "$spa_path"
        fi
    fi

    local config="
$domain {
    handle /api/* {
        reverse_proxy localhost:$api_port
    }
    handle /* {
        root * $spa_path
        file_server
        try_files {path} /index.html
    }
    encode gzip
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
    }
}"

    deploy_domain "$domain" "SPA + API" "$api_port" "$spa_path" "$config"

    print_colored $YELLOW "\n🚀 Next steps:"
    print_colored $BLUE "  1. Deploy your SPA files to: $spa_path"
    print_colored $BLUE "  2. Start your API service on port $api_port"
    print_colored $BLUE "  3. Test frontend: curl -I https://$domain"
    print_colored $BLUE "  4. Test API: curl -I https://$domain/api/health"
}

# Setup multiple services
setup_multiple_services() {
    local domain=$1

    echo -e "\n${YELLOW}How many services/paths do you need?${NC}"
    read -r num_services

    local config="\n$domain {"
    local services_info=""

    for ((i=1; i<=num_services; i++)); do
        echo -e "\n${CYAN}Service $i:${NC}"
        echo -e "${YELLOW}Enter path (e.g., /api/v1/* or /admin/*):${NC}"
        read -r service_path

        local port=$(get_port_for_service "$domain-service$i")

        config="$config
    handle $service_path {
        reverse_proxy localhost:$port
    }"

        services_info="$services_info\n  Service $i: $service_path -> Port $port"
    done

    # Add default handler
    echo -e "\n${YELLOW}Default handler for /* (static files path or leave empty for 404):${NC}"
    read -r default_path

    if [ -n "$default_path" ]; then
        config="$config
    handle /* {
        root * $default_path
        file_server
        try_files {path} /index.html
    }"
    fi

    config="$config
    encode gzip
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
    }
}"

    deploy_domain "$domain" "Multiple Services" "Various" "Multiple paths" "$config"

    print_colored $YELLOW "\n🚀 Services configured:"
    echo -e "$services_info"
}

# Setup custom configuration
setup_custom() {
    local domain=$1

    print_colored $YELLOW "\n📝 Custom Configuration Mode"
    print_colored $BLUE "You'll need to manually edit the Caddy configuration after this wizard."

    local config="
$domain {
    # Add your custom configuration here
    respond \"Hello from $domain!\" 200
    encode gzip
}"

    deploy_domain "$domain" "Custom Configuration" "Manual" "Manual setup" "$config"

    print_colored $YELLOW "\n🔧 Next steps:"
    print_colored $BLUE "  1. Edit /etc/caddy/Caddyfile"
    print_colored $BLUE "  2. Find the $domain block"
    print_colored $BLUE "  3. Replace with your custom configuration"
    print_colored $BLUE "  4. Run: sudo systemctl reload caddy"
}

# Get port for service
get_port_for_service() {
    local service_name=$1

    echo -e "\n${YELLOW}Port for $service_name (enter number or press Enter for auto-assign):${NC}"
    read -r preferred_port

    if [ -n "$preferred_port" ]; then
        local result=$($PORT_MANAGER reserve "$service_name" "$preferred_port" 2>/dev/null || echo "")
        if echo "$result" | grep -q "PORT_RESERVED="; then
            echo "$result" | grep "PORT_RESERVED=" | cut -d= -f2
        else
            print_colored $RED "Port $preferred_port not available, auto-assigning..."
            $PORT_MANAGER reserve "$service_name" | grep "PORT_RESERVED=" | cut -d= -f2
        fi
    else
        $PORT_MANAGER reserve "$service_name" | grep "PORT_RESERVED=" | cut -d= -f2
    fi
}

# Deploy domain configuration
deploy_domain() {
    local domain=$1
    local service_type=$2
    local port=$3
    local path=$4
    local config=$5

    print_colored $BLUE "\n🚀 DEPLOYING DOMAIN CONFIGURATION"
    print_colored $BLUE "═══════════════════════════════════"

    # Backup current config
    print_colored $YELLOW "\n1. Backing up current configuration..."
    local backup_result=$($PORT_MANAGER backup)
    local backup_file=$(echo "$backup_result" | grep "BACKUP_FILE=" | cut -d= -f2)
    print_colored $GREEN "   ✅ Backup created: $backup_file"

    # Add to Caddy config
    print_colored $YELLOW "\n2. Adding domain to Caddy configuration..."
    echo "$config" | sudo tee -a "$CADDY_FILE" > /dev/null
    print_colored $GREEN "   ✅ Added $domain to Caddyfile"

    # Validate config
    print_colored $YELLOW "\n3. Validating Caddy configuration..."
    if sudo caddy validate --config "$CADDY_FILE"; then
        print_colored $GREEN "   ✅ Configuration is valid"
    else
        print_colored $RED "   ❌ Configuration validation failed!"
        print_colored $YELLOW "   🔄 Restoring backup..."
        sudo cp "$backup_file" "$CADDY_FILE"
        print_colored $RED "   ❌ Deployment failed - configuration restored"
        exit 1
    fi

    # Reload Caddy
    print_colored $YELLOW "\n4. Reloading Caddy..."
    if sudo systemctl reload caddy; then
        print_colored $GREEN "   ✅ Caddy reloaded successfully"
    else
        print_colored $RED "   ❌ Caddy reload failed!"
        exit 1
    fi

    # Update registry
    print_colored $YELLOW "\n5. Updating domain registry..."
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cat >> "$REGISTRY_FILE" << EOF

### $domain - $service_type
- **Status**: ✅ ACTIVE
- **Service**: $service_type
- **Port**: $port
- **Path**: $path
- **SSL**: Managed by Caddy
- **Health Check**: \`curl -I https://$domain\`
- **Added**: $timestamp
EOF
    print_colored $GREEN "   ✅ Registry updated"

    # Verify all domains
    print_colored $YELLOW "\n6. Verifying all domains..."
    if $PORT_MANAGER verify > /dev/null 2>&1; then
        print_colored $GREEN "   ✅ All domains healthy"
    else
        print_colored $YELLOW "   ⚠️  Some domains may have issues - check manually"
    fi

    # Success summary
    print_colored $GREEN "\n🎉 DEPLOYMENT SUCCESSFUL!"
    print_colored $BLUE "═══════════════════════════"
    print_colored $BLUE "Domain: https://$domain"
    print_colored $BLUE "Service Type: $service_type"
    print_colored $BLUE "Port: $port"
    print_colored $BLUE "SSL: Automatic (Let's Encrypt)"

    print_colored $YELLOW "\n🔍 Test your domain:"
    print_colored $BLUE "curl -I https://$domain"

    print_colored $YELLOW "\n📊 View all domains:"
    print_colored $BLUE "$PORT_MANAGER status"
}

# Command line interface
case "${1:-interactive}" in
    "interactive"|"add")
        add_domain_interactive
        ;;
    "help"|"--help"|"-h")
        print_header
        echo -e "\n${BLUE}USAGE:${NC}"
        echo "  $0                    - Interactive domain wizard"
        echo "  $0 add                - Same as interactive"
        echo "  $0 help               - Show this help"
        echo ""
        echo -e "${BLUE}EXAMPLES:${NC}"
        echo "  $0                    # Start interactive wizard"
        echo "  $0 add                # Add a new domain interactively"
        ;;
    *)
        print_colored $RED "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac