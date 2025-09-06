# HTXV2 Integration and Production Deployment Guide

This document provides comprehensive instructions for integrating, testing, and deploying the HTXV2 cryptocurrency trading platform.

## Table of Contents

1. [Quick Start](#quick-start)
2. [API Integration](#api-integration)
3. [GPT/LLM Integration](#gptllm-integration)
4. [Performance Testing](#performance-testing)
5. [Production Deployment](#production-deployment)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Troubleshooting](#troubleshooting)

## Quick Start

### Development Environment

```bash
# Clone and setup
git clone <repository-url>
cd HTXV2

# Quick development setup
make setup
make docker-start

# Check everything is working
make test-api
make check-endpoints
```

### Production Deployment

```bash
# Production deployment
./scripts/deploy.sh --env production deploy

# With monitoring
./scripts/deploy.sh --env production --profile monitoring deploy

# Full production stack
./scripts/deploy.sh --env production --profile "proxy,monitoring" deploy
```

## API Integration

### Core API Endpoints

The HTXV2 platform provides comprehensive REST APIs organized into the following categories:

#### 1. Authentication & Users
```
POST /api/v1/auth/register     - User registration
POST /api/v1/auth/login        - User login
POST /api/v1/auth/refresh      - Refresh access token
POST /api/v1/auth/logout       - User logout
GET  /api/v1/users/me          - Get current user info
PUT  /api/v1/users/me          - Update user profile
```

#### 2. Data & Market Information
```
GET  /api/v1/data/crypto-prices           - Get cryptocurrency prices
GET  /api/v1/data/exchanges               - Get supported exchanges
GET  /api/v1/data/news                    - Get cryptocurrency news
GET  /api/v1/data/market-overview         - Get market overview
GET  /api/v1/data/analytics/correlation   - Get correlation analysis
POST /api/v1/data/upload                  - Upload data files
```

#### 3. Trading & Signals
```
GET  /api/v1/trading/signals                  - Get trading signals
POST /api/v1/trading/signals                  - Create trading signal
GET  /api/v1/trading/market-data/{symbol}     - Get market data
GET  /api/v1/trading/price-history/{symbol}   - Get price history
POST /api/v1/trading/backtest                 - Backtest strategy
```

#### 4. Portfolio Management
```
GET    /api/v1/portfolio/                     - Get portfolios
POST   /api/v1/portfolio/                     - Create portfolio
GET    /api/v1/portfolio/{id}                 - Get portfolio details
PUT    /api/v1/portfolio/{id}                 - Update portfolio
DELETE /api/v1/portfolio/{id}                 - Delete portfolio
GET    /api/v1/portfolio/{id}/positions       - Get positions
POST   /api/v1/portfolio/{id}/positions       - Add position
```

#### 5. Machine Learning
```
POST /api/v1/ml/generate-analysis        - Generate ML analysis
POST /api/v1/ml/predict                  - Make predictions
GET  /api/v1/ml/models                   - Get available models
POST /api/v1/ml/models/train             - Train new model
GET  /api/v1/ml/models/{id}/status       - Get training status
```

#### 6. GPT/LLM Services
```
POST /api/v1/gpt/suggest-prompt          - Get prompt suggestions
POST /api/v1/gpt/analyze-market          - AI market analysis
POST /api/v1/gpt/generate-strategy       - Generate trading strategy
POST /api/v1/gpt/explain-signal          - Explain trading signals
```

### Example API Usage

#### Authentication
```javascript
// Login
const response = await fetch('/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: 'username=user@example.com&password=secretpassword'
});
const { access_token } = await response.json();

// Use token for authenticated requests
const headers = { 'Authorization': `Bearer ${access_token}` };
```

#### Get Trading Signals
```javascript
const signals = await fetch('/api/v1/trading/signals?symbol=BTC&limit=10', {
  headers
}).then(r => r.json());
```

#### Generate AI Analysis
```javascript
const analysis = await fetch('/api/v1/gpt/analyze-market', {
  method: 'POST',
  headers: { ...headers, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    symbol: 'BTC',
    timeframe: '24h',
    analysis_depth: 'detailed',
    include_sentiment: true
  })
}).then(r => r.json());
```

## GPT/LLM Integration

### Prompt Suggestion System

The platform includes an intelligent prompt suggestion system that helps generate optimized prompts for different use cases:

```javascript
// Get prompt suggestions
const suggestions = await fetch('/api/v1/gpt/suggest-prompt', {
  method: 'POST',
  headers: { ...headers, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    context: "I need to analyze Bitcoin's recent price movement",
    purpose: "analysis",  // analysis, strategy, explanation, prediction
    symbol: "BTC",
    data_context: {
      timeframe: "24h",
      price_change: 2.5
    }
  })
}).then(r => r.json());

// Response includes:
// - suggested_prompts: Array of optimized prompts
// - recommended_prompt: Best prompt for the context
// - parameters: Optimal LLM parameters
```

### AI-Powered Market Analysis

```javascript
// Generate comprehensive market analysis
const marketAnalysis = await fetch('/api/v1/gpt/analyze-market', {
  method: 'POST',
  headers: { ...headers, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    symbol: 'BTC',
    timeframe: '24h',
    analysis_depth: 'detailed',
    include_sentiment: true,
    include_technical: true
  })
}).then(r => r.json());

// Response includes:
// - analysis: Detailed text analysis
// - key_insights: Array of key points
// - sentiment_score: Numerical sentiment (0-1)
// - confidence: Analysis confidence level
```

### Strategy Generation

```javascript
// Generate AI-powered trading strategy
const strategy = await fetch('/api/v1/gpt/generate-strategy', {
  method: 'POST',
  headers: { ...headers, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    symbol: 'BTC',
    risk_tolerance: 'medium',  // low, medium, high
    investment_horizon: 'medium_term',
    capital_amount: 10000,
    preferences: {
      max_positions: 5,
      diversification: true
    }
  })
}).then(r => r.json());

// Response includes:
// - strategy_name: Generated strategy name
// - description: Strategy overview
// - entry_conditions: When to enter trades
// - exit_conditions: When to exit trades
// - risk_management: Risk parameters
// - expected_return: Projected returns
```

## Performance Testing

### Automated Testing

```bash
# Test API endpoint performance
make test-performance

# Test specific components
./scripts/test-performance.sh api --users 20 --duration 120
./scripts/test-performance.sh database
./scripts/test-performance.sh memory
./scripts/test-performance.sh network
```

### Custom Performance Tests

```python
# Example custom performance test
import asyncio
import aiohttp
import time

async def test_custom_endpoint():
    async with aiohttp.ClientSession() as session:
        start_time = time.time()
        
        # Test your custom endpoint
        async with session.get('http://localhost:8000/api/v1/custom-endpoint') as resp:
            data = await resp.json()
            response_time = time.time() - start_time
            
        print(f"Response time: {response_time:.3f}s")
        print(f"Status: {resp.status}")
        return data

# Run the test
result = asyncio.run(test_custom_endpoint())
```

### Performance Benchmarks

**Target Performance Metrics:**
- API Response Time: < 200ms (P95)
- Database Query Time: < 50ms (average)
- Memory Usage: < 512MB per service
- Success Rate: > 99.5%
- Concurrent Users: 100+ simultaneous

## Production Deployment

### Prerequisites

1. **System Requirements:**
   - Docker 20.10+
   - Docker Compose 2.0+
   - 4GB+ RAM
   - 20GB+ disk space
   - Ubuntu 20.04+ or similar

2. **External Services:**
   - PostgreSQL 15+ with pgvector
   - Redis 7+
   - Google Cloud Project (optional)
   - SSL certificates for HTTPS

### Deployment Steps

1. **Prepare Environment:**
```bash
# Clone repository
git clone <repository-url>
cd HTXV2

# Copy and configure environment
cp docker/.env.prod.example docker/.env.prod
# Edit docker/.env.prod with your configuration
```

2. **Set Up SSL (Production):**
```bash
# Place SSL certificates
mkdir -p docker/ssl
cp your-cert.pem docker/ssl/cert.pem
cp your-key.pem docker/ssl/key.pem
```

3. **Deploy Services:**
```bash
# Basic production deployment
./scripts/deploy.sh --env production deploy

# With monitoring stack
./scripts/deploy.sh --env production --profile monitoring deploy

# Full production with proxy
./scripts/deploy.sh --env production --profile "proxy,monitoring" deploy
```

4. **Verify Deployment:**
```bash
# Check service status
./scripts/deploy.sh status

# Run health checks
curl https://yourdomain.com/health
curl https://yourdomain.com/api/v1/data/exchanges
```

### Environment Configuration

**Key Environment Variables:**

```bash
# Security
SECRET_KEY=your-super-secret-jwt-key-32-chars-min
POSTGRES_PASSWORD=secure-postgres-password
REDIS_PASSWORD=secure-redis-password

# External APIs
OPENAI_API_KEY=your-openai-key
COINGECKO_API_KEY=your-coingecko-key
HTX_API_KEY=your-htx-key

# Domain Configuration
BACKEND_CORS_ORIGINS=["https://yourdomain.com"]
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api/v1

# Google Cloud (if using)
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CREDENTIALS_PATH=./credentials
```

## Monitoring and Maintenance

### Health Monitoring

1. **Service Health Endpoints:**
   - Backend: `GET /health`
   - Frontend: `GET /api/health`
   - ML Service: `GET /health`

2. **Automated Monitoring:**
```bash
# Set up monitoring stack
./scripts/deploy.sh --env production --profile monitoring deploy

# Access monitoring dashboards
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3001 (admin/admin)
```

3. **Custom Health Checks:**
```bash
#!/bin/bash
# Add to crontab for regular health checks
curl -f https://yourdomain.com/health || echo "Service down" | mail -s "HTXV2 Alert" admin@yourdomain.com
```

### Log Management

```bash
# View service logs
./scripts/deploy.sh logs

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f ml
```

### Backup Procedures

```bash
# Database backup
docker compose exec postgres pg_dump -U htxv2_user htxv2 > backup_$(date +%Y%m%d).sql

# ML models backup
docker compose exec ml tar -czf /tmp/models_backup.tar.gz /app/models
docker compose cp ml:/tmp/models_backup.tar.gz ./backups/
```

### Scaling

```bash
# Scale specific services
docker compose up -d --scale backend=3
docker compose up -d --scale ml=2

# Use environment variables
BACKEND_REPLICAS=3 ./scripts/deploy.sh --env production deploy
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues:**
```bash
# Check database connectivity
docker compose exec backend python -c "
import asyncpg
import asyncio
async def test(): 
    conn = await asyncpg.connect('postgresql://htxv2_user:password@postgres:5432/htxv2')
    print('Database connected successfully')
    await conn.close()
asyncio.run(test())
"
```

2. **Memory Issues:**
```bash
# Check memory usage
docker stats

# Increase memory limits in docker-compose.prod.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
```

3. **SSL Certificate Issues:**
```bash
# Verify SSL certificates
openssl x509 -in docker/ssl/cert.pem -text -noout
openssl rsa -in docker/ssl/key.pem -check
```

4. **API Rate Limiting:**
```bash
# Check API rate limits
curl -I https://api.yourdomain.com/api/v1/data/exchanges
# Look for X-RateLimit-* headers
```

### Performance Issues

1. **Slow API Responses:**
   - Check database query performance
   - Review API endpoint implementations
   - Monitor resource usage
   - Consider caching strategies

2. **High Memory Usage:**
   - Check for memory leaks
   - Optimize ML model loading
   - Implement connection pooling
   - Review container memory limits

3. **Database Performance:**
   - Add appropriate indexes
   - Optimize slow queries
   - Consider read replicas
   - Monitor connection pool usage

### Getting Help

1. **Check service logs first:**
```bash
docker compose logs servicename
```

2. **Run diagnostic tests:**
```bash
make test-performance
make check-endpoints
```

3. **Monitor resource usage:**
```bash
docker stats
./scripts/test-performance.sh memory
```

For additional support, check the project documentation and issue tracker.

## Security Considerations

### Production Security Checklist

- [ ] Change all default passwords
- [ ] Use HTTPS in production
- [ ] Implement proper CORS settings
- [ ] Set up firewall rules
- [ ] Regular security updates
- [ ] Monitor for vulnerabilities
- [ ] Backup and recovery procedures
- [ ] Access control and authentication
- [ ] API rate limiting
- [ ] Input validation and sanitization

### Recommended Security Practices

1. **Use environment variables for secrets**
2. **Implement proper logging and monitoring**
3. **Regular security audits**
4. **Keep dependencies updated**
5. **Use security headers**
6. **Implement proper error handling**
7. **Regular backups and disaster recovery testing**

This guide provides comprehensive instructions for integrating and deploying the HTXV2 platform. For specific implementation details, refer to the individual component documentation and API specifications.