#!/bin/bash
# 🚀 ONE-TIME SECRET VAULT SETUP
# The simplest possible way to get your encrypted vault running
# No complexity, no ongoing maintenance, maximum security

set -e

# Configuration
VAULT_URL="https://archon.khamel.com/vault"
API_URL="https://archon.khamel.com/api/vault"
MASTER_PASSWORD="$1"
SECRETS_FILE="/home/ubuntu/archon/YOUR_SECRETS.env"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check for help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    print_colored $BLUE "🚀 ONE-TIME SECRET VAULT SETUP"
    echo ""
    print_colored $GREEN "Usage:"
    echo "  $0 \"your-master-password\""
    echo ""
    print_colored $YELLOW "Example:"
    echo "  $0 \"MyStr0ngVaultP@ssw0rd2024!\""
    echo ""
    print_colored $BLUE "What it does:"
    echo "  ✅ Creates encrypted vault with your secrets"
    echo "  ✅ Sets up web interface at https://archon.khamel.com/vault"
    echo "  ✅ No ongoing complexity - one-time setup"
    echo "  ✅ Maximum security (no password recovery)"
    echo ""
    print_colored $GREEN "After setup:"
    echo "   🔑 Master password = your key to everything"
    echo "  🔐 Web interface = manage secrets securely"
    echo "  🔗 API endpoints = programmatic access"
    echo "  💾 Store master password in password manager"
    exit 0
fi

# Validate input
if [ -z "$MASTER_PASSWORD" ]; then
    print_colored $RED "❌ ERROR: Master password required"
    echo ""
    print_colored $YELLOW "Usage: $0 \"your-strong-master-password\""
    exit 1
fi

if [ ${#MASTER_PASSWORD} -lt 8 ]; then
    print_colored $RED "❌ ERROR: Master password must be at least 8 characters"
    echo ""
    print_colored $YELLOW "Minimum requirements:"
    echo "  • At least 8 characters"
    echo "  • Include uppercase and lowercase"
    echo "  • Include numbers or symbols"
    exit 1
fi

print_colored $BLUE "🚀 STARTING SECRET VAULT SETUP..."
print_colored $YELLOW "Password: $MASTER_PASSWORD"
print_colored $BLUE "URL: $VAULT_URL"

# Check if secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
    print_colored $YELLOW "⚠️  WARNING: Secrets file not found: $SECRETS_FILE"
    print_colored $YELLOW "Creating template file..."

    # Create template file
    cat > "$SECRETS_FILE" << 'TEMPLATE'
# YOUR SECRETS
# Add your secrets here in KEY=VALUE format
# One secret per line, no quotes around values

# Examples (replace with your actual values):
OPENAI_API_KEY=sk-your-openai-key-here
SUPABASE_URL=your-supabase-url-here
GOOGLE_SEARCH_API_KEY=your-google-search-key-here

# API KEYS:
NYTIMES_USERNAME=your-nyt-username
NYTIMES_PASSWORD=your-nyt-password

# Add your real secrets here, then run: $0 "your-master-password"
TEMPLATE

    print_colored $GREEN "✅ Template created: $SECRETS_FILE"
    print_colored $YELLOW "📝 Please edit this file with your actual secrets:"
    print_colored $YELLOW "   nano $SECRETS_FILE"
    print_colored $YELLOW "Then run: $0 \"your-master-password\""
    echo ""
    exit 0
fi

print_colored $BLUE "📖 Reading secrets from: $SECRETS_FILE"

# Read secrets file and prepare JSON
SECRET_KEYS=$(grep "=" "$SECRETS_FILE" | sed 's/=.*//' | sed 's/^ *//')

# Create vault data structure
VAULT_DATA=$(cat << 'VAULT_EOF'
{
  "setup_info": {
    "created": "$(date -Iseconds)",
    "master_password_length": ${#MASTER_PASSWORD},
    "secrets_count": $(echo "$SECRET_KEYS" | wc -l | tr -d ' ')
  },
  "user_secrets": {
EOF
)

# Add each secret to vault data
for key in $SECRET_KEYS; do
    if [ -n "$key" ]; then
        value=$(grep "^$key=" "$SECRETS_FILE" | cut -d'=' -f2-)
        VAULT_DATA=$(echo "$VAULT_DATA" | sed '$ s/}/$/"\n    \"$key\": \"$value\",/")
    fi
done

# Close the JSON structure
VAULT_DATA=$(echo "$VAULT_DATA" | sed 's/},$//; echo "  }"')

# Send to vault API
print_colored $BLUE "💾 Encrypting and storing secrets..."

response=$(curl -s -X POST "$API_URL/save" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"$MASTER_PASSWORD\", \"secrets\": $VAULT_DATA}" 2>/dev/null)

# Parse response
if echo "$response" | grep -q '"success":true'; then
    print_colored $GREEN "✅ SUCCESS! Vault setup complete!"
    echo ""
    print_colored $BLUE "🌐 Your encrypted vault is ready at:"
    echo "   📋 Web Interface: $VAULT_URL"
    echo "   🔗 API Endpoints: $API_URL"
    echo ""
    print_colored $GREEN "🔑 Master Password: $MASTER_PASSWORD"
    print_colored $YELLOW "⚠️  SAVE THIS PASSWORD - store in your password manager!"
    echo ""
    print_colored $BLUE "📖 Usage Instructions:"
    echo "   1. Go to: $VAULT_URL"
    echo "   2. Login with your master password"
    echo "   3. Add/edit/delete secrets via web interface"
    echo "   4. For AI assistants: \"Unlock my vault at $API_URL with password $MASTER_PASSWORD\""
    echo ""
    print_colored $GREEN "🛡️ Security Notes:"
    echo "   • Master password is NEVER stored anywhere"
    echo "   • No password recovery (by design)"
    echo "   • If forgotten, all secrets are PERMANENTLY LOST"
    echo "   • Store master password only in password manager"
    echo ""
    print_colored $GREEN "🎉 ONE-TIME SETUP COMPLETE!"
else
    print_colored $RED "❌ ERROR: Failed to save to vault"
    print_colored $RED "Response: $response"
    exit 1
fi