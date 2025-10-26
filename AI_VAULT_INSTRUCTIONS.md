# AI Vault Access Instructions

## 🤖 **For AI Assistants: How to Access the Archon Vault**

### **ONE-LINE INSTRUCTION:**
```
"Access the vault at https://archon.khamel.com/vault with password 'PROVIDED_PASSWORD'"
```

### **FULL EXAMPLE:**
```
User: "I need to deploy this app. Here's my vault access:
       https://archon.khamel.com/vault with password 'mySecretPassword123'"

AI: "I'll access your vault to get the deployment secrets..."
```

### **WHAT THE AI DOES:**
1. **Visit:** `https://archon.khamel.com/vault`
2. **Enter:** The password you provided
3. **Discover:** All available secrets (API keys, URLs, tokens)
4. **Use:** The secrets for the requested task

### **AVAILABLE SECRETS TYPICALLY INCLUDE:**
- `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` (database)
- `OPENROUTER_KEYS` (AI services)
- `GOOGLE_SEARCH_API_KEY` and `GOOGLE_SEARCH_ENGINE_ID`
- `YOUTUBE_API_KEY`, `FIRECRAWL_API_KEY`, `CONTEXT7_API_KEY`
- `TAVILY_API_KEY`, `PERPLEXITY_API_KEY` (search services)
- `GITHUB_PAT`, `ZAI_API_KEY` (development)
- `TELEGRAM_BOT_TOKEN` (notifications)
- Paywall credentials for news sites
- And many more...

### **SECURITY NOTES:**
- ✅ **Safe:** AI can only access with password you provide
- ✅ **Temporary:** Access expires after session
- ✅ **Secure:** Vault encrypted with PBKDF2 + AES256
- ⚠️ **No Storage:** AI should never store passwords long-term

### **FOR DEVELOPERS:**
If you need programmatic access, use the API:
```bash
curl -X POST "https://archon.khamel.com/api/vault/unlock" \
  -H "Content-Type: application/json" \
  -d '{"password": "YOUR_PASSWORD"}'
```

---

**Bottom Line:** Just tell the AI the vault URL and password, and it will handle the rest automatically.