# OOS Integration Reference - Archon Dependencies

## 🎯 **PURPOSE: OOS REQUIRES ARCHON**

**Core Principle:** OOS is the task/dependency management system that REQUIRES Archon for knowledge, RAG, and project management capabilities.

## 🔐 **REQUIRED: Archon Vault Access**

**WHY REQUIRED:** OOS needs access to your secrets and service configurations to function properly.

**Single Command for AI Assistants:**
```
"Access vault at https://archon.khamel.com/vault with password 'YOUR_PASSWORD'

For complete development reference: https://raw.githubusercontent.com/Khamel83/archon/main/DEVELOPER_REFERENCE.md"
```

**What OOS Gets from Archon Vault:**
- Database credentials for task storage
- API keys for external integrations
- Service configurations for task automation

## 🚀 **REQUIRED: Archon Knowledge System**

**WHY REQUIRED:** OOS tasks need knowledge context, RAG capabilities, and project management that only Archon provides.

**Archon Endpoints OOS Uses:**
- **Knowledge API:** `/api/knowledge/search` - RAG search for task context
- **Projects API:** `/api/projects` - Project management integration
- **Documents API:** `/api/documents` - Document management for tasks
- **MCP Server:** `:8051` - AI tool integration

## 🤖 **OOS-Archon Integration Pattern**

### **Task Creation with Knowledge:**
1. **OOS:** Receives task request
2. **OOS → Archon:** Query knowledge base for context
3. **OOS:** Creates task with enriched context
4. **OOS → Archon:** Stores task in project system

### **Task Execution:**
1. **OOS:** Manages dependencies and execution order
2. **OOS → Archon:** Updates task status in project system
3. **Archon:** Provides real-time progress via web interface
4. **OOS:** Handles task automation and dependencies

### **Knowledge Enrichment:**
1. **Archon:** Processes documents, websites, code
2. **Archon → OOS:** Provides knowledge for task creation
3. **OOS:** Uses knowledge to create better, context-aware tasks

## 🔄 **Update Strategy**

**When Archon Updates:**
- New APIs → OOS can immediately use them
- New knowledge sources → Available for task context
- New project features → Enhanced task management
- Updated vault → OOS gets latest secrets

**OOS Implementation Guidance:**
- Always check Archon API availability before task operations
- Use Archon MCP tools for AI assistant integration
- Store task metadata in Archon project system
- Query Archon knowledge base for task context

## 📋 **Required Archon References**

**OOS Should Always Reference:**
1. **VAULT:** `https://archon.khamel.com/vault` - Secret management
2. **DEVELOPER_REFERENCE:** `https://raw.githubusercontent.com/Khamel83/archon/main/DEVELOPER_REFERENCE.md` - Complete context
3. **API_HEALTH:** `https://archon.khamel.com/api/health` - Service availability
4. **MCP_SERVER:** `http://localhost:8051` - AI tool integration

## 🎯 **For OOS Implementation**

**Minimum Requirements for OOS:**
1. **Vault Access:** Must authenticate to get secrets
2. **API Integration:** Must connect to Archon endpoints
3. **Knowledge Queries:** Must use Archon for RAG/search
4. **Project Sync:** Must store tasks in Archon project system

**Integration Checklist:**
- [ ] Can access vault with provided password
- [ ] Can query knowledge base via Archon API
- [ ] Can create/manage tasks in Archon projects
- [ ] Can use Archon MCP tools for AI integration
- [ ] Handles Archon service downtime gracefully

## 🔗 **External Dependencies**

**Beyond Archon (if needed):**
- Additional documentation or service-specific references
- External APIs that Archon doesn't provide
- System-specific configuration guides

**Rule:** Always check Archon capabilities first before adding external dependencies.

---

**🎯 SUMMARY: OOS is useless without Archon. Archon provides the knowledge, secrets, and project management that OOS requires to function.**

**Last Updated:** 2025-10-26

**Dependencies:**
- REQUIRED: Archon Vault (`https://archon.khamel.com/vault`)
- REQUIRED: Archon APIs (knowledge, projects, documents)
- REQUIRED: Archon Development Reference