#!/bin/bash

# Bulletproof Archon Deployment Script
# This ensures Archon is always running and recovers from failures

set -e

ARCHON_CONTAINER="archon-backend"
LOG_FILE="/var/log/archon-deploy.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_prerequisites() {
    log_message "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_message "ERROR: Docker not installed"
        exit 1
    fi

    # Check DNS resolution
    if ! nslookup kndpikghdwaktsknapfe.supabase.co >/dev/null 2>&1; then
        log_message "ERROR: DNS resolution failing"
        exit 1
    fi

    log_message "Prerequisites check passed"
}

build_image() {
    log_message "Building Archon Docker image..."
    cd /home/ubuntu/archon
    docker build -t archon-server -f python/Dockerfile.server python/
}

stop_existing() {
    log_message "Stopping existing container..."
    docker stop "$ARCHON_CONTAINER" 2>/dev/null || true
    docker rm "$ARCHON_CONTAINER" 2>/dev/null || true
}

start_container() {
    log_message "Starting Archon container..."
    docker run -d --name "$ARCHON_CONTAINER" \
        --restart unless-stopped \
        -p 8181:8181 \
        -e SUPABASE_URL=https://kndpikghdwaktsknapfe.supabase.co \
        -e SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZHBpa2doZHdha3Rza25hcGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjM5ODA3MCwiZXhwIjoyMDcxOTc0MDcwfQ.VSHtOAYDLG7lwvR5si6WDdgacrGOWJX2hyLEjmFllFE \
        -e OPENAI_API_BASE_URL=https://openrouter.ai/api/v1 \
        -e OPENAI_API_KEY=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 \
        -e ARCHON_SERVER_PORT=8181 \
        -e ARCHON_MCP_PORT=8051 \
        -e ARCHON_AGENTS_PORT=8052 \
        -e LOG_LEVEL=INFO \
        archon-server
}

health_check() {
    local max_attempts=30
    local attempt=1

    log_message "Starting health checks..."

    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep -q "$ARCHON_CONTAINER"; then
            local health=$(curl -s --max-time 10 http://localhost:8181/health 2>/dev/null || echo "unhealthy")

            if [[ "$health" == *"healthy"* ]] || [[ "$health" == *"ready"*true* ]]; then
                log_message "✅ Archon backend is healthy (attempt $attempt/$max_attempts)"
                return 0
            fi
        else
            log_message "Container not running, restarting..."
            start_container
            sleep 5
        fi

        log_message "Health check attempt $attempt/$max_attempts failed, retrying in 10s..."
        sleep 10
        ((attempt++))
    done

    log_message "❌ Health checks failed after $max_attempts attempts"
    return 1
}

main() {
    log_message "=== Archon Deployment Script Started ==="

    check_prerequisites
    build_image
    stop_existing
    start_container

    if health_check; then
        log_message "🎉 Archon deployment successful and healthy"

        # Keep monitoring
        while true; do
            sleep 60  # Check every minute

            # Quick health check
            if docker ps | grep -q "$ARCHON_CONTAINER"; then
                local health=$(curl -s --max-time 5 http://localhost:8181/health 2>/dev/null || echo "unhealthy")

                if [[ "$health" != *"healthy"* ]] && [[ "$health" != *"ready"*true* ]]; then
                    log_message "⚠️  Health check failed, attempting recovery..."
                    stop_existing
                    start_container
                fi
            else
                log_message "⚠️  Container disappeared, restarting..."
                start_container
            fi
        done
    else
        log_message "❌ Initial deployment failed"
        exit 1
    fi
}

# Run main function
main "$@"