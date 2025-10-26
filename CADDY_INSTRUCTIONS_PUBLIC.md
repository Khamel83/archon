# CADDY INSTRUCTIONS FOR AI (PUBLIC VERSION)

This file contains the complete instructions for any AI assistant to manage Caddy reverse proxy configurations.

## 🌐 Direct Access

**Primary Instructions**: https://raw.githubusercontent.com/Khamel83/archon/main/CADDY_INSTRUCTIONS_FOR_AI.md

**Universal Solution**: https://raw.githubusercontent.com/Khamel83/archon/main/UNIVERSAL_CADDY_SOLUTION.md

## 🔧 Quick Installation

### One-Click Install:
```bash
curl -sSL https://raw.githubusercontent.com/Khamel83/archon/main/install.sh | bash
```

### Manual Install:
```bash
# Download tools
wget https://raw.githubusercontent.com/Khamel83/archon/main/scripts/port-manager.sh
wget https://raw.githubusercontent.com/Khamel83/archon/main/scripts/domain-wizard.sh

# Make executable
chmod +x port-manager.sh domain-wizard.sh
```

## 🎯 Core Usage Commands

### Check Domain Status:
```bash
./port-manager.sh status
```

### Add New Domain:
```bash
./domain-wizard.sh
```

### Manual Domain Addition:
```bash
# 1. Backup current config
sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)

# 2. Add domain block to Caddyfile
sudo tee -a /etc/caddy/Caddyfile << 'EOF'

yourdomain.com {
    reverse_proxy localhost:8080
    encode gzip
}
EOF

# 3. Validate and reload
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy

# 4. Verify
./port-manager.sh verify
```

## 🛡️ Safety Rules

### NEVER BREAK EXISTING DOMAINS:
1. Always backup before changes
2. Verify all domains work after changes
3. Test with curl before reloading
4. Have rollback plan ready

### Priority Protection:
- Domain 1: ALWAYS WORKING (never touch without testing)
- Domain 2+: Use the port manager to avoid conflicts

## 📋 Domain Patterns

### Static Website:
```caddy
domain.com {
    root * /path/to/static
    file_server
    encode gzip
}
```

### API Backend:
```caddy
api.domain.com {
    reverse_proxy localhost:8080
    encode gzip
}
```

### SPA with API:
```caddy
app.domain.com {
    handle /api/* {
        reverse_proxy localhost:8080
    }
    handle /* {
        root * /path/to/spa/dist
        file_server
        try_files {path} /index.html
    }
    encode gzip
}
```

### Multiple Services:
```caddy
platform.domain.com {
    handle /api/v1/* {
        reverse_proxy localhost:8080
    }
    handle /api/v2/* {
        reverse_proxy localhost:8081
    }
    handle /admin/* {
        reverse_proxy localhost:8082
    }
    encode gzip
}
```

## 🚨 Emergency Procedures

### Restore from Backup:
```bash
# Find latest backup
ls -la /etc/caddy/Caddyfile.backup.*

# Restore
sudo cp /etc/caddy/Caddyfile.backup.YYYYMMDD_HHMMSS /etc/caddy/Caddyfile
sudo systemctl reload caddy

# Verify
curl -I https://yourcriticaldomain.com
```

### Check Domain Health:
```bash
# Test all critical domains
curl -I https://domain1.com
curl -I https://domain2.com

# Check port usage
./port-manager.sh status
```

## 🔍 Troubleshooting

### Caddy Won't Start:
```bash
# Check config syntax
sudo caddy validate --config /etc/caddy/Caddyfile

# Check logs
sudo journalctl -u caddy --since "5 minutes ago"
```

### Domain Not Working:
```bash
# Check if port is available
./port-manager.sh next 8000

# Check if service is running
curl http://localhost:8080/health

# Check DNS
nslookup yourdomain.com
```

## 📊 Monitoring

### Daily Health Check:
```bash
# Add to crontab
0 */6 * * * curl -s https://yourdomain.com/api/health >> /var/log/domain-health.log
```

### Port Conflict Detection:
```bash
# Automated checking
./port-manager.sh status | grep "Port.*already in use"
```

## 🎯 Best Practices

### Security Headers (Add to all domains):
```caddy
domain.com {
    # Your service config here

    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Strict-Transport-Security "max-age=31536000"
    }
    encode gzip
}
```

### Rate Limiting:
```caddy
api.domain.com {
    rate_limit {
        zone api_zone
        key {remote_host}
        events 100
        window 1m
    }
    reverse_proxy localhost:8080
    encode gzip
}
```

### Load Balancing:
```caddy
api.domain.com {
    reverse_proxy localhost:8080 localhost:8081 localhost:8082 {
        health_uri /health
        health_interval 30s
    }
    encode gzip
}
```

## 🔧 Configuration File Location

**Primary Config**: `/etc/caddy/Caddyfile`
**Backup Location**: `/etc/caddy/Caddyfile.backup.*`
**Port Registry**: Update your domain assignments

## 📚 Complete Documentation

For comprehensive examples and advanced patterns, see:
- UNIVERSAL_CADDY_SOLUTION.md
- DOMAIN_PORT_REGISTRY.md
- FORK_MAINTENANCE.md

## 🚀 Production Ready

This system provides:
- ✅ Unlimited domain management
- ✅ Automatic SSL certificates
- ✅ Zero-downtime deployments
- ✅ Emergency rollback procedures
- ✅ Port conflict prevention
- ✅ AI assistant integration

Works for any project type: static sites, APIs, SPAs, microservices, enterprise applications.

---

**For the most up-to-date version**: https://github.com/Khamel83/archon