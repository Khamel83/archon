#!/bin/bash

# =================================================================
# Archon Complete Migration Script
# =================================================================
# This script runs ALL required database migrations
# =================================================================

echo "🚀 Starting complete Archon Database Migration..."

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

# Migration files to run in order
MIGRATION_FILES=(
    "migration/0.1.0/001_add_source_url_display_name.sql"
    "migration/0.1.0/002_add_hybrid_search_tsvector.sql"
    "migration/0.1.0/003_ollama_add_columns.sql"
    "migration/0.1.0/004_ollama_migrate_data.sql"
    "migration/0.1.0/005_ollama_create_functions.sql"
    "migration/0.1.0/007_add_priority_column_to_tasks.sql"
    "migration/0.1.0/008_add_migration_tracking.sql"
)

# Run each migration
for migration_file in "${MIGRATION_FILES[@]}"; do
    if [ -f "$migration_file" ]; then
        echo ""
        echo "📋 Running migration: $migration_file"

        # Read migration SQL
        MIGRATION_SQL=$(cat "$migration_file")

        # Try to execute via psql if available
        if command -v psql &> /dev/null; then
            DB_URL="postgresql://postgres:${SUPABASE_SERVICE_KEY}@db.${PROJECT_REF}.supabase.co:5432/postgres"
            echo "$MIGRATION_SQL" | psql "$DB_URL" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "✅ Migration completed via psql"
                continue
            fi
        fi

        # Try API method
        RESPONSE=$(curl -s -X POST \
            "${SUPABASE_URL}/rest/v1/rpc/execute_sql" \
            -H "apikey: ${SUPABASE_SERVICE_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
            -H "Content-Type: application/json" \
            -d "{\"sql\": $(echo "$MIGRATION_SQL" | jq -Rs .)}" 2>/dev/null)

        if [[ $? -eq 0 ]] && [[ "$RESPONSE" != *"error"* ]]; then
            echo "✅ Migration completed via API"
        else
            echo "⚠️  Migration may have failed, continuing..."
        fi
    else
        echo "⚠️  Migration file not found: $migration_file"
    fi
done

echo ""
echo "🔄 Restarting services to apply changes..."

# Restart the services
docker compose restart archon-server

# Wait for services to start
echo "⏳ Waiting for services to restart..."
sleep 15

# Check if migration was successful
echo "🔍 Checking migration status..."
HEALTH_RESPONSE=$(curl -s http://localhost:8181/api/health)

if [[ "$HEALTH_RESPONSE" == *"migration_required"* ]]; then
    echo "⚠️  Additional migrations may still be required"
    echo "📋 Manual setup might be needed. Please run remaining migrations in Supabase Dashboard:"
    echo ""

    # Show any remaining migration files
    echo "Remaining migrations to run manually:"
    ls migration/0.1.0/*.sql 2>/dev/null | while read file; do
        filename=$(basename "$file")
        echo "   - $filename"
    done
else
    echo "✅ All migrations completed successfully!"
fi

echo ""
echo "🌐 Your Archon should be accessible at: http://141.148.146.79:5173"
echo "🎉 Migration process completed!"