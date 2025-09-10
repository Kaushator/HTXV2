# Developer Setup Guide

This guide helps you set up HTXV2 for development with GitHub Codex and Copilot.

## Quick Start

1. **Clone and basic setup:**
   ```bash
   git clone https://github.com/Kaushator/HTXV2.git
   cd HTXV2
   ```

2. **Choose your setup method:**
   - [Docker Setup](#docker-setup) (Recommended for quick start)
   - [Manual Setup](#manual-setup) (For full development control)

## Docker Setup (Recommended)

### Prerequisites
- Docker Desktop with WSL2 support
- At least 8GB RAM available for containers

### Steps
```bash
# Start all services
cd docker
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

**Access URLs:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Manual Setup

### Backend Setup
```bash
cd backend

# Create virtual environment
python3 -m venv venv

# Activate and install dependencies
./venv/bin/pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run migrations (when database is available)
./venv/bin/alembic upgrade head

# Start development server
./venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your configuration

# Start development server
npm run dev
```

### Database Setup
```bash
# Option 1: Docker PostgreSQL (Recommended)
docker run -d \
  --name htxv2-postgres \
  -e POSTGRES_DB=htxv2 \
  -e POSTGRES_USER=htxv2_user \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  pgvector/pgvector:pg15

# Option 2: Local PostgreSQL
# Install PostgreSQL with pgvector extension
```

## Development Commands

### Using Makefile (Recommended)
```bash
# Setup everything
make setup

# Development
make dev-all          # Start both frontend and backend
make dev-backend      # Backend only
make dev-frontend     # Frontend only

# Testing and Quality
make test-all         # Run all tests
make lint-all         # Run all linters
make clean           # Clean build artifacts
```

### Manual Commands
```bash
# Backend
cd backend
./venv/bin/pytest tests/                    # Run tests
./venv/bin/black . && ./venv/bin/isort .   # Format code
./venv/bin/flake8 .                        # Lint code

# Frontend  
cd frontend
npm test              # Run tests
npm run lint          # Lint code
npm run type-check    # Check TypeScript
npm run build         # Build for production
```

## Environment Variables

### Backend (.env)
```env
# Database
DATABASE_URL=postgresql+asyncpg://htxv2_user:password@localhost:5432/htxv2

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=your-secret-key-here
DEBUG=true
ENVIRONMENT=development

# External APIs
HTX_API_KEY=your-htx-api-key
HTX_SECRET_KEY=your-htx-secret-key
OPENAI_API_KEY=your-openai-key (optional)
```

### Frontend (.env.local)
```env
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws

# Environment
NODE_ENV=development
```

## IDE Configuration

### VS Code Extensions (Recommended)
- Python (Microsoft)
- Pylance (Microsoft)
- TypeScript Importer (pmneo)
- ES7+ React/Redux/React-Native snippets (dsznajder)
- Tailwind CSS IntelliSense (Bradlc)
- Auto Rename Tag (Jun Han)
- GitLens (GitKraken)
- Docker (Microsoft)

### VS Code Settings (.vscode/settings.json)
```json
{
  "python.defaultInterpreterPath": "./backend/venv/bin/python",
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "typescript.preferences.importModuleSpecifier": "relative",
  "tailwindCSS.includeLanguages": {
    "typescript": "typescript",
    "typescriptreact": "typescript"
  }
}
```

## GitHub Codex/Copilot Tips

### For Better AI Assistance

1. **Use descriptive comments:**
   ```python
   # Create a trading signal based on RSI and moving averages
   def generate_trading_signal(price_data: pd.DataFrame) -> dict:
   ```

2. **Follow project patterns:**
   - Backend: Use FastAPI with async/await patterns
   - Frontend: Use React hooks and TypeScript
   - Database: Use SQLAlchemy models with proper relationships

3. **Leverage existing code:**
   - Reference similar functions in the codebase
   - Use consistent naming conventions
   - Follow established error handling patterns

### Common Patterns

#### Backend API Endpoint
```python
@router.get("/trading/signals/{symbol}")
async def get_trading_signals(
    symbol: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> List[TradingSignal]:
    """Get trading signals for a specific symbol"""
    # Implementation here
```

#### Frontend Component
```typescript
interface TradingSignalProps {
  symbol: string;
  signals: TradingSignal[];
}

export function TradingSignalCard({ symbol, signals }: TradingSignalProps) {
  // Component implementation
}
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change ports in docker-compose.yml or .env files
2. **Database connection**: Ensure PostgreSQL is running and credentials are correct
3. **Permission issues**: Use `chmod +x` for shell scripts
4. **Node modules**: Delete node_modules and package-lock.json, then `npm install`
5. **Python packages**: Delete venv and recreate: `python3 -m venv venv`

### Debug Mode

```bash
# Backend with debug logging
cd backend
DEBUG=true ./venv/bin/uvicorn app.main:app --reload --log-level debug

# Frontend with debug info
cd frontend
DEBUG=true npm run dev
```

## Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Follow code style guidelines (automated via pre-commit hooks)
3. Add tests for new functionality
4. Update documentation as needed
5. Submit pull request with clear description

## Getting Help

- **Documentation**: Check component README files
- **API Docs**: http://localhost:8000/docs (when running)
- **Issues**: Create GitHub issues for bugs/features
- **Architecture**: See `.copilot-instructions.md` for project context