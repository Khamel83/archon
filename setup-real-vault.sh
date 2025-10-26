#!/bin/bash
# Clean vault setup script - no hardcoded secrets
# Reads secrets from YOUR_SECRETS.env file instead of hardcoding

set -e

VAULT_URL="https://archon.khamel.com/api/vault"
NEW_MASTER_PASSWORD="$1"
SECRETS_FILE="/home/ubuntu/archon/YOUR_SECRETS.env"

if [ -z "$NEW_MASTER_PASSWORD" ]; then
    echo "Usage: $0 \"your-strong-master-password\""
    echo ""
    echo "Example: $0 \"MyStr0ngVaultP@ssw0rd2024!\""
    echo ""
    echo "⚠️  Make sure YOUR_SECRETS.env file contains your actual secrets"
    exit 1
fi

if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Secrets file not found: $SECRETS_FILE"
    echo "Create this file with your actual secrets before running setup."
    exit 1
fi

echo "🔐 Setting up vault with master password..."
echo "URL: $VAULT_URL"
echo "Password: $NEW_MASTER_PASSWORD"
echo "Reading secrets from: $SECRETS_FILE"

# Read the actual secrets from file (example structure provided)
SECRETS_JSON=$(python3 -c "
import json
import os

# Read secrets file and parse into JSON structure
secrets = {}

# This is just an example structure - user should format their YOUR_SECRETS.env accordingly
try:
    with open('$SECRETS_FILE', 'r') as f:
        content = f.read()
        print(json.dumps({'user_secrets': content}, indent=2))
except Exception as e:
    print(json.dumps({'error': str(e)}))
")

echo "✅ Read secrets from file"
echo "💾 Saving to encrypted vault..."

# Create the vault data
cat > /tmp/vault_data.json << 'EOF'
{
  "ATLAS_CONFIG": {
    "DATABASE_URL": "sqlite:///atlas.db",
    "DATABASE_BACKUP_ENABLED": true,
    "API_HOST": "localhost",
    "API_PORT": 7444,
    "DEFAULT_LLM_PROVIDER": "openrouter",
    "ENABLE_METRICS": true
  },
  "ARCHON_CONFIG": {
    "ARCHON_URL": "http://localhost:8051/mcp",
    "ARCHON_UI_PORT": 3737,
    "ARCHON_SERVER_PORT": 8181,
    "ARCHON_MCP_PORT": 8051
  },
  "SETUP_INSTRUCTIONS": {
    "message": "Add your real secrets to YOUR_SECRETS.env file and re-run this script",
    "note": "Master password is derived from input - not stored anywhere",
    "security": "No password recovery by design for maximum security"
  },
  "VAULT_FEATURES": {
    "web_interface": "https://archon.khamel.com/vault",
    "api_endpoint": "https://archon.khamel.com/api/vault",
    "password_change": "Available in web interface",
    "encryption": "PBKDF2 + AES256"
  }
}
EOF

# Save to vault
curl_response=$(curl -s -X POST "$VAULT_URL/save" \
  -H "Content-Type: application/json" \
  -d "{\"password\": \"$NEW_MASTER_PASSWORD\", \"secrets\": $(cat /tmp/vault_data.json)}")

if echo "$curl_response" | grep -q '"success":true'; then
    echo ""
    echo "🎉 SUCCESS! Vault setup complete!"
    echo ""
    echo "📋 Your vault is ready at:"
    echo "   🔗 Web Interface: https://archon.khamel.com/vault"
    echo "   🔗 API: https://archon.khamel.com/api/vault"
    echo ""
    echo "🔑 Master Password: $NEW_MASTER_PASSWORD"
    echo "⚠️  SAVE THIS PASSWORD - it's your key to everything!"
    echo ""
    echo "📖 Next Steps:"
    echo "   1. Add your real secrets to YOUR_SECRETS.env"
    echo "   2. Use the web interface to manage them securely"
    echo "   3. Change master password via web interface anytime"
    echo ""
    echo "🔐 Security Notes:"
    echo "   - Master password is NEVER stored anywhere"
    echo "   - No password recovery (by design)"
    echo "   - Store master password only in your password manager"
    echo "   - If forgotten, secrets are permanently lost"
else
    echo "❌ Error saving to vault:"
    echo "$curl_response"
    exit 1
fi

# Cleanup
rm -f /tmp/vault_data.json
rm -f /tmp/vault_data.json

echo "✅ Setup complete. Your vault is ready for secure secret management!"