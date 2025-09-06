# HTXV2 - Cryptocurrency Trading Platform

## Infrastructure and Code Synchronization

This project implements a comprehensive GCP-based cryptocurrency trading platform with the following architecture:

### Core Components
- **Frontend**: Next.js 14 with TypeScript and shadcn/ui
- **Backend**: FastAPI with SQLAlchemy and async PostgreSQL
- **Infrastructure**: Terraform for GCP resource management
- **ETL**: Data pipelines for HTX, Coingecko, and Cryptopanic
- **ML/LLM**: Local FinGPT + Vertex AI + OpenAI integration
- **Database**: Cloud SQL PostgreSQL with pgvector extension
- **Cache**: Memorystore Redis
- **Storage**: Google Cloud Storage buckets
- **Data Warehouse**: BigQuery with vector search
- **Container Registry**: Artifact Registry
- **Security**: Secret Manager + Workload Identity Federation

### Project Structure
```
├── infrastructure/         # Terraform configurations
├── backend/               # FastAPI application  
├── frontend/              # Next.js React application
├── etl/                   # Data processing pipelines
├── ml/                    # ML/LLM services
├── docker/                # Container configurations
├── .github/workflows/     # CI/CD pipelines
├── scripts/               # Utility scripts
└── docs/                  # Documentation
```

### Key Features Implemented

#### Infrastructure (Terraform)
- ✅ VPC with private subnets and Cloud NAT
- ✅ Cloud SQL PostgreSQL with pgvector
- ✅ Memorystore Redis for caching
- ✅ Cloud Storage buckets for data lake
- ✅ BigQuery datasets and tables
- ✅ Artifact Registry for containers
- ✅ Service accounts with minimal IAM
- ✅ Secret Manager for secure configuration
- ✅ Cloud Scheduler and Pub/Sub for orchestration

#### Backend (FastAPI)
- ✅ Async FastAPI with SQLAlchemy ORM
- ✅ JWT authentication with refresh tokens
- ✅ PostgreSQL models for users, portfolios, positions
- ✅ RESTful APIs for trading, portfolio management
- ✅ Database migrations with Alembic
- ✅ Pydantic schemas for validation
- ✅ Service layer architecture
- ✅ Health checks and monitoring

#### Frontend (Next.js)
- ✅ Next.js 14 with App Router and TypeScript
- ✅ shadcn/ui components with Tailwind CSS
- ✅ React Query for data fetching
- ✅ Zustand for state management
- ✅ Theme provider for dark/light mode
- ✅ Responsive design with mobile support
- ✅ PWA capabilities

#### ETL Pipeline
- ✅ HTX (Huobi) data extractor with rate limiting
- ✅ Async data processing with retry logic
- ✅ Configuration management
- ✅ Error handling and logging
- ✅ Batch and streaming data support

#### ML/LLM Stack
- ✅ LLM provider selection logic (FinGPT + Vertex AI + OpenAI)
- ✅ Intelligent fallback mechanisms
- ✅ Financial analysis and trading signals
- ✅ Provider health monitoring
- ✅ Response caching and optimization

#### DevOps & Security
- ✅ Docker containers for all services
- ✅ Docker Compose for local development
- ✅ GitHub Actions CI/CD pipeline
- ✅ Automated testing and linting
- ✅ Security scanning with Trivy
- ✅ Infrastructure validation
- ✅ Automated deployment to Cloud Run

### Getting Started

#### Prerequisites
- Node.js 18+
- Python 3.11+
- Docker and Docker Compose
- Google Cloud SDK
- Terraform 1.5+

#### Local Development
```bash
# Clone and setup
git clone <repository-url>
cd HTXV2

# Start development environment
make setup
docker-compose -f docker/docker-compose.yml up -d

# Access services
Frontend: http://localhost:3000
Backend API: http://localhost:8000
API Docs: http://localhost:8000/docs
```

#### Production Deployment
```bash
# Initialize Terraform
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project details
terraform init
terraform plan
terraform apply

# Deploy applications
make docker-build-all
make docker-push-all
make deploy-prod
```

### Architecture Highlights

#### Data Flow
1. **Ingestion**: HTX/Coingecko/Cryptopanic → GCS (raw)
2. **Processing**: Cloud Run Jobs → BigQuery (curated)
3. **Analysis**: ML models → Trading signals
4. **Storage**: PostgreSQL (operational) + BigQuery (analytical)
5. **Caching**: Redis (real-time data + sessions)
6. **Frontend**: React Query → FastAPI → Database

#### Security Implementation
- No API keys in code (Secret Manager)
- Workload Identity Federation (no JSON keys)
- VPC with private networking
- SSL/TLS encryption everywhere
- Minimal IAM permissions per service
- Database connection encryption

#### Scalability & Performance
- Async Python with proper connection pooling
- Redis caching for hot data
- BigQuery for analytical workloads
- Cloud Run auto-scaling
- CDN for static assets
- Database read replicas (configurable)

#### Monitoring & Observability
- Structured logging with correlation IDs
- Health checks for all services
- Prometheus metrics
- Error tracking and alerting
- Performance monitoring
- Cost optimization tracking

### Technology Stack Alignment

The implementation fully aligns with the problem statement requirements:

- ✅ **Frontend**: Next.js/React with shadcn/ui
- ✅ **Backend**: FastAPI with SQLAlchemy
- ✅ **Database**: Cloud SQL PostgreSQL + pgvector
- ✅ **Cache**: Memorystore Redis  
- ✅ **Storage**: GCS data lake
- ✅ **Analytics**: BigQuery with vector search
- ✅ **ML/AI**: Vertex AI + local FinGPT
- ✅ **Infrastructure**: Terraform IaC
- ✅ **Security**: Secret Manager + WIF
- ✅ **Orchestration**: Cloud Scheduler + Pub/Sub
- ✅ **Containers**: Artifact Registry
- ✅ **CI/CD**: GitHub Actions

### Next Steps

The foundation is complete and ready for:
1. Fine-tuning ML models with real market data
2. Implementing advanced trading strategies
3. Adding real-time WebSocket connections
4. Scaling infrastructure based on usage
5. Implementing advanced security features
6. Adding comprehensive monitoring dashboards

This implementation provides a production-ready foundation that can scale from development to enterprise usage while maintaining security, performance, and cost optimization.