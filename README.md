# HTXV2 - Cryptocurrency Trading Platform

A comprehensive GCP-based cryptocurrency trading platform with ML/AI capabilities.

## Quick Start

### Prerequisites

- **Python 3.11+** (recommended 3.11 for best compatibility)
- **Node.js 18+**
- **Docker & Docker Compose**
- **Git**

### Local Development

1. **Clone and setup:**
   ```bash
   git clone https://github.com/Kaushator/HTXV2.git
   cd HTXV2
   make setup
   ```

2. **Start with Docker:**
   ```bash
   cd docker
   docker compose up -d
   ```

3. **Manual setup (alternative):**
   ```bash
   # Backend
   cd backend
   python3 -m venv venv
   ./venv/bin/pip install -r requirements.txt
   
   # Frontend
   cd frontend
   npm install
   ```

### Access Points

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Database**: PostgreSQL on localhost:5432
- **Cache**: Redis on localhost:6379

## Data Sources

- **HTX (Huobi)**: Cryptocurrency exchange data
- **Coingecko**: Market data and cryptocurrency information  
- **Cryptopanic**: News and sentiment data
- **User uploads**: CSV/XLSX files via signed URLs

## Development Commands

```bash
# Setup environment
make setup

# Development servers
make dev-backend      # Start FastAPI backend
make dev-frontend     # Start Next.js frontend  
make dev-all          # Start both frontend and backend

# Testing & Quality
make test-all         # Run all tests
make lint-all         # Run all linters
make clean           # Clean build artifacts

# Docker
cd docker && docker compose up -d

# Terraform (Infrastructure)
make tf-init         # Initialize Terraform
make tf-plan         # Plan infrastructure changes
make tf-apply        # Apply infrastructure changes
```

## Security & Best Practices

### Development
- Environment variables in `.env` files (never committed)
- Type safety with TypeScript and Python type hints
- Linting with ESLint (frontend) and flake8 (backend)
- Pre-commit hooks for code quality

### Production
- JWT authentication with Google OAuth2
- API rate limiting and CORS protection
- Secret management via GCP Secret Manager
- Container security with non-root users
- Network security with VPC and firewall rules

## Deployment

### Local Development
```bash
cd docker && docker compose up -d
```

### Production (GCP)
```bash
# Deploy infrastructure
make tf-apply

# Build and deploy containers
make docker-build-all
make docker-push-all
make deploy-prod
```

## Support & Documentation

- **API Docs**: http://localhost:8000/docs (when running)
- **Architecture**: See `docs/` directory
- **Component READMEs**: Each directory has detailed setup instructions
- **Issues**: Use GitHub Issues for bug reports and feature requests

## License

MIT License - see LICENSE file for details.
