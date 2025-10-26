#!/bin/bash

# Archon Vault Login Script - FINAL VERSION
# Usage: ./LOGIN.sh 833fwjU2ntxcfYLpez6f

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check password argument
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Please provide your master password${NC}"
    echo -e "${YELLOW}Usage: ./LOGIN.sh \"your-master-password\"${NC}"
    exit 1
fi

PASSWORD="$1"
VAULT_URL="https://archon.khamel.com"

echo -e "${BLUE}🔐 Archon Vault Login${NC}"
echo -e "${BLUE}─────────────────────${NC}"
echo ""
echo -e "🌐 URL: ${VAULT_URL}/vault"
echo ""

# Test vault access
echo -e "🔄 Testing vault access..."
RESPONSE=$(curl -s -X POST "${VAULT_URL}/api/vault/unlock" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"${PASSWORD}\"}")

# Debug output removed for cleaner interface

if echo "$RESPONSE" | grep -q '"success":true'; then
    SECRET_COUNT=$(echo "$RESPONSE" | grep -o '"secrets":' | wc -l)
    TOTAL_SECRETS=$(echo "$RESPONSE" | grep -o '"' | wc -l)
    SECRET_COUNT=$((TOTAL_SECRETS / 4))  # Rough estimate of key-value pairs
    echo -e "${GREEN}✅ LOGIN SUCCESSFUL!${NC}"
    echo -e "${GREEN}📊 Secrets in vault: ${SECRET_COUNT}+${NC}"
    echo ""
    echo -e "${BLUE}🌐 ACCESS OPTIONS:${NC}"
    echo -e "   Web Interface: ${VAULT_URL}/vault"
    echo -e "   Password: ${PASSWORD}"
    echo ""
    echo -e "${YELLOW}💡 To change password: Use the web interface above${NC}"
    echo -e "${YELLOW}   After changing, your new password will be required forever${NC}"
    echo ""
    echo -e "${GREEN}🎉 ALL SET! No more scripts needed!${NC}"
else
    echo -e "${RED}❌ LOGIN FAILED${NC}"
    echo -e "${YELLOW}❌ Invalid password or vault not initialized${NC}"
    echo ""
    echo -e "${BLUE}🔧 Quick Fix Option:${NC}"
    echo -e "   1. Delete vault directory: rm -rf vault/"
    echo -e "   2. Run this command to recreate with password:"
    echo -e "      curl -X POST \"${VAULT_URL}/api/vault/save\" \\"
    echo -e "        -H \"Content-Type: application/json\" \\"
    echo -e "        -d '{\"password\": \"${PASSWORD}\", \"secrets\": {\"API_KEY\": \"your_key_here\"}}'"
    echo ""
    echo -e "${BLUE}🔧 Or use setup script:${NC}"
    echo -e "   1. Delete vault directory: rm -rf vault/"
    echo -e "   2. Run: ./VAULT_SETUP.sh \"new-master-password\""
    echo -e "   3. Reload your secrets"
    exit 1
fi