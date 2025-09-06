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

#### Option 1: Local AI Environment (RTX 4060 + 90GB RAM)

For optimal AI development with local GPU acceleration:

```bash
# Clone repository
git clone https://github.com/Kaushator/HTXV2.git
cd HTXV2

# Start GPU-enabled environment with FinGPT
./scripts/start-local-ai.sh
```

See [Local AI Setup Guide](docs/LOCAL_AI_SETUP.md) for detailed WSL2 + Docker Desktop configuration.

#### Option 2: Standard Development

For cloud-only development without local GPU:

```bash
# Clone repository  
git clone https://github.com/Kaushator/HTXV2.git
cd HTXV2

# Set up environment variables
# Run backend: make dev-backend
# Run frontend: make dev-frontend
# Run infrastructure: make tf-plan
```

### Access Points

After starting the local environment:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000  
- **API Documentation**: http://localhost:8000/docs
- **ML Service**: http://localhost:8080 (GPU-enabled FinGPT)

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

- **Local FinGPT**: LoRA-adapted model optimized for RTX 4060 (8GB VRAM)
- **Vertex AI**: Cloud-based models (Gemini, Text-Bison)  
- **OpenAI**: Fallback provider for high-quality responses
- **Vector Search**: BigQuery Vector Search for RAG capabilities
- **GPU Acceleration**: CUDA 12.1+ support with 4-bit quantization
- **Memory Optimization**: Supports up to 90GB RAM for large model loading

## Security

- No API keys in code - all secrets in Secret Manager
- Workload Identity Federation for service authentication
- VPC and private service access
- Minimal IAM permissions per service

## Deployment

Infrastructure is managed via Terraform with CI/CD through GitHub Actions.

See individual component READMEs for detailed setup instructions.