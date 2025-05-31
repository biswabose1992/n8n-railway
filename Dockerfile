FROM n8nio/n8n:latest

ENV N8N_PORT=5678
ENV N8N_HOST="0.0.0.0"
ENV N8N_PROTOCOL="http"
ENV NODE_ENV="production"
# IMPORTANT: Override this in Railway's environment variables with your public Railway URL
ENV WEBHOOK_URL="http://localhost:5678"
# Or your preferred timezone
ENV GENERIC_TIMEZONE="Europe/London"
 # Set default to postgres
ENV DB_TYPE=postgres
# Recommended for managing disk space
ENV EXECUTIONS_DATA_PRUNE=true
# Prune executions older than 14 days (e.g., 14*24 = 336 hours)
ENV EXECUTIONS_DATA_MAX_AGE=336

# No longer need curl in the image if we're not downloading backup
# USER root
# RUN apk update && apk add --no-cache curl
# USER node

EXPOSE 5678
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["n8n"]