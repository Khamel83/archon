# Automated Upstream Sync System

This system keeps your fork up-to-date with coleam00/Archon while preserving all our enhancements.

## 🔄 Sync Methods

### Method 1: Automatic Daily Sync (Recommended)
```bash
# Setup once
./scripts/auto-sync-upstream.sh setup

# This creates a cron job that runs daily at 2 AM
# Automatically syncs if there are upstream changes
# Preserves all our additions
# Creates backups before every sync
# Notifications on success/failure (if webhook configured)
```

### Method 2: Manual Sync On-Demand
```bash
# Manual sync anytime
./scripts/auto-sync-upstream.sh sync
```

### Method 3: Manual Sync with Safety Net
```bash
# This creates backup before attempting sync
./scripts/auto-sync-upstream.sh sync
```

## 🛡️ Safety Features

### Automatic Backups
- Creates backup tag before every sync attempt
- Format: `backup-YYYYMMDD_HHMMSS`
- Preserves exact state before changes
- Easy rollback to any previous state

### Conflict Resolution
- Creates temporary merge branch (never touches main)
- Runs comprehensive tests before merging
- Generates conflict reports if needed
- Preserves main branch integrity

### Test Suite
After every merge, automatically tests:
- ✅ Core Archon files exist
- ✅ Our additions are preserved
- ✅ Configuration files validate
- ✅ Database connectivity

## 🔄 What Gets Synced

**From coleam00/Archon (upstream):**
- Core Archon functionality
- Bug fixes and improvements
- New features and security updates
- Dependency updates

**Preserved from our fork:**
- 🔐 Secret Vault system
- 🌐 Universal Caddy Solution
- 📋 All our management scripts
- 🔧 Configuration customizations

## 📊 Monitoring and Logging

### Logs
- Location: `/home/ubuntu/archon/logs/auto-sync.log`
- Timestamps for all operations
- Success/failure tracking
- Detailed error messages

### Status Checking
```bash
# Check current sync status
./scripts/auto-sync-upstream.sh status

# Shows:
# - Current commit
# - Upstream commit
# - How many commits behind
# - Safety check results
```

### Backups Management
```bash
# List all backup points
./scripts/auto-sync-upstream.sh backups

# Rollback to specific backup
./scripts/auto-sync-upstream.sh rollback backup-20241026_143022
```

## ⏰ Scheduling Options

### Daily Automatic (Recommended)
```bash
# Runs every day at 2 AM server time
# Minimizes disruption
# Preserves working state
# Creates daily backups
```

### Weekly Automated
```bash
# For less frequent updates
# Change cron to weekly instead
# Manual sync available anytime
```

### Event-Driven
```bash
# Manual sync when you want latest features
# Monitor upstream for important releases
# Sync on security announcements
```

## 🚨 Emergency Procedures

### If Sync Fails
1. **Don't panic** - main branch is protected
2. **Check logs**: `tail -f logs/auto-sync.log`
3. **Review conflict report**: `MERGE_CONFLICT_REPORT.md`
4. **Manual resolution**: Fix conflicts in temporary branch
5. **Complete merge**: Tests will verify resolution

### Rollback
```bash
# Always available safety net
./scripts/auto-sync-upstream.sh rollback backup-YYYYMMDD_HHMMSS

# Instant rollback to any previous working state
# Preserves all our additions
```

## 🔔 Notifications (Optional)

### Setup Webhook Notifications
```bash
# Edit the script and set WEBHOOK_URL
# Get notifications for:
# - Successful syncs
# - Failed syncs
# - Conflict situations
# - Rollback operations

# Compatible with:
# - Slack webhooks
# - Discord webhooks
# - Custom endpoints
```

## 📋 Maintenance Checklist

### Weekly
- [ ] Check sync logs for any issues
- [ ] Verify automated syncs are running
- [ ] Test rollback procedure
- [ ] Monitor for conflicts

### Monthly
- [ ] Review backup retention policy
- [ ] Update webhook URLs if needed
- [ ] Test emergency procedures
- [ ] Review sync frequency

## 🔄 Sync Frequency Recommendations

### For Production Systems:
- **Daily sync** at 2 AM (recommended)
- Immediate sync on security updates
- Weekly backup verification

### For Development Systems:
- **Manual sync** before starting development
- **Daily sync** for latest features
- **Feature testing** after sync

### For Testing Systems:
- **Weekly sync** sufficient
- Manual sync for specific features
- Extensive testing before sync

## 🛠️ Advanced Configuration

### Custom Merge Strategy
The script supports these patterns:
- **Safe merge** (default): Creates backup + tests
- **Fast merge**: Skips tests for quick updates
- **Manual review**: Creates PR for review

### Conflict Resolution Rules
1. **Core Archon files**: Upstream takes priority
2. **Our additions**: Preserved over upstream
3. **Configuration files**: Manual review required
4. **New features**: Add to our feature backlog

## 📈 Benefits

### Safety First
- ✅ Never lose working state
- ✅ Automatic backup before changes
- ✅ Comprehensive testing
- ✅ Rollback always available

### Automation
- ✅ No manual intervention needed
- ✅ Configurable timing
- ✅ Error handling and recovery
- ✅ Status monitoring

### Best of Both Worlds
- ✅ Get upstream improvements
- ✅ Keep our enhancements
- ✅ Minimal merge conflicts
- ✅ Modular architecture

## 🎯 Getting Started

1. **Setup automated sync** (one-time):
   ```bash
   ./scripts/auto-sync-upstream.sh setup
   ```

2. **Configure notifications** (optional):
   ```bash
   # Edit scripts/auto-sync-upstream.sh
   # Set WEBHOOK_URL="your-webhook-url"
   ```

3. **Test the system**:
   ```bash
   # Run first sync manually to test
   ./scripts/auto-sync-upstream.sh sync
   ```

4. **Monitor and relax**:
   - Check logs periodically
   - Verify automatic syncs run
   - Enjoy automated updates!

---

**Result**: Your fork stays current with coleam00/Archon while preserving ALL our Secret Vault, Caddy solutions, and custom enhancements - automatically and safely.