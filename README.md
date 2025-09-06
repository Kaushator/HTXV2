# HTXV2 - Cryptocurrency Trading Platform

A comprehensive GCP-based cryptocurrency trading platform with ML/AI capabilities.

## Architecture Overview

```
[Frontend (Next.js/React, shadcn)]
          |        REST/WS
          v
[Backend API (FastAPI)]  —— gRPC/HTTP ———————————————————————————————─┐
          | SQLAlchemy                |                                  |
          |                           |                                  |
          v                           v                                  v
  [Cloud SQL for PostgreSQL]   [Memorystore (Redis)]           [Artifact Registry]
          |                           |                                  |
          | ETL writes/reads          | caching / queues                 | images for API/ETL/LLM
          v                           v                                  v
 [Feature Store (Postgres/pgvector)]  [Pub/Sub] <——— Cloud Scheduler ————┐
          ^            ^                 ^                                |
          |            |                 | triggers                       |
          |            |           Dataflow jobs / Cloud Run Jobs         |
          |            |                                                  |
          |            └——— Embeddings ————> [Vertex AI Matching Engine] |
          |                                                               |
          |                ┌──────────── Batch/Stream ingestion ───────────────┐
          |                |                                                   |
          v                v                                                   v
 [GCS (raw landing)] -> [Dataflow | Cloud Run Jobs] -> [BigQuery (curated/dwh)] ---> [Looker/BI]
```

## Components

- **Frontend**: Next.js 14 with React, TypeScript, and shadcn/ui
- **Backend**: FastAPI with SQLAlchemy, Alembic migrations
- **Infrastructure**: Terraform for GCP resource management
- **Database**: Cloud SQL PostgreSQL with pgvector extension
- **Caching**: Memorystore Redis
- **Storage**: Google Cloud Storage for data lake
- **Data Warehouse**: BigQuery with vector search
- **ML/AI**: Vertex AI + local FinGPT with LoRA adapters
- **Container Registry**: Artifact Registry
- **Security**: Secret Manager, Workload Identity Federation
- **Monitoring**: Cloud Logging, Error Reporting, Cloud Monitoring

## Getting Started

### Prerequisites

- Node.js 18+
- Python 3.11+
- Docker
- Terraform
- Google Cloud SDK
- Git

### Local Development

1. Clone the repository
2. Set up environment variables
3. Run backend: `make dev-backend`
4. Run frontend: `make dev-frontend`
5. Run infrastructure: `make tf-plan`

## Project Structure

```
├── frontend/           # Next.js React application
├── backend/           # FastAPI application
├── infrastructure/    # Terraform configurations
├── ml/               # ML/LLM components and models
├── etl/              # Data processing pipelines
├── docker/           # Docker configurations
├── scripts/          # Utility scripts
├── docs/             # Documentation
└── .github/          # GitHub Actions workflows
```

## Data Sources

- **HTX (Huobi)**: Cryptocurrency exchange data
- **Coingecko**: Market data and cryptocurrency information
- **Cryptopanic**: News and sentiment data
- **User uploads**: CSV/XLSX files via signed URLs

## ML/LLM Stack

- **Local FinGPT**: LoRA-adapted model running in Docker (RTX 4060)
- **Vertex AI**: Cloud-based models (Gemini, Text-Bison)
- **OpenAI**: Fallback provider for high-quality responses
- **Vector Search**: BigQuery Vector Search for RAG capabilities

## Security

- No API keys in code - all secrets in Secret Manager
- Workload Identity Federation for service authentication
- VPC and private service access
- Minimal IAM permissions per service

## Deployment

Infrastructure is managed via Terraform with CI/CD through GitHub Actions.

See individual component READMEs for detailed setup instructions.