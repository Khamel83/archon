#!/bin/bash

# =================================================================
# Archon Automatic Migration Script
# =================================================================
# This script will automatically run the database migration
# for your Supabase database
# =================================================================

echo "🚀 Starting Archon Database Migration..."

# Extract Supabase credentials from .env
SUPABASE_URL=$(grep "SUPABASE_URL=" .env | cut -d '=' -f2)
SUPABASE_SERVICE_KEY=$(grep "SUPABASE_SERVICE_KEY=" .env | cut -d '=' -f2)

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo "❌ Error: SUPABASE_URL or SUPABASE_SERVICE_KEY not found in .env file"
    exit 1
fi

# Extract project ref from URL
PROJECT_REF=$(echo $SUPABASE_URL | sed 's|https://||' | sed 's|\.supabase\.co||')

echo "📊 Project: $PROJECT_REF"
echo "🔗 Connecting to Supabase..."

# Create the migration SQL
MIGRATION_SQL=$(cat <<'EOF'
-- =====================================================
-- Add source_url and source_display_name columns
-- =====================================================

-- Add new columns to archon_sources table
ALTER TABLE archon_sources
ADD COLUMN IF NOT EXISTS source_url TEXT,
ADD COLUMN IF NOT EXISTS source_display_name TEXT;

-- Add indexes for the new columns for better query performance
CREATE INDEX IF NOT EXISTS idx_archon_sources_url ON archon_sources(source_url);
CREATE INDEX IF NOT EXISTS idx_archon_sources_display_name ON archon_sources(source_display_name);

-- Add comments to document the new columns
COMMENT ON COLUMN archon_sources.source_url IS 'The original URL that was crawled to create this source';
COMMENT ON COLUMN archon_sources.source_display_name IS 'Human-readable name for UI display (e.g., "GitHub - microsoft/typescript")';

-- Backfill existing data
UPDATE archon_sources
SET
    source_url = COALESCE(source_url, source_id),
    source_display_name = COALESCE(source_display_name, source_id)
WHERE
    source_url IS NULL
    OR source_display_name IS NULL;

SELECT 'Migration completed successfully!' as status;
EOF
)

# Method 1: Try using psql if available
if command -v psql &> /dev/null; then
    echo "✅ Found psql, attempting direct connection..."

    # Construct connection string
    DB_URL="postgresql://postgres:${SUPABASE_SERVICE_KEY}@db.${PROJECT_REF}.supabase.co:5432/postgres"

    echo "$MIGRATION_SQL" | psql "$DB_URL" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Migration completed successfully via psql!"
        echo "🌐 Your Archon is now available at: http://141.148.146.79:5173"
        exit 0
    fi
fi

# Method 2: Try using curl to Supabase REST API
echo "🔄 Trying Supabase REST API..."

# Create a temporary file with the SQL
echo "$MIGRATION_SQL" > /tmp/migration.sql

# Use curl to execute SQL via Supabase RPC
RESPONSE=$(curl -s -X POST \
    "${SUPABASE_URL}/rest/v1/rpc/execute_sql" \
    -H "apikey: ${SUPABASE_SERVICE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"sql\": $(echo "$MIGRATION_SQL" | jq -Rs .)}" 2>/dev/null)

if [ $? -eq 0 ] && [[ "$RESPONSE" != *"error"* ]]; then
    echo "✅ Migration completed successfully via API!"
    echo "🌐 Your Archon is now available at: http://141.148.146.79:5173"
else
    echo "⚠️  Automatic migration failed. Manual setup required:"
    echo ""
    echo "📋 Please run this SQL manually in your Supabase Dashboard:"
    echo "   1. Go to https://supabase.com/dashboard"
    echo "   2. Select your project ($PROJECT_REF)"
    echo "   3. Go to SQL Editor"
    echo "   4. Copy and paste the SQL below:"
    echo ""
    echo "$MIGRATION_SQL"
    echo ""
    echo "   5. Click Run"
    echo ""
    echo "🌐 After running SQL, access Archon at: http://141.148.146.79:5173"
fi

# Cleanup
rm -f /tmp/migration.sql

echo "🎉 Migration script completed!"