# HTXV2 Development Environment - Quick Start Guide

## ✅ What's Working

### Infrastructure (Fully Operational)
- **PostgreSQL**: Running with pgvector extension
- **Redis**: Cache and real-time data storage
- **Backend API**: FastAPI application with full feature set

### Current Status
```bash
# Infrastructure services are healthy
docker compose -f docker/docker-compose.yml ps
NAME                IMAGE                    COMMAND                  SERVICE    CREATED         STATUS                    PORTS
docker-backend-1    docker-backend           "uvicorn app.main:ap…"   backend    X minutes ago   Up X minutes (healthy)    0.0.0.0:8000->8000/tcp
docker-postgres-1   pgvector/pgvector:pg15   "docker-entrypoint.s…"   postgres   X minutes ago   Up X minutes (healthy)    0.0.0.0:5432->5432/tcp
docker-redis-1      redis:7-alpine           "docker-entrypoint.s…"   redis      X minutes ago   Up X minutes (healthy)    0.0.0.0:6379->6379/tcp
```

## 🚀 Quick Start Commands

### Start Full Backend Stack
```bash
cd docker
docker compose up -d  # Starts PostgreSQL + Redis + Backend
```

### Access Points
- **Backend API**: http://localhost:8000/health
- **API Documentation**: http://localhost:8000/docs
- **Database**: PostgreSQL on port 5432
- **Cache**: Redis on port 6379

### Test API
```bash
# Health check
curl http://localhost:8000/health

# MCP tools
curl http://localhost:8000/api/v1/mcp/tools

# API documentation
open http://localhost:8000/docs
```

### Frontend Development (Alternative to Docker)
```bash
# Start frontend in development mode
./scripts/start-frontend-dev.sh
# or manually:
cd frontend && npm install && npm run dev
```

## 🔧 Development Environment

### DevContainer Setup
- **Location**: `.devcontainer/devcontainer.json`
- **Features**: Python 3.11, Node.js 18, Docker-in-Docker
- **Extensions**: Copilot, Python tools, TypeScript support
- **Ports**: Auto-forwards 8000, 3000, 5432, 6379

### VS Code Configuration
The devcontainer includes pre-configured VS Code settings for:
- Python formatting (Black)
- TypeScript support
- Tailwind CSS IntelliSense
- GitHub Copilot integration

## 📋 Resolved Issues

### ✅ Fixed
1. **SSL Certificate Issues**: Added trusted hosts for pip installs
2. **Missing Dependencies**: Added email-validator to backend requirements
3. **WebSocket URL Mismatch**: Fixed inconsistency between compose files
4. **Database Connectivity**: PostgreSQL + Redis healthy and accessible
5. **DevContainer Configuration**: Created comprehensive development setup

### ⚠️ Known Limitations
1. **Frontend Docker Build**: SSL issues with Alpine package manager
   - **Workaround**: Use development mode (`npm run dev`) instead
2. **Local Validation Scripts**: Require local Python environment
   - **Solution**: Use Docker containers or devcontainer

## 🛠️ Development Workflow

### Option 1: Full Docker Stack
```bash
cd docker
docker compose up -d
# Backend at http://localhost:8000
# Start frontend separately: ./scripts/start-frontend-dev.sh
```

### Option 2: DevContainer (Recommended)
1. Open project in VS Code
2. "Reopen in Container" when prompted
3. Everything auto-configured and ready

### Option 3: Manual Setup
```bash
# Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend (separate terminal)
cd frontend
npm install
npm run dev
```

## 📚 Available API Endpoints

The backend provides comprehensive REST API with:
- **Authentication**: User registration, login, JWT tokens
- **Trading**: Signals, market data, price history
- **Portfolio**: Management, positions, analytics
- **Data**: Price data, uploads, news, market overview
- **MCP**: System health, task management, real-time updates
- **WebSocket**: Real-time communication at `/api/v1/mcp/ws`

Full documentation available at: http://localhost:8000/docs

## 🔄 Next Steps

1. **Start Development**: Use devcontainer or Docker stack
2. **Configure APIs**: Add your HTX API keys to `.env` files
3. **Test Features**: Explore API endpoints via Swagger UI
4. **Frontend Development**: Start with `npm run dev` 
5. **Production Setup**: Configure GCP resources via Terraform

## 🐛 Troubleshooting

### Backend Not Starting
```bash
docker compose logs backend
# Check for missing environment variables or dependency issues
```

### Database Connection Issues
```bash
docker compose logs postgres
# Verify PostgreSQL is healthy
docker compose ps
```

### Port Conflicts
```bash
# Check what's using ports 8000, 3000, 5432, 6379
lsof -i :8000
# Stop conflicting services or change ports in docker-compose.yml
```

### SSL Issues During Build
```bash
# Use development mode instead of Docker for frontend
./scripts/start-frontend-dev.sh
```