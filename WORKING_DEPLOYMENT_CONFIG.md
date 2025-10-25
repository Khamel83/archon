# Working Archon Deployment Configuration
# Saved on: $(date)

This file contains the exact working configuration for the bulletproof Archon deployment.

## Current Status: ✅ BULLETPROOF VERIFIED

### All Components Working:
- ✅ Frontend: https://archon.khamel.com (HTTP 200)
- ✅ Backend: http://localhost:8181/health (healthy)
- ✅ API Proxy: https://archon.khamel.com/api/health (healthy)
- ✅ Container: archon-backend running and healthy
- ✅ Service: systemd archon.service active and monitoring

### Configuration Files:
1. **DNS Configuration**: `/etc/systemd/resolved.conf`
   ```
   [Resolve]
   DNS=8.8.8.8 1.1.1.1 9.9.9.9 1.0.0.1
   FallbackDNS=8.8.4.4 208.67.222.222
   ```

2. **Caddy Configuration**: `/etc/caddy/Caddyfile`
   ```
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
       header {
           X-Content-Type-Options nosniff
           X-Frame-Options DENY
           X-XSS-Protection "1; mode=block"
       }
   }
   ```

3. **Systemd Service**: `/etc/systemd/system/archon.service`
   ```
   [Unit]
   Description=Archon Backend Service (Bulletproof)
   After=network.target docker.service systemd-resolved.service
   Requires=docker.service
   Wants=systemd-resolved.service

   [Service]
   Type=simple
   User=ubuntu
   Group=ubuntu
   WorkingDirectory=/home/ubuntu/archon
   ExecStart=/home/ubuntu/archon/deploy-archon.sh
   Restart=always
   RestartSec=60

   [Install]
   WantedBy=multi-user.target
   ```

4. **Deployment Script**: `/home/ubuntu/archon/deploy-archon.sh`
   - Has health monitoring, auto-recovery, and logging
   - Manages Docker container lifecycle
   - Includes comprehensive error handling

### Environment Variables:
```
SUPABASE_URL=https://kndpikghdwaktsknapfe.supabase.co
SUPABASE_SERVICE_KEY=[REDACTED]
OPENAI_API_BASE_URL=https://openrouter.ai/api/v1
OPENAI_API_KEY=[REDACTED]
ARCHON_SERVER_PORT=8181
ARCHON_MCP_PORT=8051
ARCHON_AGENTS_PORT=8052
LOG_LEVEL=INFO
```

### Container Information:
- **Name**: archon-backend
- **Image**: archon-server:latest
- **Port**: 8181:8181
- **Status**: Running and healthy
- **Health**: /health endpoint responding with "healthy" status

### Verification Commands (for future reference):
```bash
# Check everything is working
curl -I https://archon.khamel.com
curl -s http://localhost:8181/health | jq -r '.status'
curl -s https://archon.khamel.com/api/health | jq -r '.status'

# Check service status
sudo systemctl status archon.service

# Check container
docker ps | grep archon-backend

# Check logs
sudo tail -f /var/log/archon-deploy.log
```

### Recovery Tested:
- ✅ Service restarts on boot (systemd enable)
- ✅ Container restarts on failure (tested)
- ✅ Health monitoring active (deploy-archon.sh)
- ✅ DNS resolution working (Google DNS)
- ✅ Frontend serving with SSL (Caddy)
- ✅ API proxy functioning (Caddy → Backend)

## Summary: This is a working, bulletproof "set it and forget it" deployment configuration.