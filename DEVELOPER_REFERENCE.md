# Complete Development Reference

**🎯 PURPOSE:** This document provides complete access to all development systems while explaining WHY each approach is used, allowing flexibility when implementations change.

**🔄 PRINCIPLE:** When any "how" becomes outdated, understand the "why" and adapt accordingly.

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

**WHY Caddy:** Automatic SSL, reverse proxy, simple config - provides secure web access to all services.

**Core Principle:** All web traffic goes through Caddy for SSL termination and routing.

**Current Setup:**
- Config Location: `/etc/caddy/Caddyfile`
- Service Status: `sudo systemctl status caddy`
- Reload Changes: `sudo systemctl reload caddy`
- Validate Config: `sudo caddy validate --config /etc/caddy/Caddyfile`

**When This Changes:** If web server changes, the principle remains: one entry point for SSL + routing to backend services.

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

**WHY MICROSERVICES:** Each service has single responsibility, independent scaling, clear boundaries.

**Core Principle:** Services communicate via HTTP APIs, no direct imports - true separation of concerns.

**Current Services:**
- Frontend UI: `localhost:3737` (React/Vite) - User interface
- API Server: `localhost:8181` (FastAPI) - Core business logic
- MCP Server: `localhost:8051` (AI integration) - Model Context Protocol
- Agents Service: `localhost:8052` (PydanticAI) - AI/ML operations

**When Architecture Changes:** Maintain separation and HTTP communication patterns regardless of implementation details.

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

**WHY MCP:** Standard protocol for AI assistants to access external tools and knowledge.

**Core Principle:** AI connects via Model Context Protocol - consistent interface across all AI clients.

**Current Setup:**
- MCP Server Access: `http://localhost:8051`
- Available MCP Tools: Knowledge search, project management, document operations
- Supported Models: OpenAI, Google Gemini, Ollama

**When This Changes:** MCP protocol ensures AI integration works even if underlying implementation changes.

## 🔄 **OOS Integration Principles**

**WHY OOS:** Task dependency management, export/import capabilities, CLI automation for development workflows.

**Core OOS Principles (apply even if tools change):**
1. **Validate Before Create:** Always check task validity before creation
2. **Dependency Awareness:** Understand and resolve task dependencies
3. **Circular Prevention:** Detect and prevent circular dependencies
4. **Export/Import:** JSONL format for portable task data
5. **CLI Integration:** Command-line interface for automation

**OOS-Archon Integration:**
- Archon manages documents/knowledge (input for tasks)
- OOS manages task dependencies and execution
- Both systems feed each other: knowledge → tasks → refined knowledge

**When OOS Evolves:** These principles remain - specific commands may change but approach (validation, dependencies, circular prevention) stays the same.

**Current OOS Commands (examples - verify current state):**
- Task creation with dependency validation
- JSONL export/import for backup/portability
- Dependency graph visualization
- CLI automation scripts

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

## 🔍 **Troubleshooting & Debugging Principles**

**WHY SYSTEMATIC DEBUGGING:** Patterns allow quick diagnosis when implementations change.

**Core Debugging Approach:**
1. **Isolate Layer:** Test each service independently (network → app → database)
2. **Check Dependencies:** Verify required services are running before testing
3. **Log Analysis:** Always check logs before code changes
4. **Health Endpoints:** Use `/health` endpoints to verify service status

**Current Common Issues:**
- Port conflicts: `lsof -i :PORT`
- Docker permissions: Add user to docker group
- Caddy issues: `sudo journalctl -u caddy`

**Health Checks (current - adapt as services change):**
- Vault: `curl -I https://archon.khamel.com/vault`
- API: `curl https://archon.khamel.com/api/health`
- Frontend: Check `http://localhost:3737`

**When Tools Change:** Maintain systematic approach: isolate → check dependencies → analyze logs → verify health endpoints.

## 📚 **Documentation Philosophy**

**WHY DOCUMENTED PATTERNS:** When implementations change, understand the pattern's purpose and adapt.

**Core Documentation Principle:** Document the WHY, not just the HOW. The HOW changes, the WHY remains.

**Current Documentation (for current implementation - principles apply when this changes):**
- Architecture: `PRPs/ai_docs/ARCHITECTURE.md` - System design principles
- Data Fetching: `PRPs/ai_docs/DATA_FETCHING_ARCHITECTURE.md` - API patterns
- Query Patterns: `PRPs/ai_docs/QUERY_PATTERNS.md` - Data access patterns
- ETag Implementation: `PRPs/ai_docs/ETAG_IMPLEMENTATION.md` - Caching strategy
- API Naming: `PRPs/ai_docs/API_NAMING_CONVENTIONS.md` - RESTful patterns

**When This Changes:** These documents may become outdated, but the underlying principles (separation of concerns, API patterns, caching strategies) remain valid.

---

## 🎯 **Summary: Complete Development Context**

**This single document provides:**
- ✅ **Secrets Access:** All API keys and credentials
- ✅ **Current Implementation:** Specific commands and configurations
- ✅ **Core Principles:** WHY things are done this way
- ✅ **Adaptation Guidance:** How to work when implementations change
- ✅ **OOS Integration:** How task system connects with knowledge system
- ✅ **Troubleshooting Approach:** Systematic debugging patterns

## 🔄 **OOS Integration - This System's Role**

**WHY ARCHON FOR OOS:** Archon provides the foundational services that OOS requires - knowledge management, RAG, project management, and secure secret access.

**Archon's Role in OOS Ecosystem:**
1. **Knowledge Hub:** All task context and RAG capabilities
2. **Secret Manager:** Secure vault for all credentials and API keys
3. **Project System:** Task management and status tracking
4. **MCP Provider:** AI tool integration for OOS operations
5. **API Gateway:** Standardized interfaces for external systems

**OOS Dependencies on Archon:**
- Vault access for secrets and configuration
- Knowledge API for task context and RAG
- Projects API for task management
- Documents API for information access
- MCP server for AI assistant integration

**When OOS Implements:** Always reference Archon endpoints first before adding external services.

**For AI Assistants:** Use current commands when available, apply principles when things change, and always ask: "What is the purpose of this operation?" to adapt correctly.

**OOS Integration Reference:** See `OOS_INTEGRATION_REFERENCE.md` for complete OOS-Archon dependency documentation.

**Last Updated:** 2025-10-26