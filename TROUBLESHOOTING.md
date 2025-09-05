# AnythingLLM Troubleshooting Guide
*Based on Context7 best practices and common deployment issues*

## 🚨 Common Deployment Errors & Solutions

### 1. **Permission Denied Errors**
```
cp: cannot create directory '/data/storage/assets': Permission denied
mkdir: cannot create directory '/data/storage/documents': Permission denied
```

**Root Cause**: Container user doesn't have write permissions to storage directories.

**Context7 Solution**:
```bash
# Inside container (as root):
docker container exec -u 0 -t <CONTAINER_ID> chown -R anythingllm:anythingllm /data
docker container exec -u 0 -t <CONTAINER_ID> chmod -R 755 /data
```

**Prevention**: Our Dockerfile now pre-creates all directories with proper ownership.

---

### 2. **Database Errors**
```
Error: Schema engine error:
SQLite database error
unable to open database file: /storage/anythingllm.db
```

**Root Cause**: Missing or corrupted SQLite database file.

**Context7 Solution**:
```bash
# Create database file with proper permissions
docker container exec -u 0 -t <CONTAINER_ID> touch /data/storage/anythingllm.db
docker container exec -u 0 -t <CONTAINER_ID> chmod 664 /data/storage/anythingllm.db
docker container exec -u 0 -t <CONTAINER_ID> chown anythingllm:anythingllm /data/storage/anythingllm.db
```

**Prevention**: Our Dockerfile now pre-creates the database file.

---

### 3. **Prisma Migration Failures**
```
Environment variables loaded from .env
Prisma schema loaded from prisma/schema.prisma
✔ Generated Prisma Client (v5.3.1) to ./node_modules/@prisma/client in 431ms
```

**Root Cause**: Database schema not properly initialized.

**Context7 Solution**:
```bash
# Run Prisma migrations manually
cd server && npx prisma generate --schema=./prisma/schema.prisma
cd server && npx prisma migrate deploy --schema=./prisma/schema.prisma
```

**Prevention**: Our startup script now includes proper error handling.

---

### 4. **Port Binding Issues**
```
Error: listen EADDRINUSE: address already in use :::7860
```

**Root Cause**: Port 7860 is already in use or not properly exposed.

**Context7 Solution**:
- Check Hugging Face Spaces settings for correct `app_port: 7860`
- Verify `EXPOSE 7860` in Dockerfile
- Ensure `SERVER_PORT=7860` environment variable

---

### 5. **User ID Conflicts**
```
useradd: UID 1000 is not unique
```

**Root Cause**: User with UID 1000 already exists but with different name.

**Context7 Solution**: Our Dockerfile now handles this gracefully:
```dockerfile
RUN if ! id -u anythingllm > /dev/null 2>&1; then \
        useradd -m -u 1000 anythingllm; \
    fi && \
    usermod -u 1000 anythingllm 2>/dev/null || true
```

---

## 🔧 Debugging Tools

### View Container Logs
```bash
# Real-time logs
docker logs -f <container-id>

# Last 100 lines
docker logs --tail 100 <container-id>

# Logs with timestamps
docker logs -t <container-id>
```

### Execute Debug Commands
```bash
# Get shell access
docker exec -it <container-id> /bin/bash

# Check permissions
docker exec -it <container-id> ls -la /data/storage/

# Check processes
docker exec -it <container-id> ps aux

# Check database
docker exec -it <container-id> sqlite3 /data/storage/anythingllm.db ".tables"
```

### Use Our Debug Script
```bash
# Inside container
./debug-anythingllm.sh

# Or from host
docker exec -it <container-id> ./debug-anythingllm.sh
```

---

## 🏥 Health Checks

### Manual Health Check
```bash
curl -f http://localhost:7860/api/ping
```

### Check Service Status
```bash
# Check if AnythingLLM is responding
curl -I http://localhost:7860/

# Check specific endpoints
curl http://localhost:7860/api/v1/system/system-vectors
```

---

## 📋 Environment Variables Checklist

Ensure these are properly set in your Hugging Face Space:

```env
STORAGE_DIR="/data/storage"
SERVER_PORT=7860
NODE_ENV=production
DISABLE_TELEMETRY=true
JWT_SECRET="your-secure-secret-key"
VECTOR_DB="lancedb"
```

---

## 🔍 Log Analysis

### Startup Success Indicators
Look for these in logs:
```
✔ Generated Prisma Client
✔ Database migration completed
Server listening on port 7860
AnythingLLM is ready!
```

### Common Error Patterns
```bash
# Permission issues
grep -i "permission denied" logs

# Database issues
grep -i "sqlite\|database\|prisma" logs

# Port issues
grep -i "EADDRINUSE\|port.*already" logs

# Memory issues
grep -i "out of memory\|killed" logs
```

---

## 🚀 Performance Optimization

### Memory Usage
```bash
# Check memory usage
docker stats <container-id>

# Inside container
free -h
```

### Disk Space
```bash
# Check disk usage
df -h /data

# Clean up if needed
docker system prune -f
```

---

## 📚 Context7 References

Based on official documentation from:

1. **AnythingLLM Storage Issues**: [Storage README](https://github.com/mintplex-labs/anything-llm/blob/master/server/storage/README.md)
2. **Docker Deployment**: [Docker Guide](https://github.com/mintplex-labs/anything-llm/blob/master/docker/HOW_TO_USE_DOCKER.md)
3. **Database Setup**: [Prisma Documentation](https://github.com/mintplex-labs/anything-llm/blob/master/server/utils/prisma/PRISMA.md)
4. **Hugging Face Spaces**: [Docker Spaces Guide](https://huggingface.co/docs/hub/spaces-sdks-docker)

---

## 🆘 Emergency Recovery

### Complete Reset
```bash
# Stop container
docker stop <container-id>

# Remove old data (WARNING: This deletes all data!)
docker exec -u 0 -it <container-id> rm -rf /data/storage/*

# Recreate structure
docker exec -u 0 -it <container-id> mkdir -p /data/storage/{documents,models,vector-cache,assets,logs}
docker exec -u 0 -it <container-id> touch /data/storage/anythingllm.db
docker exec -u 0 -it <container-id> chown -R anythingllm:anythingllm /data

# Restart container
docker start <container-id>
```

### Backup Before Changes
```bash
# Create backup
docker exec -it <container-id> tar -czf /tmp/anythingllm-backup.tar.gz /data/storage/

# Copy backup out
docker cp <container-id>:/tmp/anythingllm-backup.tar.gz ./
```

---

## ✅ Success Checklist

- [ ] Container starts without errors
- [ ] Health check endpoint responds (http://localhost:7860/api/ping)
- [ ] Database file exists with proper permissions
- [ ] All storage directories created
- [ ] No permission denied errors in logs
- [ ] Prisma migrations completed successfully
- [ ] Server listening on port 7860
- [ ] Web interface accessible

---

*This guide is continuously updated based on Context7 research and community feedback.*
