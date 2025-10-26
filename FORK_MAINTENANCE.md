# Fork Maintenance Guide

This repository is based on [coleam00/Archon](https://github.com/coleam00/Archon) with additional enhancements:

## 🔐 Secret Vault System (NEW)
- **URL**: https://archon.khamel.com/vault
- **Purpose**: Encrypted password-protected storage for API keys and secrets
- **Features**:
  - Web interface with password protection
  - Programmatic API access
  - Master password unlocks all secrets
  - Perfect for AI assistants

### Files Added:
- `python/src/server/api_routes/vault_api.py` - Vault API endpoints
- `vault/index.html` - Web interface
- `.env` - Added required environment variables

## 🌐 Universal Caddy Solution (NEW)
- **Purpose**: Solve SSL certificate conflicts and domain management complexity
- **Features**:
  - Unlimited domains with automatic SSL
  - Port management system
  - Emergency rollback procedures
  - Zero-downtime deployments

### Files Added:
- `CADDY_INSTRUCTIONS_FOR_AI.md` - Single file for AI assistants
- `UNIVERSAL_CADDY_SOLUTION.md` - Complete implementation guide
- `DOMAIN_PORT_REGISTRY.md` - Domain/port tracking
- `scripts/port-manager.sh` - Automated port management
- `scripts/domain-wizard.sh` - Interactive domain setup
- `create-public-repo.sh` - Package solution for distribution

## 🔄 Fork Maintenance Process

### Syncing with Upstream:
```bash
# Fetch latest changes
git fetch upstream

# Merge upstream main into our fork
git checkout main
git merge upstream/main

# Resolve any conflicts
# (Our additions are modular, so conflicts should be minimal)
```

### Our Modular Additions:
- **Vault system**: Completely separate from Archon core
- **Caddy solution**: Independent of Archon, works anywhere
- **Scripts**: Standalone tools for system management

### Benefits:
- ✅ Keep all our enhancements
- ✅ Get upstream updates easily
- ✅ Modular architecture prevents conflicts
- ✅ Both systems work independently

## 🚀 Deployment Configuration

This fork uses:
- **Production**: Docker Compose (bulletproof deployment)
- **Secret Vault**: Available at `/vault`
- **Domain Management**: Caddy with unlimited domains
- **Database**: Supabase (same as upstream)

## 📋 Environment Variables Required

Our additions require these extra variables:
```bash
# For vault system (automatic creation)
ARCHON_MCP_PORT=8051
ARCHON_AGENTS_PORT=8052

# Original Archon variables (unchanged)
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_service_key
OPENAI_API_KEY=your_openai_key
```

## 🤖 For AI Assistants

When working with this repository, tell Claude Code:
> "Read CADDY_INSTRUCTIONS_FOR_AI.md file and help me manage domains"

For secret management:
> "Use the vault API at https://your-domain.com/api/vault with password X"

This fork maintains full compatibility with upstream while adding powerful new capabilities.