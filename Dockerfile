# AnythingLLM Hugging Face Spaces Deployment
# Optimized Dockerfile following Docker and HF Spaces best practices
# Read the docs: https://huggingface.co/docs/hub/spaces-sdks-docker

FROM mintplexlabs/anythingllm:render

# Switch to root to set up user and directories with proper permissions
USER root

# Create non-root user with UID 1000 (HF Spaces requirement)
# Note: anythingllm user should already exist in base image, but ensure UID 1000
RUN if ! id -u anythingllm > /dev/null 2>&1; then \
        useradd -m -u 1000 anythingllm; \
    fi && \
    usermod -u 1000 anythingllm 2>/dev/null || true

# Create the complete directory structure with proper ownership
RUN mkdir -p /data/storage/documents \
             /data/storage/models \
             /data/storage/vector-cache \
             /data/storage/assets \
             /data/storage/logs && \
    chown -R anythingllm:anythingllm /data && \
    chmod -R 755 /data

# Create storage symlink with proper ownership
RUN ln -sf /data/storage /storage && \
    chown -h anythingllm:anythingllm /storage

# Set home directory and PATH for the user
ENV HOME=/home/anythingllm \
    PATH=/home/anythingllm/.local/bin:$PATH

# Set working directory to user's home
WORKDIR $HOME

# Switch to non-root user (HF Spaces security requirement)
USER anythingllm

# Set environment variables for Hugging Face Spaces
ENV STORAGE_DIR="/data/storage" \
    SERVER_PORT=7860 \
    NODE_ENV=production \
    DISABLE_TELEMETRY=true

# Expose the required port for HF Spaces
EXPOSE 7860

# Use the standard entrypoint from the base image
ENTRYPOINT ["/bin/bash", "/usr/local/bin/render-entrypoint.sh"]
