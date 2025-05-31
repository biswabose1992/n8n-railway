FROM n8nio/n8n:latest

ENV N8N_PORT=5678
ENV N8N_HOST="0.0.0.0"
ENV N8N_PROTOCOL="http"
ENV NODE_ENV="production"
# IMPORTANT: Override this in Railway's environment variables with your public Railway URL
ENV WEBHOOK_URL="http://localhost:5678" 
# Or your preferred timezone
ENV GENERIC_TIMEZONE="Europe/London" 
ENV DB_SQLITE_VACUUM_ON_STARTUP=true
# Recommended for managing disk space
ENV EXECUTIONS_DATA_PRUNE=true 
# Prune executions older than 14 days (e.g., 14*24 = 336 hours)
ENV EXECUTIONS_DATA_MAX_AGE=336 

ARG BACKUP_URL=https://github.com/biswabose1992/n8n-railway/releases/download/0.0.1/n8n_backup.tar.gz

# Switch to root for installing curl and ensuring correct directory permissions
USER root
RUN apk update && apk add --no-cache curl

# Ensure the target directory for the backup exists and parent is owned by node
# The base n8nio/n8n image should have /home/node owned by node.
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

# Download the backup file using curl
RUN echo "Attempting to download backup from URL: ${BACKUP_URL}" && \
    if curl -SLf --retry 3 --retry-delay 5 -o /home/node/.n8n/n8n_backup.tar.gz "${BACKUP_URL}"; then \
        echo "SUCCESS: Backup file downloaded to /home/node/.n8n/n8n_backup.tar.gz" && \
        chown node:node /home/node/.n8n/n8n_backup.tar.gz; \
    else \
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" && \
        echo "ERROR: FAILED TO DOWNLOAD BACKUP FILE from ${BACKUP_URL}." && \
        echo "The backup file will be missing during the restore attempt." && \
        echo "Please check the BACKUP_URL and network access in the build environment." && \
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" && \
        # If you want the build to FAIL if the download fails, uncomment the next line:
        # exit 1; \
        echo "WARNING: n8n_backup.tar.gz download failed. Proceeding without it."; \
    fi

# Verify file presence and permissions after download attempt (still as root)
RUN echo "Verifying contents of /home/node/.n8n/ after download attempt (running as root):" && ls -lha /home/node/.n8n/

# Copy custom entrypoint script and make it executable (still as root)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to node user for running n8n
USER node

# Set working directory (optional, as n8n usually finds its data in /home/node/.n8n)
WORKDIR /home/node

EXPOSE 5678
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["n8n"]