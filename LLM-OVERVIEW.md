# LLM Overview — archon
*Updated: 2026-05-10 07:35 UTC | Tier: standard | Auto-updated: daily cron*

## What This Is
<p align="center"> <img src="./archon-ui-main/public/archon-main-graphic.png" alt="Archon Main Graphic" width="853" height="422">

## Current State
*Status: 🟢 active from local git history*

**Active work:**
- f8563a8 chore: bootstrap LLM-OVERVIEW files 2026-05-10
- 2b6b97d 📖 Update README with OOS integration reference
- 9e2ce52 🧠 Add OOS principles and 'WHY not just HOW' documentation
- cdd3663 📖 Add simple AI vault access instructions to README
- 7624e29 📚 Add AI vault access documentation
- 535fbba ✅ Add vault web interface and security configuration

**Known issues:**
- No known issue found in recent commit subjects or local TODO/BLOCKERS docs.

**Recent changes (7 days):**
- `f8563a8 chore: bootstrap LLM-OVERVIEW files 2026-05-10`

## Architecture
- Stack marker: Docker Compose service
- Stack marker: Makefile-driven operations
- Top-level entry: `AGENTS.md`
- Top-level entry: `AI_VAULT_INSTRUCTIONS.md`
- Top-level entry: `archon-ui-main/`
- Top-level entry: `bin/`
- Top-level entry: `CADDY_INSTRUCTIONS_PUBLIC.md`
- Top-level entry: `check-env.js`
- Top-level entry: `CLAUDE.md`
- Top-level entry: `compositions/`

## Key Commands
- `docker compose up -d  # start compose service from the relevant service directory`
- `git status --short`
- `git log --oneline -5`

## Dependencies
- **Runs on:** Not declared in local repo evidence.
- **Calls out to:** See repo docs and config files.
- **Called by:** Not declared in local repo evidence.
- **Env vars required:** `ARCHON_AGENTS_PORT`, `ARCHON_DOCS_PORT`, `ARCHON_MCP_PORT`, `ARCHON_SERVER_PORT`, `ARCHON_UI_PORT`, `HOST`, `LOGFIRE_TOKEN`, `LOG_LEVEL`, `PROD`, `SUPABASE_SERVICE_KEY`, `SUPABASE_URL`, `VITE_ALLOWED_HOSTS`, `VITE_SHOW_DEVTOOLS`

## Critical Rules
- Preserve repo-local instructions in `AGENTS.md`, `CLAUDE.md`, or README when present.
- Do not infer behavior from the repository name alone; verify against local docs and source.

## Gotchas
- Generated from local evidence only: git history, top-level structure, README/CLAUDE/AGENTS/docs, and env examples.
