# AnythingLLM Hugging Face Spaces Deployment
# Optimized Dockerfile with Context7 best practices and comprehensive error fixes
# Read the docs: https://huggingface.co/docs/hub/spaces-sdks-docker

FROM mintplexlabs/anythingllm:render

# Switch to root for setup and debugging
USER root

# Install debugging tools and fix common issues
RUN apt-get update && apt-get install -y \
    curl \
    htop \
    procps \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with UID 1000 (HF Spaces requirement)
# Handle existing user gracefully
RUN if ! id -u anythingllm > /dev/null 2>&1; then \
        useradd -m -u 1000 anythingllm; \
    fi && \
    usermod -u 1000 anythingllm 2>/dev/null || true && \
    usermod -d /home/anythingllm anythingllm 2>/dev/null || true

# Create comprehensive directory structure with proper ownership
# Based on Context7 AnythingLLM documentation
RUN mkdir -p /data/storage/documents \
             /data/storage/models \
             /data/storage/vector-cache \
             /data/storage/assets \
             /data/storage/logs \
             /data/storage/lancedb \
             /app/server/storage \
             /app/collector \
             /home/anythingllm && \
    touch /data/storage/anythingllm.db && \
    chown -R anythingllm:anythingllm /data /app/server /app/collector /home/anythingllm && \
    chmod -R 755 /data && \
    chmod 664 /data/storage/anythingllm.db

# Create storage symlinks with proper ownership (Context7 fix)
RUN ln -sf /data/storage /app/server/storage && \
    ln -sf /data/storage /storage && \
    chown -h anythingllm:anythingllm /app/server/storage /storage

# Set proper environment variables for user
ENV HOME=/home/anythingllm \
    PATH=/home/anythingllm/.local/bin:$PATH \
    USER=anythingllm

# Set working directory to user's home
WORKDIR $HOME

# Switch to non-root user (HF Spaces security requirement)
USER anythingllm

# Comprehensive environment variables for AnythingLLM
ENV STORAGE_DIR="/data/storage" \
    SERVER_PORT=7860 \
    NODE_ENV=production \
    DISABLE_TELEMETRY=true \
    JWT_SECRET="huggingface-spaces-anythingllm-default-secret-key-change-in-production" \
    LLM_PROVIDER="" \
    EMBEDDING_ENGINE="" \
    VECTOR_DB="lancedb" \
    WHISPER_PROVIDER="local" \
    TTS_PROVIDER="native" \
    PASSWORDMINCHAR=8

# Add health check for debugging
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/api/ping || exit 1

# Expose the required port for HF Spaces
EXPOSE 7860

# Create startup script with error handling and logging
RUN echo '#!/bin/bash' > /tmp/startup.sh && \
    echo 'set -e' >> /tmp/startup.sh && \
    echo 'echo "=== AnythingLLM Startup $(date) ===" | tee -a /data/storage/logs/startup.log' >> /tmp/startup.sh && \
    echo 'echo "Checking permissions..." | tee -a /data/storage/logs/startup.log' >> /tmp/startup.sh && \
    echo 'ls -la /data/storage/ | tee -a /data/storage/logs/startup.log' >> /tmp/startup.sh && \
    echo 'echo "Checking database..." | tee -a /data/storage/logs/startup.log' >> /tmp/startup.sh && \
    echo 'if [ ! -f /data/storage/anythingllm.db ]; then' >> /tmp/startup.sh && \
    echo '  echo "Creating database file..." | tee -a /data/storage/logs/startup.log' >> /tmp/startup.sh && \
    echo '  touch /data/storage/anythingllm.db' >> /tmp/startup.sh && \
    echo 'fi' >> /tmp/startup.sh && \
    echo 'echo "Starting AnythingLLM..." | tee -a /data/storage/logs/startup.log' >> /tmp/startup.sh && \
    echo 'exec /bin/bash /usr/local/bin/render-entrypoint.sh' >> /tmp/startup.sh && \
    chmod +x /tmp/startup.sh

# Use the enhanced startup script
ENTRYPOINT ["/bin/bash", "/tmp/startup.sh"]
