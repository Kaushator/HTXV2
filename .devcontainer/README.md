# DevContainer Configurations

This project supports multiple development container configurations:

## Available Configurations

### Backend Development (`.devcontainer/backend/`)
- **Focus**: Python FastAPI backend development
- **Services**: PostgreSQL, Redis, Backend API
- **Tools**: Python 3.11, FastAPI, SQLAlchemy, pytest
- **VS Code**: Python extensions, Docker, Copilot
- **Ports**: 8000 (API), 5432 (PostgreSQL), 6379 (Redis)

### Frontend Development (`.devcontainer/frontend/`)
- **Focus**: Next.js React frontend development  
- **Tools**: Node.js 18, TypeScript, Tailwind CSS
- **VS Code**: TypeScript extensions, ESLint, Prettier, Copilot
- **Ports**: 3000 (Frontend), 8000 (Backend API proxy)

## Usage

### Option 1: VS Code Dev Container Extension
1. Open the project in VS Code
2. Choose "Reopen in Container" when prompted
3. Select either `backend` or `frontend` configuration

### Option 2: Command Palette
1. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
2. Choose the appropriate configuration

### Option 3: Manual Selection
1. Copy desired config to `.devcontainer/devcontainer.json`
2. Restart VS Code and reopen in container

## Development Workflow

### Backend Container
```bash
# Container starts with all dependencies installed
cd /app
python -m uvicorn app.main:app --reload

# Run tests
pytest tests/

# Check MCP status
curl http://localhost:8000/api/v1/mcp/health
```

### Frontend Container  
```bash
# Container starts with node_modules installed
cd /workspace/frontend
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

## Troubleshooting

### Port Conflicts
- Backend container forwards 8000, 5432, 6379
- Frontend container forwards 3000, 8000
- Ensure ports are available on host

### Volume Issues
- Backend uses named volume for `venv` persistence
- Frontend uses named volume for `node_modules` persistence
- Run `docker volume ls` to check volumes

### Dependencies
- Backend: Auto-installs from `requirements.txt`
- Frontend: Auto-installs from `package.json`
- Rebuild container if dependencies change significantly

## Legacy Configuration
The original unified configuration is preserved as `legacy-devcontainer.json` for reference.