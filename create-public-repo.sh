#!/bin/bash
# Script to package the Universal Caddy Solution for public distribution

set -e

REPO_DIR="/home/ubuntu/universal-caddy-solution"
FILES_TO_PACKAGE=(
    "CADDY_INSTRUCTIONS_FOR_AI.md"
    "UNIVERSAL_CADDY_SOLUTION.md"
    "DOMAIN_PORT_REGISTRY.md"
    "scripts/port-manager.sh"
    "scripts/domain-wizard.sh"
)

echo "📦 Creating Universal Caddy Solution package..."

# Create clean repo directory
rm -rf "$REPO_DIR"
mkdir -p "$REPO_DIR"
mkdir -p "$REPO_DIR/scripts"

# Copy files
for file in "${FILES_TO_PACKAGE[@]}"; do
    if [ -f "/home/ubuntu/archon/$file" ]; then
        cp "/home/ubuntu/archon/$file" "$REPO_DIR/$file"
        echo "✅ Copied $file"
    else
        echo "❌ Missing $file"
    fi
done

# Create README for the repo
cat > "$REPO_DIR/README.md" << 'EOF'
# Universal Caddy Multi-Domain Solution

A bulletproof, scalable solution for managing unlimited domains with Caddy reverse proxy.

## 🚀 Quick Start

1. **For AI Assistants**: Read `CADDY_INSTRUCTIONS_FOR_AI.md` - contains everything needed
2. **For Developers**: See `UNIVERSAL_CADDY_SOLUTION.md` for patterns and examples
3. **Interactive Setup**: Run `./scripts/domain-wizard.sh`

## ✨ Features

- ✅ Unlimited domains on one server
- ✅ Automatic SSL certificates (Let's Encrypt)
- ✅ Zero-downtime deployments
- ✅ Built-in health monitoring
- ✅ Port conflict prevention
- ✅ Emergency rollback procedures
- ✅ Universal patterns for any service type

## 🛠️ Installation

```bash
# Download the scripts
wget https://raw.githubusercontent.com/YOUR-USERNAME/universal-caddy-solution/main/scripts/port-manager.sh
wget https://raw.githubusercontent.com/YOUR-USERNAME/universal-caddy-solution/main/scripts/domain-wizard.sh

# Make executable
chmod +x port-manager.sh domain-wizard.sh

# Download the AI instructions
wget https://raw.githubusercontent.com/YOUR-USERNAME/universal-caddy-solution/main/CADDY_INSTRUCTIONS_FOR_AI.md
```

## 📋 Works For

- Static websites (HTML/CSS/JS)
- APIs and microservices
- SPAs with backends (React, Vue, Angular)
- Multiple services on one domain
- Enterprise multi-tenant applications
- Personal projects and client sites

## 🎯 For Claude Code Users

Simply tell Claude Code:
> "Read the CADDY_INSTRUCTIONS_FOR_AI.md file and add a domain for my service"

## 📚 Documentation

- **`CADDY_INSTRUCTIONS_FOR_AI.md`** - Complete instructions for AI assistants
- **`UNIVERSAL_CADDY_SOLUTION.md`** - Implementation patterns and examples
- **`DOMAIN_PORT_REGISTRY.md`** - Template for tracking domains/ports

## 🤝 Contributing

This solution was created to solve the complexity of managing multiple domains with Caddy.
Feel free to submit issues or improvements!

---

**Never deal with SSL certificate conflicts or domain management complexity again.**
EOF

# Create installation script
cat > "$REPO_DIR/install.sh" << 'EOF'
#!/bin/bash
# Universal Caddy Solution Installer

set -e

echo "🚀 Installing Universal Caddy Solution..."

# Create directories
mkdir -p /home/ubuntu/caddy-solution/{scripts,logs}

# Download files
BASE_URL="https://raw.githubusercontent.com/YOUR-USERNAME/universal-caddy-solution/main"

echo "📥 Downloading scripts..."
curl -sSL "$BASE_URL/scripts/port-manager.sh" -o /home/ubuntu/caddy-solution/scripts/port-manager.sh
curl -sSL "$BASE_URL/scripts/domain-wizard.sh" -o /home/ubuntu/caddy-solution/scripts/domain-wizard.sh

echo "📥 Downloading documentation..."
curl -sSL "$BASE_URL/CADDY_INSTRUCTIONS_FOR_AI.md" -o /home/ubuntu/caddy-solution/CADDY_INSTRUCTIONS_FOR_AI.md
curl -sSL "$BASE_URL/UNIVERSAL_CADDY_SOLUTION.md" -o /home/ubuntu/caddy-solution/UNIVERSAL_CADDY_SOLUTION.md
curl -sSL "$BASE_URL/DOMAIN_PORT_REGISTRY.md" -o /home/ubuntu/caddy-solution/DOMAIN_PORT_REGISTRY.md

echo "🔧 Setting permissions..."
chmod +x /home/ubuntu/caddy-solution/scripts/*.sh

echo "✅ Installation complete!"
echo ""
echo "🎯 Quick commands:"
echo "  Status check: /home/ubuntu/caddy-solution/scripts/port-manager.sh status"
echo "  Add domain:   /home/ubuntu/caddy-solution/scripts/domain-wizard.sh"
echo ""
echo "🤖 For AI assistants:"
echo "  Read: /home/ubuntu/caddy-solution/CADDY_INSTRUCTIONS_FOR_AI.md"
EOF

chmod +x "$REPO_DIR/install.sh"

echo ""
echo "✅ Package created in: $REPO_DIR"
echo ""
echo "🚀 Next steps to make it public:"
echo "1. cd $REPO_DIR"
echo "2. git init"
echo "3. git add ."
echo "4. git commit -m 'Initial commit: Universal Caddy Solution'"
echo "5. Create repo on GitHub"
echo "6. git remote add origin https://github.com/YOUR-USERNAME/universal-caddy-solution.git"
echo "7. git push -u origin main"
echo ""
echo "📋 Then users can install with:"
echo "curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/universal-caddy-solution/main/install.sh | bash"