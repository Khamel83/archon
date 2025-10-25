# DOMAIN & PORT REGISTRY
# Master tracking system for all domains and services

## 🚨 CRITICAL DOMAINS (MUST ALWAYS WORK)

### dada.khamel.com - PRIORITY #1
- **Status**: ✅ ACTIVE
- **Service**: External service (not managed by this server)
- **Port**: 8000 (localhost proxy target)
- **SSL**: Managed by Caddy
- **Health Check**: `curl -I https://dada.khamel.com`
- **Notes**: SINGLE MOST IMPORTANT THING - NEVER BREAK THIS
- **Last Verified**: Working (HTTP/2 200)

## 📋 ACTIVE DOMAINS

### archon.khamel.com - Archon Deployment
- **Status**: ✅ ACTIVE
- **Service**: Archon Backend + Frontend
- **Ports**:
  - 8181: Backend API
  - 3737: Frontend dev server (dev only)
  - Static files: `/home/ubuntu/archon/archon-ui-main/dist`
- **SSL**: Managed by Caddy
- **Health Check**: `curl -s https://archon.khamel.com/api/health`
- **Container**: archon-backend
- **SystemD**: archon.service
- **Last Verified**: Working

## 🔧 PORT ALLOCATION REGISTRY

### System Ports (1-1023) - Reserved
- 22: SSH
- 80: HTTP (Caddy)
- 443: HTTPS (Caddy)

### Service Ports (1024-49151)
- **8000**: dada.khamel.com backend target
- **8051**: Archon MCP Server (ARCHON_MCP_PORT)
- **8052**: Archon Agents Server (ARCHON_AGENTS_PORT)
- **8181**: Archon Backend API (ARCHON_SERVER_PORT)
- **3737**: Archon Frontend Dev Server (dev only)

### Available Ports for Future Services
- 8080: Available
- 8082-8180: Available
- 8182-8999: Available
- 9000-9999: Available

## 🎯 CADDY CONFIGURATION MATRIX

Current Caddyfile structure:
```
/etc/caddy/Caddyfile
├── dada.khamel.com (Priority #1)
│   └── → localhost:8000
└── archon.khamel.com
    ├── /api/* → localhost:8181
    └── /* → static files + SPA routing
```

## 🔍 HEALTH MONITORING COMMANDS

### Verify All Domains
```bash
# Priority #1 - dada.khamel.com
curl -I https://dada.khamel.com
# Expected: HTTP/2 200

# Archon frontend
curl -I https://archon.khamel.com
# Expected: HTTP/2 200

# Archon API
curl -s https://archon.khamel.com/api/health | jq -r '.status'
# Expected: "healthy"

# Backend direct
curl -s http://localhost:8181/health | jq -r '.status'
# Expected: "healthy"
```

### Port Status Check
```bash
# Check what's listening on each port
sudo netstat -tlnp | grep -E ':(8000|8051|8052|8181|3737) '

# Check Caddy status
sudo systemctl status caddy

# Check Archon service
sudo systemctl status archon.service

# Check Docker containers
docker ps | grep archon
```

## 🚀 ADDING NEW DOMAINS - SAFE PROCEDURE

### Before Adding Any Domain:
1. **BACKUP Current State**:
   ```bash
   sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)
   ```

2. **Verify Current Domains Work**:
   ```bash
   curl -I https://dada.khamel.com
   curl -I https://archon.khamel.com/api/health
   ```

3. **Check Port Availability**:
   ```bash
   sudo netstat -tlnp | grep :PROPOSED_PORT
   ```

### Adding New Domain Steps:
1. Choose available port from registry above
2. Add domain to this registry first
3. Update Caddyfile with new domain block
4. Test Caddy config: `sudo caddy validate --config /etc/caddy/Caddyfile`
5. Reload Caddy: `sudo systemctl reload caddy`
6. Verify ALL domains still work (especially dada.khamel.com)
7. Update this registry with verification timestamp

### Emergency Rollback:
```bash
# If anything breaks dada.khamel.com:
sudo cp /etc/caddy/Caddyfile.backup.YYYYMMDD_HHMMSS /etc/caddy/Caddyfile
sudo systemctl reload caddy
curl -I https://dada.khamel.com  # MUST return 200
```

## 📊 DOMAIN DEPENDENCY MATRIX

```
dada.khamel.com
├── Dependencies: External service on port 8000
├── SSL: Auto-managed by Caddy
├── Critical Level: MAXIMUM (NEVER BREAK)
└── Monitors: Manual verification required

archon.khamel.com
├── Dependencies:
│   ├── archon-backend container (port 8181)
│   ├── Static files (/home/ubuntu/archon/archon-ui-main/dist)
│   └── File permissions (caddy:caddy ownership)
├── SSL: Auto-managed by Caddy
├── Critical Level: High
└── Monitors: Health endpoint + systemd service
```

## 🛡️ BULLETPROOF RULES

### Rule #1: dada.khamel.com Protection
- NEVER modify dada.khamel.com configuration without backup
- ALWAYS verify dada.khamel.com works after ANY Caddy change
- If dada.khamel.com breaks, IMMEDIATELY rollback

### Rule #2: Port Conflict Prevention
- ALWAYS check port availability before assignment
- Update this registry BEFORE making changes
- Use sequential port assignment (8181, 8182, 8183...)

### Rule #3: Change Management
- Backup Caddyfile before changes
- Validate config before reload
- Test all domains after changes
- Document changes in this registry

### Rule #4: Monitoring
- Health checks for all critical services
- Regular verification of domain functionality
- Automated alerts for service failures

## 📝 CHANGE LOG

| Date | Action | Domains Affected | Status |
|------|--------|-----------------|--------|
| Current | Created registry | All | ✅ |
| Previous | Fixed multi-domain SSL | dada + archon | ✅ |
| Previous | Restored dada.khamel.com | dada.khamel.com | ✅ |

## 🔄 MAINTENANCE SCHEDULE

### Daily (Automated via systemd)
- Archon service health monitoring
- Container restart on failure
- Backend health checks

### Weekly (Manual)
- Verify all domains respond correctly
- Check SSL certificate status
- Review port usage
- Update this registry if needed

### Monthly (Manual)
- SSL certificate renewal verification
- System resource usage review
- Backup cleanup
- Security updates

## 🆘 EMERGENCY CONTACTS & PROCEDURES

### If dada.khamel.com Goes Down:
1. **IMMEDIATE**: Restore from last known good Caddyfile backup
2. **VERIFY**: `curl -I https://dada.khamel.com` returns 200
3. **INVESTIGATE**: Check what changed since last working state
4. **DOCUMENT**: Update this registry with incident details

### If archon.khamel.com Goes Down:
1. Check container status: `docker ps | grep archon`
2. Check service status: `sudo systemctl status archon.service`
3. Check logs: `sudo journalctl -u archon.service --since "5 minutes ago"`
4. Restart if needed: `sudo systemctl restart archon.service`

This registry serves as the single source of truth for all domain and port management on this server.