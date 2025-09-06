# HTXV2 Local PC Deployment Guide

This guide will help you deploy the complete HTXV2 cryptocurrency trading platform on your local PC.

## 🚀 Quick Start (Recommended)

### 1. Clone and Setup
```bash
git clone https://github.com/Kaushator/HTXV2.git
cd HTXV2

# Set up development environment
make setup
```

### 2. Start the Application
```bash
# Start all services with Docker
make docker-start

# Or use the deployment script for more control
./scripts/deploy.sh --env development deploy
```

### 3. Access Your Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000  
- **API Documentation**: http://localhost:8000/docs
- **ML Service**: http://localhost:8080 (if GPU enabled)

## 🛠️ Detailed Setup

### Prerequisites
- **Docker Desktop**: Latest version with Docker Compose V2
- **Git**: For cloning the repository
- **4GB+ RAM**: Minimum for all services
- **10GB+ Disk Space**: For Docker images and data

Optional for AI features:
- **NVIDIA GPU**: RTX 4060 or similar for local AI
- **WSL2**: If on Windows for GPU support

### Environment Configuration

1. **Copy environment files**:
```bash
# Backend environment
cp backend/.env.example backend/.env

# Frontend environment (already created)
# frontend/.env.local

# Production environment (if needed)
cp docker/.env.prod.example docker/.env.prod
```

2. **Edit configuration files** (optional):
   - Add your API keys for external services
   - Configure database passwords
   - Set up monitoring credentials

### Available Commands

```bash
# Development
make setup                 # Initial setup
make dev-backend          # Run backend only
make dev-frontend         # Run frontend only
make dev-all             # Run both backend and frontend

# Docker Operations
make docker-build-all     # Build all Docker images
make docker-start         # Start all services
make docker-stop          # Stop all services
make docker-restart       # Restart services
make docker-logs          # View service logs
make docker-clean         # Clean containers and volumes

# Testing and Validation
make test-all            # Run all tests
make test-performance    # Performance testing
make check-endpoints     # API endpoint validation

# Production Deployment
make deploy-prod         # Deploy production environment
```

## 🧪 Testing Your Deployment

### 1. Health Check
```bash
# Check if all services are running
curl http://localhost:8000/health

# Check API endpoints
make check-endpoints
```

### 2. Performance Testing
```bash
# Run comprehensive performance tests
make test-performance

# Custom performance testing
./scripts/test-performance.sh api --users 10 --duration 60
```

### 3. API Testing
Visit http://localhost:8000/docs for interactive API documentation and testing.

## 🤖 AI/ML Features

### Available AI Endpoints
- **GPT Prompt Suggestions**: `POST /api/v1/gpt/suggest-prompt`
- **Market Analysis**: `POST /api/v1/gpt/analyze-market`
- **Strategy Generation**: `POST /api/v1/gpt/generate-strategy`
- **ML Predictions**: `POST /api/v1/ml/predict`
- **Model Management**: `GET /api/v1/ml/models`

### Example API Calls
```bash
# Get trading signal suggestions
curl -X POST "http://localhost:8000/api/v1/gpt/suggest-prompt" \
  -H "Content-Type: application/json" \
  -d '{"context": "Analyze Bitcoin trends", "purpose": "analysis", "symbol": "BTC"}'

# Generate market analysis
curl -X POST "http://localhost:8000/api/v1/gpt/analyze-market" \
  -H "Content-Type: application/json" \
  -d '{"symbol": "BTC", "timeframe": "24h", "include_sentiment": true}'
```

## 📊 Features Overview

### Trading Features
- **Real-time Market Data**: Live cryptocurrency prices and data
- **Trading Signals**: AI-powered buy/sell signals with confidence scores
- **Portfolio Management**: Track multiple portfolios and positions
- **Backtesting**: Test trading strategies with historical data
- **Price History**: Historical price charts and analysis

### AI/ML Features
- **Intelligent Prompts**: Context-aware prompt suggestions for trading analysis
- **Market Analysis**: AI-powered market sentiment and technical analysis
- **Strategy Generation**: Automated trading strategy creation
- **Risk Assessment**: AI-based risk analysis and management
- **Predictive Models**: Price prediction and trend analysis

### Data Sources
- **HTX (Huobi)**: Real-time exchange data
- **CoinGecko**: Market data and cryptocurrency information
- **CryptoPanic**: News sentiment and social media analysis
- **Custom Data**: Upload CSV/XLSX files for analysis

## 🔧 Troubleshooting

### Common Issues

1. **Port conflicts**:
```bash
# Check what's using ports
netstat -tulpn | grep :3000
netstat -tulpn | grep :8000

# Stop conflicting services or change ports in docker-compose.yml
```

2. **Docker issues**:
```bash
# Clean up Docker
make docker-clean
docker system prune -af

# Restart Docker Desktop
```

3. **Memory issues**:
```bash
# Check container memory usage
docker stats

# Reduce services if needed by commenting out in docker-compose.yml
```

4. **Database connection issues**:
```bash
# Check database logs
make docker-logs | grep postgres

# Reset database
docker-compose down -v
make docker-start
```

### Performance Optimization

1. **For better performance**:
   - Close unnecessary applications
   - Increase Docker memory allocation (Docker Desktop settings)
   - Use SSD storage for Docker data

2. **For GPU features** (optional):
   - Install NVIDIA Docker toolkit
   - Configure WSL2 with GPU support
   - Use GPU-enabled Docker Compose file

## 📈 Production Deployment

For production deployment:

```bash
# Copy and edit production environment
cp docker/.env.prod.example docker/.env.prod
# Edit .env.prod with your production settings

# Deploy with monitoring
./scripts/deploy.sh --env production --profile monitoring deploy
```

## 🆘 Support

If you encounter issues:

1. **Check service logs**: `make docker-logs`
2. **Run health checks**: `curl http://localhost:8000/health`
3. **Test API endpoints**: `make check-endpoints`
4. **Performance diagnostics**: `make test-performance`

## 📋 What's Included

Your HTXV2 platform includes:

✅ **Complete Backend API** with authentication, trading, and AI endpoints  
✅ **Modern Frontend** with Next.js and real-time features  
✅ **AI/ML Integration** with GPT-powered analysis  
✅ **Database** with PostgreSQL and vector search capabilities  
✅ **Caching** with Redis for high performance  
✅ **Monitoring** with optional Prometheus and Grafana  
✅ **Testing Suite** for validation and performance  
✅ **Production Deployment** scripts and configuration  

## 🎯 Next Steps

After deployment:

1. **Explore the API**: Visit http://localhost:8000/docs
2. **Test AI features**: Try the GPT prompt suggestions
3. **Set up monitoring**: Enable Grafana dashboards
4. **Add real data**: Configure external API keys
5. **Customize**: Modify the application for your specific needs

---

**Your HTXV2 platform is now ready for cryptocurrency trading and analysis!** 🚀