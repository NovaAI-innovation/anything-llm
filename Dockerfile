# AnythingLLM Hugging Face Spaces Deployment
# This dockerfile deploys a complete AnythingLLM instance to Hugging Face Spaces
# with proper permissions and storage configuration.

FROM mintplexlabs/anythingllm:render

# Switch to root to set up directories and permissions
USER root

# Create the data directory structure and set proper ownership
RUN mkdir -p /data/storage && \
    mkdir -p /data/storage/documents && \
    mkdir -p /data/storage/models && \
    mkdir -p /data/storage/vector-cache && \
    mkdir -p /data/storage/assets && \
    chown -R anythingllm:anythingllm /data && \
    chmod -R 755 /data

# Create the storage symlink
RUN ln -sf /data/storage /storage && \
    chown -h anythingllm:anythingllm /storage

# Switch back to anythingllm user
USER anythingllm

# Set environment variables for Hugging Face Spaces
ENV STORAGE_DIR="/data/storage"
ENV SERVER_PORT=7860
ENV NODE_ENV=production

# Use the standard entrypoint
ENTRYPOINT ["/bin/bash", "/usr/local/bin/render-entrypoint.sh"]
