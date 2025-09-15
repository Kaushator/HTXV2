# HTXV2 AI Tool Optimization Guide

## 🤖 Container Development with AI Assistance

### Token-Optimized Prompts for Large Files

#### Backend MCP Service (327 lines)
```python
# @codex: КОНТЕКСТ: HTXV2 MCP (Master Control Program) - центральный сервис оркестрации
# ФАЙЛ: backend/app/services/mcp_service.py
# ЦЕЛЬ: WebSocket управление, health checks, task orchestration
# ПАТТЕРН: Async service class с Redis pub/sub и SQLAlchemy

# ТЕКУЩИЕ МЕТОДЫ:
# - initialize() - Redis/DB подключения  
# - check_system_health() - проверка всех сервисов
# - manage_websocket_connections() - управление WS соединениями
# - orchestrate_data_flow() - координация ETL процессов
# - handle_market_data() - обработка рыночных данных

# @codex: Разбей задачу на методы по 20-30 строк максимум
```

#### WebSocket Endpoints (309 lines) 
```python
# @codex: КОНТЕКСТ: HTXV2 WebSocket API endpoints
# ФАЙЛ: backend/app/api/api_v1/endpoints/websocket.py  
# ЦЕЛЬ: Real-time market data, portfolio updates, trading signals
# ПАТТЕРН: FastAPI WebSocket с asyncio и rate limiting

# ЭНДПОЙНТЫ:
# - /ws/market-data/{symbol} - рыночные данные
# - /ws/portfolio/{user_id} - обновления портфеля  
# - /ws/trading-signals - торговые сигналы
# - /ws/mcp - системные события

# @codex: Оптимизируй connection handling и error recovery
```

#### MCP API Endpoints (343 lines)
```python
# @codex: КОНТЕКСТ: HTXV2 MCP REST API 
# ФАЙЛ: backend/app/api/api_v1/endpoints/mcp.py
# ЦЕЛЬ: Health checks, task management, system control
# ПАТТЕРН: FastAPI router с async handlers

# ЭНДПОЙНТЫ:
# - GET /health - системное здоровье
# - GET /tasks - статус задач
# - POST /tasks - создание задач
# - GET /metrics - метрики производительности

# @codex: Добавь endpoint documentation и схемы Pydantic
```

### Token Optimization Strategies

#### 1. File Splitting Recommendations
- **mcp_service.py**: Split into:
  - `mcp_core.py` (base class, initialization)
  - `mcp_websocket.py` (WebSocket management)  
  - `mcp_health.py` (health checks)
  - `mcp_orchestration.py` (task orchestration)

#### 2. Context Templates for Common Tasks

##### FastAPI Endpoint Creation
```python
# @codex: КОНТЕКСТ: HTXV2 FastAPI endpoint
# ТЕХНОЛОГИИ: FastAPI, async SQLAlchemy, Pydantic, Redis
# ЦЕЛЬ: {describe_purpose}
# АУТЕНТИФИКАЦИЯ: JWT Bearer tokens
# ОШИБКИ: HTTPException с детальными сообщениями
# ЛОГИРОВАНИЕ: structlog с request_id correlation

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user
from app.core.rate_limit import rate_limiter
from app.db.session import get_async_db
from app.schemas.{module} import {Schema}Response

router = APIRouter(prefix="/{endpoint}", tags=["{tag}"])

@router.{method}("/{path}")
@rate_limiter(max_requests=100, time_window=60)
async def {function_name}(
    # @codex: добавь параметры и dependencies
    db: AsyncSession = Depends(get_async_db)
):
    """
    {Endpoint description}
    
    - **param**: description
    - **returns**: {Schema}Response
    """
    # @codex: реализация endpoint логики
```

##### React Component (Frontend)
```typescript
// @cursor: КОНТЕКСТ: HTXV2 frontend компонент
// ТЕХНОЛОГИИ: Next.js, TypeScript, shadcn/ui, TanStack Query, Zustand
// ЦЕЛЬ: {describe_purpose}
// ПАТТЕРН: Server component с client interactions

import { useState, useEffect } from 'react'
import { useQuery, useMutation } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface {ComponentName}Props {
  // @cursor: типизированные props
}

export function {ComponentName}({ ...props }: {ComponentName}Props) {
  // @cursor: component state и query hooks
  
  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        {/* @cursor: component content */}
      </CardContent>
    </Card>
  )
}
```

#### 3. Container Optimization Prompts

##### Docker Build Optimization
```bash
# @codex: КОНТЕКСТ: HTXV2 Docker optimization
# ФАЙЛ: docker/{service}.Dockerfile  
# ЦЕЛЬ: Минимизация размера образа и время сборки
# ПРОБЛЕМЫ: SSL cert issues, layer caching, security

# ОПТИМИЗАЦИИ:
# 1. Multi-stage builds для prod/dev
# 2. .dockerignore для node_modules, .git
# 3. Security: non-root user, minimal packages
# 4. Health checks с appropriate timeouts
# 5. Layer caching для dependencies

# @codex: Исправь SSL проблемы и оптимизируй кэширование
```

##### Development Workflow
```bash
# @codex: КОНТЕКСТ: HTXV2 local development
# ЦЕЛЬ: Fast reload, debugging, efficient resource usage
# ПРОБЛЕМЫ: Hot reload conflicts, port conflicts, volume mounting

# КОМАНДЫ:
# make setup - первоначальная настройка
# make dev-all - запуск frontend + backend 
# make lint-all - проверка кода
# make test-all - запуск тестов

# @codex: Настрой эффективный dev workflow с hot reload
```

### Token Budget Management

#### Large File Analysis (>10KB identified):
1. **test_integration.py** (10.9KB) - Split into modules
2. **scripts/token-optimizer.py** (10.5KB) - Already optimized
3. **backend/app/services/mcp_service.py** (11.8KB) - Split as above
4. **backend/app/api/api_v1/endpoints/mcp.py** (11.2KB) - Documented
5. **backend/app/api/api_v1/endpoints/websocket.py** (10.4KB) - Optimized

#### Context Optimization Rules:
- **Files < 300 lines**: Send complete for context
- **Files 300-500 lines**: Send with focused prompts  
- **Files > 500 lines**: Split into logical modules
- **Use @cursor/@codex**: Comments for targeted assistance
- **Templates**: Pre-built patterns for common tasks

### AI Assistant Configuration

#### Cursor (Frontend)
```json
{
  "rules": [
    "Use TypeScript strict mode",
    "Prefer server components when possible", 
    "Use shadcn/ui components consistently",
    "Implement loading states and error boundaries",
    "Follow HTXV2 design system colors and spacing"
  ],
  "patterns": {
    "component": "/docs/templates/react-component.tsx",
    "page": "/docs/templates/next-page.tsx", 
    "hook": "/docs/templates/react-hook.ts"
  }
}
```

#### Codex (Backend)  
```json
{
  "rules": [
    "Use async/await for all I/O operations",
    "Include proper error handling with HTTPException",
    "Add request_id correlation for logging",
    "Use dependency injection for database sessions",
    "Follow FastAPI best practices for validation"
  ],
  "patterns": {
    "endpoint": "/docs/templates/fastapi-endpoint.py",
    "service": "/docs/templates/async-service.py",
    "schema": "/docs/templates/pydantic-schema.py"
  }
}
```

### Performance Optimization

#### Container Resource Limits
```yaml
# docker-compose.yml optimizations
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:  
          memory: 256M
          cpus: '0.25'
    healthcheck:
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
      
  frontend:
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.3'
```

#### Build Cache Optimization
```dockerfile
# Multi-stage build for better caching
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS builder  
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
# Final production image
```

### Deployment Checklist

#### Pre-deployment Token Analysis
- [ ] All files < 10KB (for efficient AI assistance)
- [ ] Context comments @cursor/@codex added
- [ ] Repetitive code extracted to utils/helpers  
- [ ] Types and interfaces in separate files
- [ ] Documentation updated with examples

#### Container Health Checks
- [ ] Backend: FastAPI /health endpoint responds < 5s
- [ ] Frontend: Next.js pages load < 3s
- [ ] Database: PostgreSQL connection pool healthy
- [ ] Redis: Cache hit rate > 80%  
- [ ] WebSocket: Connection stability > 95%

#### Security & Performance  
- [ ] No secrets in environment variables or logs
- [ ] Rate limiting enabled on all public endpoints
- [ ] CORS properly configured for production
- [ ] Container resource limits set appropriately
- [ ] Health checks with reasonable timeouts

### Troubleshooting Common Issues

#### SSL Certificate Problems
```dockerfile
# Fix for SSL issues in Alpine containers
RUN apk add --no-cache ca-certificates && update-ca-certificates
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
```

#### Volume Mount Issues
```yaml
# Proper volume configuration for development
volumes:
  - ../backend:/app
  - /app/__pycache__  # Exclude cache
  - backend_venv:/app/venv  # Persist virtual env
```

#### Hot Reload Problems
```json
// Next.js config for container development
{
  "experimental": {
    "outputFileTracingRoot": path.join(__dirname, "../../")
  },
  "watchOptions": {
    "poll": 1000,
    "aggregateTimeout": 300
  }
}
```