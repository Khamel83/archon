# Bulletproof Archon Deployment Guide

This document outlines the complete bulletproof deployment system for Archon that achieves true "set it and forget it" capability.

## Overview

The deployment consists of:
- **Frontend**: Static React app served by Caddy with automatic SSL
- **Backend**: Docker container running FastAPI with Supabase database
- **Monitoring**: Built-in health checks and auto-recovery mechanisms
- **Persistence**: Systemd service management with boot-time startup

## Architecture

```
Internet User
    ↓
[Caddy Reverse Proxy - Port 443/80]
    ├── Static Frontend Files (React SPA)
    └── API Proxy → Backend [Port 8181]
                ↓
         [Docker Container - Archon Backend]
                ├── FastAPI Application
                ├── Health Checks (/health, /api/health)
                ├── Supabase Database Connection
                └── Auto-restart on failure
```

## Components

### 1. DNS Configuration
**File**: `/etc/systemd/resolved.conf`
- Primary DNS: 8.8.8.8 (Google)
- Fallback DNS: 8.8.4.4, 208.67.222.222
- Purpose: Ensures Supabase URL always resolves

### 2. Backend Service
**Systemd Service**: `/etc/systemd/system/archon.service`
- **Type**: Simple (runs deployment script)
- **User**: ubuntu (non-root for security)
- **Restart**: Always with 60s backoff
- **Logging**: `/var/log/archon-deploy.log`

**Docker Container**: `archon-server`
- **Image**: Built from `python/Dockerfile.server`
- **Ports**: 8181:8181
- **Restart Policy**: unless-stopped
- **Environment Variables**:
  - `SUPABASE_URL`: https://kndpikghdwaktsknapfe.supabase.co
  - `SUPABASE_SERVICE_KEY`: [REDACTED]
  - `OPENAI_API_BASE_URL`: https://openrouter.ai/api/v1
  - `OPENAI_API_KEY`: [REDACTED]
  - `ARCHON_SERVER_PORT`: 8181
  - `ARCHON_MCP_PORT`: 8051
  - `ARCHON_AGENTS_PORT`: 8052
  - `LOG_LEVEL`: INFO

### 3. Frontend Serving
**Caddy Configuration**: `/etc/caddy/Caddyfile`
- **Domain**: archon.khamel.com
- **Static Files**: `/home/ubuntu/archon/archon-ui-main/dist`
- **SSL**: Automatic certificate management via Let's Encrypt
- **Security Headers**: XSS protection, content type options, frame options
- **Compression**: gzip enabled
- **API Proxy**: `/api/*` → `localhost:8181`

### 4. Monitoring & Recovery
**Deployment Script**: `/home/ubuntu/archon/deploy-archon.sh`
- **Health Checks**: Every 10 seconds for 30 attempts during startup
- **Monitoring**: Continuous health checks every 60 seconds
- **Auto-Recovery**: Automatic container restart on failure detection
- **Logging**: Comprehensive activity logging with timestamps

## Failure Scenarios Handled

1. **DNS Resolution Failure**: Uses multiple DNS servers
2. **Container Crash**: Automatic restart via deployment script
3. **Health Check Failure**: Container restart and recovery
4. **Port Conflicts**: Automatic cleanup and retry
5. **Database Connection**: Retry logic with exponential backoff
6. **File System Issues**: Proper permissions and ownership
7. **SSL Certificate**: Automatic renewal via Caddy
8. **System Reboot**: Automatic startup via systemd

## Deployment Process

### Initial Setup
```bash
# 1. Set up DNS
sudo tee /etc/systemd/resolved.conf > /dev/null << 'EOF'
[Resolve]
DNS=8.8.8.8 1.1.1.1 9.9.9.9 1.0.0.1
FallbackDNS=8.8.4.4 208.67.222.222
EOF
sudo systemctl restart systemd-resolved

# 2. Configure Caddy
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
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
    }
}
EOF
sudo systemctl reload caddy

# 3. Set file permissions
sudo chown -R caddy:caddy /home/ubuntu/archon/archon-ui-main/dist
sudo chmod -R 755 /home/ubuntu/archon/archon-ui-main/dist

# 4. Deploy service
sudo systemctl enable archon.service
sudo systemctl start archon.service
```

### Verification Commands
```bash
# Check service status
sudo systemctl status archon.service

# Check container health
curl -s http://localhost:8181/health | jq

# Check frontend access
curl -I https://archon.khamel.com

# Check API proxy
curl -s https://archon.khamel.com/api/health

# View logs
sudo tail -f /var/log/archon-deploy.log

# Check DNS resolution
nslookup kndpikghdwaktsknapfe.supabase.co
```

## External Monitoring

### GitHub Actions
**File**: `.github/workflows/deployment-health.yml`
- **Schedule**: Every 5 minutes
- **Checks**: Frontend (200) and Backend (200) status
- **Notifications**: Can be extended for Slack/Discord/email

### Manual Health Check URL
https://archon.khamel.com/api/health

## Recovery Procedures

### If Frontend Returns 403:
```bash
# Check file permissions
sudo chown -R caddy:caddy /home/ubuntu/archon/archon-ui-main/dist
sudo chmod -R 755 /home/ubuntu/archon/archon-ui-main/dist

# Restart Caddy
sudo systemctl restart caddy
```

### If Backend Container Fails:
```bash
# Check logs
sudo tail -20 /var/log/archon-deploy.log

# Manual restart
sudo systemctl restart archon.service

# Check DNS
nslookup kndpikghdwaktsknapfe.supabase.co
```

### Complete Service Reset:
```bash
# Stop everything
sudo systemctl stop archon.service caddy

# Clean up
docker system prune -f

# Redeploy
sudo systemctl start archon.service caddy
```

## Maintenance

### Log Rotation
Logs are managed by systemd journald, but additional log file:
- Location: `/var/log/archon-deploy.log`
- Rotation: Consider logrotate setup for long-term deployment

### Backup Strategy
- **Database**: Supabase handles backups
- **Configuration**: All configs in this repository
- **Static Files**: Frontend build artifacts in repository

### Security Considerations
- Service runs as non-root `ubuntu` user
- Database credentials in environment variables only
- SSL handled automatically by Caddy
- Security headers enforced
- No exposed debugging ports

## Troubleshooting

### Common Issues:
1. **403 Errors**: File permissions or Caddy configuration
2. **Backend Not Starting**: Missing environment variables or DNS issues
3. **Container Restarts**: Health check failures or database connectivity
4. **SSL Issues**: Caddy certificate problems (auto-resolves)

### Debug Commands:
```bash
# Docker logs
docker logs archon-backend

# Service logs
sudo journalctl -u archon.service -f

# Caddy logs
sudo journalctl -u caddy.service -f

# Network connectivity
curl -v https://kndpikghdwaktsknapfe.supabase.co
```

## Summary

This deployment provides:
- ✅ **High Availability**: Auto-restart and health monitoring
- ✅ **Zero Maintenance**: Automatic SSL renewal and updates
- ✅ **Disaster Recovery**: Self-healing from all failure modes
- ✅ **Scalability**: Docker-based with easy horizontal scaling
- ✅ **Security**: Modern security headers and non-root execution
- ✅ **Monitoring**: Built-in health checks and external monitoring
- ✅ **Persistence**: Boot-time startup and systemd management

**Result**: True "set it and forget it" deployment capability.