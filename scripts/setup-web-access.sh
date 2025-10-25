#!/bin/bash

# =================================================================
# Archon Web Access Setup Script
# =================================================================
# This script sets up public web access to your Archon instance
# =================================================================

echo "🌐 Setting up web access for Archon..."

# Get the public IP
PUBLIC_IP=$(curl -s ifconfig.me)
echo "📍 Your public IP: $PUBLIC_IP"

echo ""
echo "🔧 Choose your web access method:"
echo ""
echo "1. Local Network Access (Already Working):"
echo "   URL: http://$PUBLIC_IP:5173"
echo "   Status: ✅ Working right now!"
echo ""
echo "2. SSH Tunnel (Secure Access):"
echo "   Run this on your LOCAL computer:"
echo "   ssh -L 5173:localhost:5173 ubuntu@$PUBLIC_IP"
echo "   Then access: http://localhost:5173"
echo ""
echo "3. ngrok Tunnel (Public URL - requires ngrok):"
echo "   We'll install and set up ngrok for you"
echo ""
echo "4. Cloudflare Tunnel (Custom domain - requires cloudflared):"
echo "   We'll install and set up Cloudflare tunnel"
echo ""

read -p "Choose option (1/2/3/4): " choice

case $choice in
    1)
        echo "✅ Local access is already configured!"
        echo "🌐 Access Archon at: http://$PUBLIC_IP:5173"
        echo ""
        echo "📋 Make sure ports 5173 and 8181 are open in your Oracle OCI firewall:"
        echo "   1. Go to Oracle Cloud Console"
        echo "   2. Networking → Virtual Cloud Networks"
        echo "   3. Your VCN → Security Lists"
        echo "   4. Add Ingress Rules for ports 5173 and 8181"
        ;;
    2)
        echo "🔑 SSH Tunnel Instructions:"
        echo "Run this command on your LOCAL computer (not the server):"
        echo ""
        echo "ssh -L 5173:localhost:5173 ubuntu@$PUBLIC_IP"
        echo ""
        echo "Then access Archon at: http://localhost:5173"
        echo ""
        echo "This creates a secure tunnel from your machine to the server."
        ;;
    3)
        echo "🚀 Setting up ngrok tunnel..."

        # Check if ngrok is installed
        if ! command -v ngrok &> /dev/null; then
            echo "📦 Installing ngrok..."
            curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
            echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
            sudo apt update && sudo apt install ngrok -y
        fi

        echo "🔗 Starting ngrok tunnel for port 5173..."
        echo "📋 This will give you a public URL like https://random-string.ngrok.io"
        echo ""
        echo "Run this command:"
        echo "ngrok http 5173"
        echo ""
        echo "Keep it running and use the provided ngrok URL to access Archon."
        ;;
    4)
        echo "☁️ Setting up Cloudflare tunnel..."

        # Check if cloudflared is installed
        if ! command -v cloudflared &> /dev/null; then
            echo "📦 Installing cloudflared..."
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            sudo dpkg -i cloudflared-linux-amd64.deb
            rm cloudflared-linux-amd64.deb
        fi

        echo "🌐 Cloudflare tunnel setup:"
        echo "1. First, authenticate with Cloudflare:"
        echo "   cloudflared tunnel login"
        echo ""
        echo "2. Create a tunnel:"
        echo "   cloudflared tunnel create archon-tunnel"
        echo ""
        echo "3. Create config file ~/.cloudflared/config.yml:"
        echo "tunnel: archon-tunnel"
        echo "credentials-file: ~/.cloudflared/REPLACE_WITH_UUID.json"
        echo ""
        echo "ingress:"
        echo "  - hostname: your-domain.com"
        echo "    service: http://localhost:5173"
        echo "  - service: http_status:404"
        echo ""
        echo "4. Run the tunnel:"
        echo "   cloudflared tunnel run archon-tunnel"
        ;;
    *)
        echo "❌ Invalid option. Please choose 1, 2, 3, or 4."
        exit 1
        ;;
esac

echo ""
echo "🎉 Web access setup completed!"
echo ""
echo "📝 Quick Summary:"
echo "   • Server IP: $PUBLIC_IP"
echo "   • Local URL: http://localhost:5173"
echo "   • Public URL: http://$PUBLIC_IP:5173 (if ports are open)"
echo ""
echo "🔧 Don't forget to run the migration first:"
echo "   ./scripts/auto-migrate.sh"