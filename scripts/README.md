# Development Scripts

This directory contains utility scripts for development, deployment, and maintenance.

## Scripts

### Development
- `setup-dev.sh` - Set up local development environment
- `start-services.sh` - Start all services locally
- `stop-services.sh` - Stop all services
- `reset-db.sh` - Reset database and run migrations

### Deployment
- `deploy-dev.sh` - Deploy to development environment
- `deploy-staging.sh` - Deploy to staging environment
- `deploy-prod.sh` - Deploy to production environment

### Database
- `migrate.sh` - Run database migrations
- `seed-data.sh` - Seed database with sample data
- `backup-db.sh` - Backup database
- `restore-db.sh` - Restore database from backup

### Utilities
- `lint-all.sh` - Run linting on all components
- `test-all.sh` - Run all tests
- `build-docker.sh` - Build all Docker images
- `push-docker.sh` - Push Docker images to registry

## Usage

All scripts are designed to be run from the project root:

```bash
# Set up development environment
./scripts/setup-dev.sh

# Start all services
./scripts/start-services.sh

# Deploy to staging
./scripts/deploy-staging.sh
```