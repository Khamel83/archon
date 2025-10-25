# Archon Deployment Failure Scenarios & Recovery

This document outlines the top 5 reasons why the bulletproof Archon deployment might stop running, with specific symptoms and recovery procedures.

## Current Status Check Commands
```bash
# Full system health check
curl -I https://archon.khamel.com                    # Frontend (should be 200)
curl -s http://localhost:8181/health | jq -r '.status'    # Backend (should be "healthy")
curl -s https://archon.khamel.com/api/health | jq -r '.status' # API (should be "healthy")
sudo systemctl status archon.service                    # Service (should be "active")
docker ps | grep archon-backend                     # Container (should be "Up")
nslookup kndpikghdwaktsknapfe.supabase.co        # DNS (should resolve)
```

---

## 1. DNS Resolution Failure

**Symptoms:**
- Backend container starts but crashes with database connection errors
- Health checks fail with "database unavailable"
- `nslookup kndpikghdwaktsknapfe.supabase.co` returns NXDOMAIN

**Root Causes:**
- Google DNS (8.8.8.8) blocked or unreachable
- Supabase domain changed or deleted
- Network connectivity issues
- DNS cache poisoning

**Recovery:**
```bash
# Test different DNS servers
nslookup kndpikghdwaktsknapfe.supabase.co @8.8.4.4
nslookup kndpikghdwaktsknapfe.supabase.co @1.1.1.1

# Flush DNS cache
sudo systemctl restart systemd-resolved

# Check if it's a domain issue
curl -v https://supabase.co  # Test main Supabase site

# If DNS fails completely, use IP (temporary)
# Get Supabase IP and update systemd service
```

---

## 2. Docker Container Crashes

**Symptoms:**
- Container exits with code 1, 125, or 137
- `docker ps` shows no containers
- Systemd service in restart loop
- Health check failures in logs

**Root Causes:**
- Out of memory (OOM killer)
- Database connection failures
- Missing environment variables
- Port conflicts
- Image corruption

**Recovery:**
```bash
# Check container logs
docker logs archon-backend --tail 50

# Check system resources
free -h
df -h

# Manual restart
sudo systemctl restart archon.service

# Rebuild image if corrupted
cd /home/ubuntu/archon
docker build -t archon-server-new -f python/Dockerfile.server python/
docker stop archon-backend
docker rm archon-backend
# Update systemd service to use new image temporarily
```

---

## 3. Systemd Service Failures

**Symptoms:**
- `systemctl status archon.service` shows "failed" or "inactive"
- Service doesn't start on boot
- Restart loops with backoff
- Permission errors in journal

**Root Causes:**
- Syntax errors in service file
- Permission issues with deployment script
- Resource conflicts
- Missing dependencies

**Recovery:**
```bash
# Check service logs
sudo journalctl -u archon.service --since "5 minutes ago" -f

# Validate service file
sudo systemd-analyze verify /etc/systemd/system/archon.service

# Test manual execution
/home/ubuntu/archon/deploy-archon.sh

# Reset and restart
sudo systemctl daemon-reload
sudo systemctl reset-failed archon.service
sudo systemctl start archon.service
```

---

## 4. Caddy/Proxy Issues

**Symptoms:**
- Frontend returns 403 Forbidden errors
- `curl -I https://archon.khamel.com` returns 5xx errors
- API calls fail with connection refused
- SSL certificate errors

**Root Causes:**
- File permission issues (Caddy can't access frontend files)
- SSL certificate renewal failures
- Caddy configuration errors
- Port conflicts or firewall blocks
- Reverse proxy configuration errors

**Recovery:**
```bash
# Check Caddy logs
sudo journalctl -u caddy.service --since "5 minutes ago" -f

# Test file permissions
sudo -u caddy ls -la /home/ubuntu/archon/archon-ui-main/dist/

# Fix permissions (most common issue)
sudo chown -R caddy:caddy /home/ubuntu/archon/archon-ui-main/dist
sudo chmod -R 755 /home/ubuntu/archon/archon-ui-main/dist

# Restart Caddy
sudo systemctl restart caddy

# Test Caddy config
sudo caddy validate --config /etc/caddy/Caddyfile

# Check for port conflicts
sudo netstat -tlnp | grep ':80\|:443'
```

---

## 5. Database/Supabase Issues

**Symptoms:**
- Backend starts but health checks fail with database errors
- API endpoints return 500 errors about database
- Connection timeout errors
- Migration required errors

**Root Causes:**
- Supabase service outage
- Invalid service key or expired credentials
- Database connection limits exceeded
- Schema migration required
- Network connectivity to Supabase blocked

**Recovery:**
```bash
# Test Supabase connectivity
curl -H "Authorization: Bearer YOUR_KEY" \
     -H "apikey: YOUR_KEY" \
     https://kndpikghdwaktsknapfe.supabase.co/rest/v1/

# Check backend logs for database errors
sudo tail -20 /var/log/archon-deploy.log | grep -i "database\|supabase\|connection"

# Test with minimal backend (if available)
# This would require a simplified version that doesn't depend on database

# Check if credentials are still valid
# Go to Supabase dashboard to verify service status
```

---

## Emergency Recovery Procedures

### Complete Service Reset
```bash
# Stop everything gracefully
sudo systemctl stop archon.service caddy

# Clean up containers
docker stop archon-backend 2>/dev/null || true
docker rm archon-backend 2>/dev/null || true

# Clean up Docker resources
docker system prune -f

# Restart from scratch
sudo systemctl start caddy
sudo systemctl start archon.service

# Verify everything works
curl -I https://archon.khamel.com
curl -s http://localhost:8181/health
```

### Bootstrap from Scratch
```bash
# If everything fails, rebuild from known working state
cd /home/ubuntu/archon
git checkout HEAD  # Go to last known working state
./deploy-archon.sh  # Redeploy with working configuration
```

### Monitoring and Prevention
```bash
# Set up continuous monitoring
while true; do
    curl -s https://archon.khamel.com/api/health
    sleep 300  # Check every 5 minutes
done &

# Log rotation setup
sudo nano /etc/logrotate.d/archon-deploy
# Add log rotation rules for long-term deployment
```

---

## Quick Diagnosis Commands

```bash
# One-liner to check everything
echo "=== ARCHON HEALTH ===" && \
curl -I https://archon.khamel.com | head -1 && \
docker ps | grep archon-backend && \
sudo systemctl status archon.service --no-pager | head -3 && \
nslookup kndpikghdwaktsknapfe.supabase.co | head -3 && \
echo "=== END HEALTH CHECK ==="

# Automated health check script
#!/bin/bash
while true; do
    if curl -s https://archon.khamel.com/api/health | grep -q "healthy"; then
        echo "✅ All systems operational"
    else
        echo "❌ System failure detected"
        sudo systemctl restart archon.service
    fi
    sleep 300
done
```

## Summary

This deployment handles all common failure scenarios with automatic recovery and manual intervention procedures. The key is monitoring and rapid response to any service degradation.