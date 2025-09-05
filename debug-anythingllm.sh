#!/bin/bash

# AnythingLLM Debugging Script for Hugging Face Spaces
# Based on Context7 best practices and common deployment issues
# Usage: ./debug-anythingllm.sh

echo "🔍 AnythingLLM Debug Script - $(date)"
echo "====================================="

# Check if running inside container
if [ -f /.dockerenv ]; then
    echo "✅ Running inside Docker container"
else
    echo "❌ Not running inside Docker container"
fi

echo ""
echo "🏠 Environment Information:"
echo "USER: $USER"
echo "HOME: $HOME"
echo "STORAGE_DIR: $STORAGE_DIR"
echo "SERVER_PORT: $SERVER_PORT"
echo "NODE_ENV: $NODE_ENV"

echo ""
echo "📁 Directory Structure Check:"
ls -la /data/storage/ 2>/dev/null || echo "❌ /data/storage/ not accessible"
ls -la /app/server/ 2>/dev/null || echo "❌ /app/server/ not accessible"
ls -la /app/collector/ 2>/dev/null || echo "❌ /app/collector/ not accessible"

echo ""
echo "🔗 Symlink Check:"
ls -la /storage 2>/dev/null || echo "❌ /storage symlink not found"
ls -la /app/server/storage 2>/dev/null || echo "❌ /app/server/storage symlink not found"

echo ""
echo "💾 Database Check:"
if [ -f "/data/storage/anythingllm.db" ]; then
    echo "✅ Database file exists"
    ls -la /data/storage/anythingllm.db
    sqlite3 /data/storage/anythingllm.db ".tables" 2>/dev/null || echo "⚠️  Database may be corrupted or empty"
else
    echo "❌ Database file missing - creating it now..."
    touch /data/storage/anythingllm.db
    chmod 664 /data/storage/anythingllm.db
fi

echo ""
echo "🔐 Permissions Check:"
echo "Current user: $(whoami)"
echo "Current UID: $(id -u)"
echo "Current GID: $(id -g)"
echo "Storage directory permissions:"
stat -c "%a %n %U:%G" /data/storage/ 2>/dev/null || echo "❌ Cannot check /data/storage/ permissions"

echo ""
echo "🌐 Network Check:"
echo "Checking if port $SERVER_PORT is available..."
netstat -tuln 2>/dev/null | grep ":$SERVER_PORT" || echo "Port $SERVER_PORT is available"

echo ""
echo "🏥 Health Check:"
if command -v curl >/dev/null 2>&1; then
    echo "Testing AnythingLLM health endpoint..."
    curl -f http://localhost:$SERVER_PORT/api/ping 2>/dev/null && echo "✅ Health check passed" || echo "❌ Health check failed"
else
    echo "⚠️  curl not available for health check"
fi

echo ""
echo "📋 Process Check:"
ps aux | grep -E "(node|anythingllm)" | grep -v grep || echo "No AnythingLLM processes found"

echo ""
echo "💿 Disk Space Check:"
df -h /data 2>/dev/null || echo "Cannot check disk space"

echo ""
echo "📝 Recent Logs:"
if [ -f "/data/storage/logs/startup.log" ]; then
    echo "Startup logs (last 10 lines):"
    tail -10 /data/storage/logs/startup.log
else
    echo "No startup logs found"
fi

echo ""
echo "🔧 Suggested Fixes:"
echo "1. If database errors: rm /data/storage/anythingllm.db && touch /data/storage/anythingllm.db"
echo "2. If permission errors: chown -R anythingllm:anythingllm /data"
echo "3. If startup fails: check logs with: docker logs <container-id>"
echo "4. If health check fails: wait 2-3 minutes for full startup"

echo ""
echo "📚 Context7 Documentation References:"
echo "- AnythingLLM Storage: https://github.com/mintplex-labs/anything-llm/blob/master/server/storage/README.md"
echo "- Docker Setup: https://github.com/mintplex-labs/anything-llm/blob/master/docker/HOW_TO_USE_DOCKER.md"
echo "- HF Spaces: https://huggingface.co/docs/hub/spaces-sdks-docker"

echo ""
echo "🔍 Debug Complete - $(date)"
