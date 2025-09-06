# HTXV2 - Cryptocurrency Trading Platform

A comprehensive GCP-based cryptocurrency trading platform with AI/ML capabilities, real-time data processing, and intelligent trading signals.

## 🚀 Quick Start

### Development
```bash
git clone <repository-url>
cd HTXV2
make setup
make docker-start
```

### Production
```bash
./scripts/deploy.sh --env production deploy
```

## 🏗️ Architecture Overview

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

## ✨ Key Features

### 🤖 AI/ML Integration
- **Local FinGPT**: LoRA-adapted model for financial analysis
- **GPT Prompt Suggestions**: Intelligent prompt generation for trading analysis
- **Multi-LLM Support**: OpenAI, Vertex AI, and local model fallbacks
- **Vector Search**: RAG capabilities with BigQuery Vector Search
- **ML Trading Signals**: Automated signal generation and backtesting

### 📊 Trading & Analytics
- **Real-time Market Data**: HTX, Coingecko, CryptoPanic integration
- **Portfolio Management**: Multi-portfolio tracking and analytics
- **Advanced Charting**: Technical analysis with custom indicators
- **Risk Management**: Position sizing and risk assessment tools
- **Backtesting Engine**: Strategy testing with historical data

### 🔧 Infrastructure
- **Containerized Services**: Docker-based microservices architecture
- **Auto-scaling**: Kubernetes-ready with horizontal scaling
- **Monitoring**: Prometheus, Grafana, and custom dashboards
- **CI/CD**: GitHub Actions with automated testing and deployment
- **Security**: Secret management, HTTPS, and security scanning

## 📋 Components

- **Frontend**: Next.js 14 with React, TypeScript, and shadcn/ui
- **Backend**: FastAPI with SQLAlchemy, Alembic migrations
- **Infrastructure**: Terraform for GCP resource management
- **Database**: Cloud SQL PostgreSQL with pgvector extension
- **Caching**: Memorystore Redis for high-performance caching
- **Storage**: Google Cloud Storage for data lake
- **Data Warehouse**: BigQuery with vector search capabilities
- **ML/AI**: Vertex AI + local FinGPT with LoRA adapters
- **Container Registry**: Artifact Registry for Docker images
- **Security**: Secret Manager, Workload Identity Federation
- **Monitoring**: Cloud Logging, Error Reporting, Cloud Monitoring

## 🛠️ API Endpoints

### Authentication & Users
```
POST /api/v1/auth/register      - User registration
POST /api/v1/auth/login         - User login  
POST /api/v1/auth/refresh       - Refresh tokens
POST /api/v1/auth/logout        - User logout
GET  /api/v1/users/me           - Get user profile
```

### Trading & Signals
```
GET  /api/v1/trading/signals               - Get trading signals
POST /api/v1/trading/signals               - Create trading signal
GET  /api/v1/trading/market-data/{symbol}  - Real-time market data
GET  /api/v1/trading/price-history/{symbol} - Historical price data
POST /api/v1/trading/backtest              - Strategy backtesting
```

### AI/ML Services
```
POST /api/v1/ml/generate-analysis     - ML-powered market analysis
POST /api/v1/ml/predict              - Price predictions
GET  /api/v1/ml/models               - Available ML models
POST /api/v1/gpt/suggest-prompt      - GPT prompt suggestions
POST /api/v1/gpt/analyze-market      - AI market analysis
POST /api/v1/gpt/generate-strategy   - Trading strategy generation
```

### Data & Portfolio
```
GET  /api/v1/data/crypto-prices      - Cryptocurrency prices
GET  /api/v1/data/exchanges          - Supported exchanges
GET  /api/v1/data/news               - Market news and sentiment
GET  /api/v1/portfolio/              - Portfolio management
POST /api/v1/portfolio/              - Create portfolio
```

## 🧪 Testing & Performance

### Endpoint Testing
```bash
# Test API completeness
make check-endpoints

# Performance testing
make test-performance

# Custom load testing
./scripts/test-performance.sh api --users 50 --duration 300
```

### Performance Benchmarks
- **API Response Time**: < 200ms (P95)
- **Database Queries**: < 50ms average
- **Memory Usage**: < 512MB per service
- **Concurrent Users**: 100+ simultaneous
- **Success Rate**: > 99.5%

## 🚀 Deployment

### Development Environment
```bash
# Quick setup
make setup
make docker-start

# Access services
# Frontend: http://localhost:3000
# Backend: http://localhost:8000/docs
# ML Service: http://localhost:8080
```

### Production Deployment
```bash
# Basic production
./scripts/deploy.sh --env production deploy

# With monitoring
./scripts/deploy.sh --env production --profile monitoring deploy

# Full stack with proxy
./scripts/deploy.sh --env production --profile "proxy,monitoring" deploy
```

### Cloud Deployment
```bash
# Initialize infrastructure
cd infrastructure
terraform init
terraform plan
terraform apply

# Deploy applications
make docker-build-all
make deploy-prod
```

## 📊 Monitoring & Observability

### Built-in Monitoring
- **Health Checks**: Automated service health monitoring
- **Performance Metrics**: Response times, throughput, error rates
- **Resource Usage**: CPU, memory, disk, network monitoring
- **Business Metrics**: Trading volume, user activity, model performance

### Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards and visualization
- **Custom Dashboards**: Trading-specific metrics and KPIs
- **Log Aggregation**: Structured logging with search capabilities

### Alerts & Notifications
- **Service Health**: Automated alerts for service degradation
- **Performance**: Threshold-based performance alerts
- **Security**: Security event monitoring and alerts
- **Business**: Trading signal accuracy and portfolio performance

## 🤖 AI/GPT Integration

### Intelligent Prompt Generation
The platform includes sophisticated prompt suggestion capabilities:

```javascript
// Get optimized prompts for trading analysis
const suggestions = await fetch('/api/v1/gpt/suggest-prompt', {
  method: 'POST',
  body: JSON.stringify({
    context: "Analyze Bitcoin's recent volatility",
    purpose: "analysis",  // analysis, strategy, explanation, prediction
    symbol: "BTC"
  })
});
```

### AI-Powered Market Analysis
```javascript
// Generate comprehensive market analysis
const analysis = await fetch('/api/v1/gpt/analyze-market', {
  method: 'POST',
  body: JSON.stringify({
    symbol: 'BTC',
    timeframe: '24h',
    include_sentiment: true,
    include_technical: true
  })
});
```

### Local FinGPT Integration
- **GPU Support**: Optimized for RTX 4060 and similar hardware
- **LoRA Adapters**: Fine-tuned for financial analysis
- **Fallback Strategy**: Automatic fallback to cloud providers
- **Model Serving**: REST API for model inference

## 📈 Data Sources

### Real-time Data
- **HTX (Huobi)**: Cryptocurrency exchange data and order books
- **Coingecko**: Market data and cryptocurrency information
- **Cryptopanic**: News sentiment and social media data
- **User Uploads**: CSV/XLSX file processing via signed URLs

### Data Processing
- **ETL Pipelines**: Automated data ingestion and processing
- **Data Validation**: Quality checks and anomaly detection
- **Feature Engineering**: Technical indicators and market features
- **Data Storage**: Raw, processed, and curated data layers

## 🔒 Security

### Production Security
- **HTTPS/TLS**: End-to-end encryption
- **JWT Authentication**: Secure token-based authentication
- **API Rate Limiting**: Protection against abuse
- **Input Validation**: Comprehensive data sanitization
- **Secret Management**: Encrypted secrets with Google Secret Manager
- **Workload Identity**: Service-to-service authentication

### Development Security
- **Environment Isolation**: Separate dev/staging/production environments
- **Security Scanning**: Automated vulnerability scanning
- **Dependency Monitoring**: Regular security updates
- **Code Quality**: Automated linting and security checks

## 🛠️ Development

### Prerequisites
- Node.js 18+
- Python 3.11+
- Docker and Docker Compose
- Google Cloud SDK (optional)
- Terraform 1.5+ (for infrastructure)

### Local Development Commands
```bash
# Setup
make setup                 # Set up development environment
make docker-start         # Start all services

# Development
make dev-backend          # Run backend only
make dev-frontend         # Run frontend only
make dev-all             # Run both frontend and backend

# Testing
make test-all            # Run all tests
make test-performance    # Performance and bottleneck testing
make check-endpoints     # API endpoint completeness

# Code Quality
make lint-all            # Lint all code
make clean              # Clean build artifacts
```

### Docker Commands
```bash
make docker-build-all    # Build all images
make docker-start        # Start services
make docker-stop         # Stop services
make docker-logs         # View logs
make docker-clean        # Clean containers and volumes
```

## 📁 Project Structure

```
├── frontend/           # Next.js React application
├── backend/           # FastAPI application
├── infrastructure/    # Terraform configurations
├── ml/               # ML/LLM components and models
├── etl/              # Data processing pipelines
├── docker/           # Docker configurations
├── scripts/          # Utility and deployment scripts
├── tests/            # Test suites and performance tests
├── docs/             # Documentation
└── .github/          # GitHub Actions workflows
```

## 📖 Documentation

- **[Integration Guide](docs/INTEGRATION_GUIDE.md)**: Comprehensive integration instructions
- **[Implementation Details](docs/IMPLEMENTATION.md)**: Technical implementation overview
- **[API Documentation](http://localhost:8000/docs)**: Interactive API documentation
- **[Component READMEs](.)**: Individual component documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Check the [Integration Guide](docs/INTEGRATION_GUIDE.md)
- Review the [troubleshooting section](docs/INTEGRATION_GUIDE.md#troubleshooting)
- Run diagnostic tests: `make test-performance`
- Check service logs: `make docker-logs`

---

**Ready for production deployment with comprehensive AI integration, real-time data processing, and enterprise-grade monitoring.**