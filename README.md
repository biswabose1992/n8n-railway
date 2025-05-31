# n8n Railway Deployment

This repository contains the configuration files needed to deploy n8n with PostgreSQL on Railway.app.

## What's Included

- **docker-compose.yml**: Docker Compose configuration for local development
- **backup.sh**: Script to backup n8n data and PostgreSQL database
- **.env.example**: Template for environment variables

## Local Development

1. Clone this repository
2. Copy `.env.example` to `.env` and fill in your values
3. Run with Docker Compose:
   ```bash
   docker-compose up -d
   ```
4. Access n8n at `http://localhost:5678`

## Environment Variables

Create a `.env` file with these variables:

- `N8N_BASIC_AUTH_USER`: Username for n8n basic auth
- `N8N_BASIC_AUTH_PASSWORD`: Password for n8n basic auth
- `N8N_GOOGLE_OAUTH_CLIENT_ID`: Google OAuth client ID
- `N8N_GOOGLE_OAUTH_CLIENT_SECRET`: Google OAuth client secret
- `POSTGRES_PASSWORD`: PostgreSQL database password
- `GOOGLE_GEMINI_API_KEY`: Gemini API key for AI integrations

## Backup & Restore

### Create Backup
```bash
./backup.sh
```

### Restore from Backup
```bash
# Restore n8n data
docker run --rm -v n8n_n8n_data:/data -v $(pwd)/backups/[timestamp]:/backup alpine tar xzf /backup/n8n_data.tar.gz -C /

# Restore database
docker-compose exec -T postgres psql -U n8n -d n8n < backups/[timestamp]/n8n_database.sql
```

## Railway Deployment

1. Connect this repository to Railway
2. Set environment variables in Railway dashboard
3. Deploy using the Railway PostgreSQL addon

## Architecture

- **n8n**: Workflow automation platform
- **PostgreSQL**: Database for storing n8n data
- **Docker**: Containerization for consistent deployments

## Security Notes

- Never commit `.env` file to version control
- Use strong passwords for all credentials
- Keep API keys secure and rotate them regularly
