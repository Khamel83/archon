#!/bin/bash
# SIMPLE WORKING ARCHON BACKUP - NO FANCY FEATURES, JUST WORKS
set -e

echo "🔧 Restoring Archon to SIMPLE WORKING STATE..."

# 1. Stop everything
sudo systemctl stop archon.service 2>/dev/null || true
sudo systemctl stop caddy 2>/dev/null || true
docker stop archon-backend 2>/dev/null || true
docker rm archon-backend 2>/dev/null || true

# 2. SIMPLE Caddy config (no fancy features)
sudo tee /etc/caddy/Caddyfile > /dev/null << 'EOF'
archon.khamel.com {
    root * /home/ubuntu/archon/archon-ui-main/dist

    handle /api/* {
        reverse_proxy localhost:8181
    }

    handle /* {
        file_server
        try_files {path} /index.html
    }

    encode gzip
}
EOF

# 3. Fix file permissions
sudo chown -R caddy:caddy /home/ubuntu/archon/archon-ui-main/dist
sudo chmod -R 755 /home/ubuntu/archon/archon-ui-main/dist

# 4. Clear SSL cache and restart Caddy
sudo rm -rf /var/lib/caddy/.local/share/caddy/certificates/* 2>/dev/null || true
sudo systemctl start caddy

# 5. Start backend container (simple, no fancy monitoring)
docker run -d --name archon-backend --restart unless-stopped -p 8181:8181 \
  -e SUPABASE_URL=https://kndpikghdwaktsknapfe.supabase.co \
  -e SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZHBpa2doZHdha3Rza25hcGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjM5ODA3MCwiZXhwIjoyMDcxOTc0MDcwfQ.VSHtOAYDLG7lwvR5si6WDdgacrGOWJX2hyLEjmFllFE \
  -e OPENAI_API_BASE_URL=https://openrouter.ai/api/v1 \
  -e OPENAI_API_KEY=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 \
  -e ARCHON_SERVER_PORT=8181 \
  -e ARCHON_MCP_PORT=8051 \
  -e ARCHON_AGENTS_PORT=8052 \
  -e LOG_LEVEL=INFO \
  archon-server

# 6. Wait and test
sleep 30

echo "🧪 Testing restoration..."
if curl -s https://archon.khamel.com/api/health | grep -q "healthy"; then
    echo "✅ SUCCESS! Archon is working:"
    echo "   Frontend: https://archon.khamel.com"
    echo "   API: https://archon.khamel.com/api/health"
    echo "   Backend: http://localhost:8181/health"
else
    echo "❌ Still having issues. Check:"
    echo "   docker logs archon-backend"
    echo "   sudo journalctl -u caddy"
fi