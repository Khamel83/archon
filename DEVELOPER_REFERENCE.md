# Complete Development Reference

## 🔐 **Vault Access (Secrets & API Keys)**

**Web Interface:** https://archon.khamel.com/vault
**One Command:** `./LOGIN.sh "your-password-here"`

**Available Secrets Include:**
- SUPABASE_URL, SUPABASE_SERVICE_KEY (database)
- OPENROUTER_KEYS (AI services)
- GOOGLE_SEARCH_API_KEY, GOOGLE_SEARCH_ENGINE_ID
- YOUTUBE_API_KEY, FIRECRAWL_API_KEY, CONTEXT7_API_KEY
- TAVILY_API_KEY, PERPLEXITY_API_KEY (search)
- GITHUB_PAT, ZAI_API_KEY (development)
- TELEGRAM_BOT_TOKEN (notifications)
- All paywall credentials and service tokens

## 🌐 **Caddy/Web Server Management**

**Caddy Configuration Location:** `/etc/caddy/Caddyfile`
**Service Status:** `sudo systemctl status caddy`
**Reload Changes:** `sudo systemctl reload caddy`
**Validate Config:** `sudo caddy validate --config /etc/caddy/Caddyfile`

**Current Archon Domains:**
- `dada.khamel.com` → `localhost:8000` (Priority #1)
- `archon.khamel.com` → `/home/ubuntu/archon/archon-ui-main/dist` (main app)

**Common Caddy Patterns:**
```caddy
# Static website
domain.com {
    root * /path/to/files
    file_server
    encode gzip
}

# API backend
api.domain.com {
    reverse_proxy localhost:8080
    encode gzip
}

# Mixed (API + Static)
app.domain.com {
    handle /api/* {
        reverse_proxy localhost:8080
    }
    handle /* {
        root * /path/to/app
        file_server
        try_files {path} /index.html
    }
    encode gzip
}
```

**Domain Management:**
1. Backup: `sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)`
2. Add domain block to Caddyfile
3. Validate: `sudo caddy validate --config /etc/caddy/Caddyfile`
4. Reload: `sudo systemctl reload caddy`

## 🚀 **Archon Project Structure**

**Services & Ports:**
- Frontend UI: `localhost:3737` (React/Vite)
- API Server: `localhost:8181` (FastAPI)
- MCP Server: `localhost:8051` (AI integration)
- Agents Service: `localhost:8052` (PydanticAI)

**Development Commands:**
```bash
# Start all services
docker compose up --build -d

# Hybrid development (recommended)
make dev  # Backend in Docker, frontend local

# Stop all services
make stop

# Run tests
make test

# Run linters
make lint
```

**Key Directories:**
- Frontend: `archon-ui-main/` (React app)
- Backend: `python/src/server/` (FastAPI services)
- MCP Tools: `python/src/mcp_server/features/`
- Database: Supabase (PostgreSQL + pgvector)

## 🔧 **Database Management**

**Supabase Setup:**
- Local: `http://host.docker.internal:8000`
- Cloud: Your Supabase project URL
- Migration file: `migration/complete_setup.sql`

**Key Tables:**
- `sources` - Crawled websites and documents
- `documents` - Processed chunks with embeddings
- `archon_projects` - Project management
- `archon_tasks` - Task tracking
- `code_examples` - Extracted code snippets

## 🤖 **AI Integration**

**MCP Server Access:** `http://localhost:8051`
**Available MCP Tools:**
- Knowledge base search and retrieval
- Project and task management
- Document operations
- Version control

**AI Models Supported:**
- OpenAI (default)
- Google Gemini
- Ollama (local)

## 📁 **File Management**

**Git Workflow:**
```bash
git add .
git commit -m "description"
git push origin main
```

**Docker Operations:**
```bash
# View logs
docker compose logs -f archon-server

# Rebuild services
docker compose up -d --build

# Clean up
docker compose down -v
```

## 🔍 **Troubleshooting**

**Common Issues:**
- Port conflicts: Check with `lsof -i :PORT`
- Docker permissions: Add user to docker group
- Caddy issues: Check logs with `sudo journalctl -u caddy`

**Health Checks:**
- Vault: `curl -I https://archon.khamel.com/vault`
- API: `curl https://archon.khamel.com/api/health`
- Frontend: Check `http://localhost:3737`

## 📚 **Documentation Links**

- Architecture: `PRPs/ai_docs/ARCHITECTURE.md`
- Data Fetching: `PRPs/ai_docs/DATA_FETCHING_ARCHITECTURE.md`
- Query Patterns: `PRPs/ai_docs/QUERY_PATTERNS.md`
- ETag Implementation: `PRPs/ai_docs/ETAG_IMPLEMENTATION.md`
- API Naming: `PRPs/ai_docs/API_NAMING_CONVENTIONS.md`

---

**🎯 This single document provides everything needed for development, deployment, and maintenance of the Archon system.**

**Last Updated:** 2025-10-26