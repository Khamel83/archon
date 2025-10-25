# CADDY DOMAIN MANAGEMENT - INSTRUCTIONS FOR AI ASSISTANTS
# Single source of truth for domain/SSL management - prevents configuration conflicts

## 🚨 CRITICAL RULES - READ FIRST

### RULE #1: NEVER BREAK EXISTING DOMAINS
- **dada.khamel.com is PRIORITY #1** - it MUST ALWAYS WORK
- ALWAYS backup before ANY Caddy changes: `sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)`
- ALWAYS verify existing domains work after changes
- If ANY domain breaks, IMMEDIATELY restore from backup

### RULE #2: USE THE TOOLS PROVIDED
- **Port Manager**: `/home/ubuntu/archon/scripts/port-manager.sh`
- **Domain Wizard**: `/home/ubuntu/archon/scripts/domain-wizard.sh`
- **Registry**: `/home/ubuntu/archon/DOMAIN_PORT_REGISTRY.md`
- **Universal Guide**: `/home/ubuntu/archon/UNIVERSAL_CADDY_SOLUTION.md`

### RULE #3: STANDARD PROCEDURE FOR ANY DOMAIN CHANGE
```bash
# 1. Backup current config
sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)

# 2. Check current status
/home/ubuntu/archon/scripts/port-manager.sh status

# 3. Make changes (see patterns below)

# 4. Validate config
sudo caddy validate --config /etc/caddy/Caddyfile

# 5. Reload Caddy
sudo systemctl reload caddy

# 6. Verify ALL domains work
/home/ubuntu/archon/scripts/port-manager.sh verify
```

## 📋 CURRENT DOMAIN CONFIGURATION

### EXISTING DOMAINS (NEVER BREAK THESE)
```caddy
# /etc/caddy/Caddyfile

# dada.khamel.com - PRIORITY #1 - MUST ALWAYS WORK
dada.khamel.com {
    reverse_proxy localhost:8000
    encode gzip
}

# archon.khamel.com - Archon deployment
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
```

### PORT ASSIGNMENTS
- **8000**: dada.khamel.com backend (CRITICAL - DO NOT CHANGE)
- **8181**: Archon backend API
- **8051**: Archon MCP Server
- **8052**: Archon Agents Server
- **8200+**: Available for new services

## 🛠️ ADDING NEW DOMAINS - SAFE PATTERNS

### Pattern 1: Static Website
```caddy
newdomain.com {
    root * /path/to/static/files
    file_server
    encode gzip
}
```

### Pattern 2: API Service
```caddy
api.newdomain.com {
    reverse_proxy localhost:AVAILABLE_PORT
    encode gzip
}
```

### Pattern 3: SPA + API (React/Vue with backend)
```caddy
app.newdomain.com {
    handle /api/* {
        reverse_proxy localhost:AVAILABLE_PORT
    }
    handle /* {
        root * /path/to/spa/dist
        file_server
        try_files {path} /index.html
    }
    encode gzip
}
```

### Pattern 4: Multiple Services
```caddy
platform.newdomain.com {
    handle /api/v1/* {
        reverse_proxy localhost:PORT1
    }
    handle /api/v2/* {
        reverse_proxy localhost:PORT2
    }
    handle /admin/* {
        reverse_proxy localhost:PORT3
    }
    handle /* {
        root * /var/www/frontend
        file_server
    }
    encode gzip
}
```

## 🔧 AI ASSISTANT COMMANDS

### Quick Status Check
```bash
/home/ubuntu/archon/scripts/port-manager.sh status
```

### Add New Domain (Interactive)
```bash
/home/ubuntu/archon/scripts/domain-wizard.sh
```

### Find Available Port
```bash
/home/ubuntu/archon/scripts/port-manager.sh next 8200
```

### Emergency Backup
```bash
/home/ubuntu/archon/scripts/port-manager.sh backup
```

### Verify All Domains Healthy
```bash
/home/ubuntu/archon/scripts/port-manager.sh verify
```

## 🚨 TROUBLESHOOTING GUIDE

### If Caddy Won't Start
```bash
# Check config syntax
sudo caddy validate --config /etc/caddy/Caddyfile

# Check logs
sudo journalctl -u caddy --since "10 minutes ago"

# Restore from backup if needed
sudo cp /etc/caddy/Caddyfile.backup.YYYYMMDD_HHMMSS /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

### If Domain Returns 502/503
```bash
# Check if backend service is running
curl http://localhost:PORT/health

# Check Docker containers
docker ps | grep service-name

# Check systemd services
sudo systemctl status service-name
```

### If SSL Certificate Issues
```bash
# Check certificate status
curl -I https://domain.com

# Force certificate renewal (Caddy handles this automatically)
sudo systemctl restart caddy
```

## 📝 STEP-BY-STEP WORKFLOWS

### Adding a New API Service
1. **Get Available Port**:
   ```bash
   /home/ubuntu/archon/scripts/port-manager.sh next 8200
   # Returns: NEXT_PORT=8200
   ```

2. **Reserve Port**:
   ```bash
   /home/ubuntu/archon/scripts/port-manager.sh reserve "my-new-api" 8200
   ```

3. **Backup Config**:
   ```bash
   /home/ubuntu/archon/scripts/port-manager.sh backup
   ```

4. **Add Domain Block**:
   ```bash
   sudo tee -a /etc/caddy/Caddyfile << 'EOF'

   api.mynewdomain.com {
       reverse_proxy localhost:8200
       encode gzip
   }
   EOF
   ```

5. **Validate & Reload**:
   ```bash
   sudo caddy validate --config /etc/caddy/Caddyfile
   sudo systemctl reload caddy
   ```

6. **Verify All Domains**:
   ```bash
   /home/ubuntu/archon/scripts/port-manager.sh verify
   ```

### Adding React SPA with Backend
1. **Get Ports** (need 2: frontend files + API):
   ```bash
   /home/ubuntu/archon/scripts/port-manager.sh next 8200
   # API will use 8200, static files served by Caddy
   ```

2. **Backup & Add Configuration**:
   ```bash
   /home/ubuntu/archon/scripts/port-manager.sh backup

   sudo tee -a /etc/caddy/Caddyfile << 'EOF'

   myapp.com {
       handle /api/* {
           reverse_proxy localhost:8200
       }
       handle /* {
           root * /var/www/myapp/dist
           file_server
           try_files {path} /index.html
       }
       encode gzip
   }
   EOF
   ```

3. **Validate & Deploy**:
   ```bash
   sudo caddy validate --config /etc/caddy/Caddyfile
   sudo systemctl reload caddy
   /home/ubuntu/archon/scripts/port-manager.sh verify
   ```

## 🎯 COMMON SCENARIOS & SOLUTIONS

### "I need to add a subdomain for staging"
```bash
# Use domain wizard for guided setup
/home/ubuntu/archon/scripts/domain-wizard.sh

# Or manually add:
staging.myapp.com {
    reverse_proxy localhost:8201
    encode gzip
}
```

### "I need multiple API versions"
```bash
api.myapp.com {
    handle /v1/* {
        reverse_proxy localhost:8200
    }
    handle /v2/* {
        reverse_proxy localhost:8201
    }
    handle /* {
        respond "API Documentation" 200
    }
    encode gzip
}
```

### "I need to migrate an existing site"
1. **Set up new domain first** (test it works)
2. **Update DNS** to point to new server
3. **Keep old domain config** until migration confirmed
4. **Remove old domain** only after full verification

### "I need load balancing"
```caddy
api.myapp.com {
    reverse_proxy localhost:8200 localhost:8201 localhost:8202 {
        health_uri /health
        health_interval 30s
    }
    encode gzip
}
```

## 📊 MONITORING & MAINTENANCE

### Daily Health Check (add to cron)
```bash
0 */6 * * * /home/ubuntu/archon/scripts/port-manager.sh verify >> /home/ubuntu/archon/logs/health.log 2>&1
```

### Weekly Config Backup (add to cron)
```bash
0 2 * * 0 /home/ubuntu/archon/scripts/port-manager.sh backup >> /home/ubuntu/archon/logs/backup.log 2>&1
```

### Check Domain Status
```bash
# All domains
/home/ubuntu/archon/scripts/port-manager.sh status

# Specific domain
curl -I https://domain.com
```

## 🔐 SECURITY BEST PRACTICES

### Always Include Security Headers
```caddy
domain.com {
    # Your service config here

    # Security headers (add to ALL domains)
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }
    encode gzip
}
```

### File Permissions for Static Sites
```bash
# For any static file directory
sudo chown -R caddy:caddy /path/to/static/files
sudo chmod -R 755 /path/to/static/files
```

## 🆘 EMERGENCY PROCEDURES

### If dada.khamel.com Goes Down (CRITICAL)
```bash
# 1. IMMEDIATE restore from last backup
sudo cp /etc/caddy/Caddyfile.backup.LATEST /etc/caddy/Caddyfile
sudo systemctl reload caddy

# 2. Verify it's back up
curl -I https://dada.khamel.com

# 3. Investigate what broke it
sudo journalctl -u caddy --since "30 minutes ago"
```

### If All Domains Go Down
```bash
# 1. Check Caddy status
sudo systemctl status caddy

# 2. Restart Caddy
sudo systemctl restart caddy

# 3. If that fails, restore backup and restart
sudo cp /etc/caddy/Caddyfile.backup.LATEST /etc/caddy/Caddyfile
sudo systemctl restart caddy
```

## 💡 AI ASSISTANT GUIDELINES

### Before Making ANY Changes
1. ✅ Read this file completely
2. ✅ Check current domain status: `/home/ubuntu/archon/scripts/port-manager.sh status`
3. ✅ Backup current config: `/home/ubuntu/archon/scripts/port-manager.sh backup`
4. ✅ Verify what user actually wants vs. breaking existing setup

### When Adding Domains
1. ✅ Use the domain wizard: `/home/ubuntu/archon/scripts/domain-wizard.sh`
2. ✅ OR follow the step-by-step workflows above
3. ✅ ALWAYS verify all domains after changes
4. ✅ Update the registry: `/home/ubuntu/archon/DOMAIN_PORT_REGISTRY.md`

### When Troubleshooting
1. ✅ Check logs: `sudo journalctl -u caddy --since "10 minutes ago"`
2. ✅ Validate config: `sudo caddy validate --config /etc/caddy/Caddyfile`
3. ✅ Use port manager for diagnosis: `/home/ubuntu/archon/scripts/port-manager.sh status`
4. ✅ If all else fails, restore backup and investigate

### Communication with User
1. ✅ Show what you're going to do BEFORE doing it
2. ✅ Explain any risks (especially to existing domains)
3. ✅ Provide verification commands they can run
4. ✅ Give them the backup file location for safety

## 🎉 SUCCESS CRITERIA

After ANY domain changes, ALL of these should return success:
```bash
# Critical domain (MUST work)
curl -I https://dada.khamel.com                     # Should return 200 or 405

# Archon domain
curl -I https://archon.khamel.com                   # Should return 200
curl -s https://archon.khamel.com/api/health        # Should return {"status":"healthy"}

# Overall health check
/home/ubuntu/archon/scripts/port-manager.sh verify  # Should show all domains healthy
```

**If ANY of these fail after your changes, IMMEDIATELY restore the backup and investigate.**

---

## 📚 REFERENCE FILES
- **Registry**: `/home/ubuntu/archon/DOMAIN_PORT_REGISTRY.md` - Current domain/port assignments
- **Universal Guide**: `/home/ubuntu/archon/UNIVERSAL_CADDY_SOLUTION.md` - Complete implementation patterns
- **Port Manager**: `/home/ubuntu/archon/scripts/port-manager.sh` - Port management tool
- **Domain Wizard**: `/home/ubuntu/archon/scripts/domain-wizard.sh` - Interactive domain setup
- **Caddy Config**: `/etc/caddy/Caddyfile` - Current configuration (BACKUP BEFORE CHANGES)

This file contains everything you need to safely manage domains without breaking existing functionality. Read it, follow it, and the complexity will be eliminated.