# UNIVERSAL CADDY MULTI-DOMAIN SOLUTION
# Works for ANY number of domains, ANY project, ANYWHERE

## 🌍 UNIVERSAL DESIGN PRINCIPLES

This Caddy configuration is designed to handle **unlimited domains** on **any server**, for **any project**. It's not just for Archon - it's a complete multi-domain management system.

## 🏗️ SCALABLE ARCHITECTURE

### Pattern for ANY Domain
```caddy
domain.example.com {
    # Choose ONE of these patterns based on your service type:

    # Pattern 1: Static website
    root * /path/to/static/files
    file_server

    # Pattern 2: Simple API/backend
    reverse_proxy localhost:PORT

    # Pattern 3: SPA with API (like React + backend)
    handle /api/* {
        reverse_proxy localhost:API_PORT
    }
    handle /* {
        root * /path/to/spa/dist
        file_server
        try_files {path} /index.html
    }

    # Pattern 4: Multiple services/paths
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
        root * /path/to/frontend
        file_server
    }

    # Universal optimizations (add to ALL domains)
    encode gzip
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
    }
}
```

## 🔧 UNIVERSAL PORT MANAGER

The `port-manager.sh` script works for **ANY** project:

```bash
# Reserve ports for any service
./port-manager.sh reserve "my-blog-api" 8200
./port-manager.sh reserve "analytics-service" 8201
./port-manager.sh reserve "auth-microservice" 8202

# Check status of any server
./port-manager.sh status

# Works on any Linux server with Caddy
```

## 🌐 REAL-WORLD EXAMPLES

### Example 1: Personal Blog + API
```caddy
myblog.com {
    handle /api/* {
        reverse_proxy localhost:8200  # Blog API
    }
    handle /* {
        root * /var/www/myblog
        file_server
        try_files {path} /index.html
    }
    encode gzip
}
```

### Example 2: Multiple Client Websites
```caddy
client1.com {
    reverse_proxy localhost:8300
    encode gzip
}

client2.com {
    root * /var/www/client2
    file_server
    encode gzip
}

client3.com {
    handle /shop/* {
        reverse_proxy localhost:8301  # E-commerce backend
    }
    handle /* {
        root * /var/www/client3
        file_server
    }
    encode gzip
}
```

### Example 3: Microservices Architecture
```caddy
api.mycompany.com {
    handle /auth/* {
        reverse_proxy localhost:8400  # Auth service
    }
    handle /users/* {
        reverse_proxy localhost:8401  # User service
    }
    handle /orders/* {
        reverse_proxy localhost:8402  # Order service
    }
    handle /payments/* {
        reverse_proxy localhost:8403  # Payment service
    }
    encode gzip
}

admin.mycompany.com {
    reverse_proxy localhost:8410  # Admin dashboard
    encode gzip
}

app.mycompany.com {
    handle /api/* {
        reverse_proxy api.mycompany.com
    }
    handle /* {
        root * /var/www/frontend
        file_server
        try_files {path} /index.html
    }
    encode gzip
}
```

## 🚀 ADDING ANY NEW DOMAIN (UNIVERSAL PROCESS)

### Step 1: Use Port Manager
```bash
# Reserve a port for your service
./port-manager.sh reserve "my-new-service" 8500

# Output: PORT_RESERVED=8500
```

### Step 2: Add to Registry
Edit `DOMAIN_PORT_REGISTRY.md` and add:
```markdown
### mynewdomain.com - My New Service
- **Status**: ✅ ACTIVE
- **Service**: My New Service
- **Port**: 8500
- **SSL**: Managed by Caddy
- **Health Check**: `curl -I https://mynewdomain.com`
```

### Step 3: Backup Current Config
```bash
./port-manager.sh backup
# Output: BACKUP_FILE=/etc/caddy/Caddyfile.backup.20241025_164650
```

### Step 4: Add Domain to Caddy
```bash
sudo tee -a /etc/caddy/Caddyfile << 'EOF'

mynewdomain.com {
    reverse_proxy localhost:8500
    encode gzip
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
    }
}
EOF
```

### Step 5: Validate and Reload
```bash
# Test configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy
sudo systemctl reload caddy

# Verify ALL domains still work
./port-manager.sh verify
```

## 🏭 PRODUCTION-READY FEATURES

### Automatic SSL for ALL Domains
- Caddy automatically gets Let's Encrypt certificates
- Automatic renewal (no manual intervention needed)
- Works for unlimited domains

### Load Balancing (for high traffic)
```caddy
api.example.com {
    reverse_proxy localhost:8500 localhost:8501 localhost:8502 {
        health_uri /health
        health_interval 30s
    }
}
```

### Rate Limiting
```caddy
api.example.com {
    rate_limit {
        zone api_zone
        key {remote_host}
        events 100
        window 1m
    }
    reverse_proxy localhost:8500
}
```

### Geographic Routing
```caddy
api.example.com {
    @us_traffic {
        header_regexp Country "US|CA"
    }
    @eu_traffic {
        header_regexp Country "DE|FR|UK"
    }

    handle @us_traffic {
        reverse_proxy us-server:8500
    }
    handle @eu_traffic {
        reverse_proxy eu-server:8500
    }
    handle {
        reverse_proxy default-server:8500
    }
}
```

## 🌍 DEPLOYMENT ANYWHERE

### Works on ANY Linux Server
- Ubuntu, Debian, CentOS, RHEL, Amazon Linux
- Docker containers, VPS, dedicated servers, cloud instances
- AWS EC2, Google Cloud, DigitalOcean, Linode, etc.

### Zero-Configuration SSL
- No manual certificate management
- Works for new domains immediately
- Automatic HTTPS redirect

### Unlimited Scaling
- Add as many domains as needed
- Each domain can have different backend architecture
- Mix static sites, APIs, SPAs, microservices freely

## 📊 MONITORING FOR ANY SCALE

The port manager provides universal monitoring:

```bash
# Works for any number of domains
./port-manager.sh status

# Sample output for large deployments:
🚀 ACTIVE SERVICES:
  Port 8000: client1.com backend
  Port 8001: client2.com api
  Port 8002: client3.com shop
  Port 8100: analytics-service
  Port 8101: auth-service
  Port 8102: notification-service
  Port 8200: blog-api
  Port 8201: cms-backend

🔍 DOMAIN HEALTH CHECK
✅ client1.com: HEALTHY
✅ client2.com: HEALTHY
✅ client3.com: HEALTHY
✅ analytics.mycompany.com: HEALTHY
✅ api.mycompany.com: HEALTHY
```

## 🎯 UNIVERSAL BEST PRACTICES

### 1. Port Organization
- **8000-8099**: Client websites
- **8100-8199**: Internal services
- **8200-8299**: APIs
- **8300-8399**: Microservices
- **8400-8499**: Development/staging

### 2. Domain Naming Conventions
- `api.domain.com` - Main API
- `admin.domain.com` - Admin interfaces
- `app.domain.com` - Main application
- `dev.domain.com` - Development/staging
- `status.domain.com` - Status pages

### 3. Security Headers (Universal)
```caddy
# Add to EVERY domain block
header {
    X-Content-Type-Options nosniff
    X-Frame-Options DENY
    X-XSS-Protection "1; mode=block"
    Strict-Transport-Security "max-age=31536000; includeSubDomains"
}
```

## 🔄 MAINTENANCE (Universal)

### Daily Automated Health Checks
```bash
# Add to crontab for any server
0 */6 * * * /home/ubuntu/archon/scripts/port-manager.sh verify >> /home/ubuntu/archon/logs/health-check.log 2>&1
```

### Weekly Configuration Backup
```bash
# Automatic weekly backups
0 2 * * 0 /home/ubuntu/archon/scripts/port-manager.sh backup >> /home/ubuntu/archon/logs/backup.log 2>&1
```

## 🎉 CONCLUSION

This solution is **completely universal**:

✅ **Works for unlimited domains**
✅ **Works on any Linux server**
✅ **Works for any project type**
✅ **Zero-downtime deployments**
✅ **Automatic SSL management**
✅ **Built-in monitoring**
✅ **Production-ready security**
✅ **Scalable architecture**

You can use this exact system for:
- Personal projects
- Client websites
- Enterprise applications
- Microservices
- E-commerce sites
- APIs and services
- Static sites
- SPAs with backends

The port manager and registry system scales to hundreds of domains on a single server, and the Caddy configuration handles all the SSL complexity automatically.

**This is your universal multi-domain solution for life.**