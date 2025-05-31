#!/bin/bash

# Create backup directory with timestamp
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating n8n backup in $BACKUP_DIR..."

# Backup n8n data volume
echo "Backing up n8n data..."
docker run --rm -v n8n_n8n_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine sh -c "cd /data && tar czf /backup/n8n_data.tar.gz ."

# Backup PostgreSQL database
echo "Backing up PostgreSQL database..."
docker-compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/n8n_database.sql"

# Copy docker-compose and env files
echo "Backing up configuration files..."
cp docker-compose.yml "$BACKUP_DIR/"
cp .env "$BACKUP_DIR/"

echo "Backup completed in $BACKUP_DIR"
echo "Files created:"
ls -la "$BACKUP_DIR"