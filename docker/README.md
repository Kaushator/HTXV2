# Docker Configurations

This directory contains Docker configurations for all services in the HTXV2 project.

## Structure

- `backend.Dockerfile` - FastAPI backend container
- `frontend.Dockerfile` - Next.js frontend container
- `etl.Dockerfile` - ETL jobs container
- `ml.Dockerfile` - ML/LLM services container
- `docker-compose.yml` - Local development environment
- `docker-compose.prod.yml` - Production environment

## Development Environment

To run the complete development environment:

```bash
cd docker
docker compose up -d
```

This will start:
- PostgreSQL database with pgvector
- Redis cache
- Backend API
- Frontend application
- ETL services

## Production Deployment

For production deployment to Google Cloud:

```bash
# Build and push to Artifact Registry
make docker-build-all
make docker-push-all

# Deploy to Cloud Run
make deploy-prod
```

## Environment Variables

Each service requires specific environment variables. See the respective `.env.example` files in each service directory.

## Health Checks

All containers include health checks to ensure services are running properly:
- Backend: `/health` endpoint
- Frontend: HTTP 200 response
- Database: PostgreSQL connection check
- Redis: PING command