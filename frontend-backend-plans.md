# Frontend-Backend Integration Plans

## Overview
This document outlines the integration strategies and configurations for coordinating the HTXV2 frontend (Next.js) and backend (FastAPI) components.

## API Configuration

### Backend API Endpoints
```yaml
Base URL: http://localhost:8000/api/v1
Production URL: https://api.htxv2.com/api/v1

Core Endpoints:
  Authentication:
    - POST /auth/login
    - POST /auth/logout
    - POST /auth/refresh
    - POST /auth/register
    
  Trading:
    - GET /trading/markets
    - GET /trading/tickers
    - POST /trading/orders
    - GET /trading/orders/{order_id}
    - DELETE /trading/orders/{order_id}
    
  Portfolio:
    - GET /portfolio/positions
    - GET /portfolio/balance
    - GET /portfolio/history
    
  Market Data:
    - GET /market/prices
    - GET /market/charts/{symbol}
    - GET /market/orderbook/{symbol}
    
  ML/AI Analysis:
    - POST /analysis/signals
    - GET /analysis/predictions/{symbol}
    - POST /analysis/sentiment
```

### Frontend API Integration
```typescript
// API Configuration
const API_CONFIG = {
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1',
  timeout: 30000,
  retries: 3,
  retryDelay: 1000
};

// WebSocket Configuration
const WS_CONFIG = {
  url: process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/ws',
  reconnectInterval: 5000,
  maxReconnectAttempts: 10
};
```

## Authentication Strategy

### JWT Token Management
```typescript
// Token Storage Strategy
interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

// Token Refresh Logic
const TOKEN_REFRESH_THRESHOLD = 300; // 5 minutes before expiry
```

### Security Headers
```yaml
CORS Configuration:
  - http://localhost:3000
  - https://htxv2.com
  - https://app.htxv2.com

Security Headers:
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - X-XSS-Protection: 1; mode=block
  - Strict-Transport-Security: max-age=31536000
```

## Real-time Data Integration

### WebSocket Channels
```yaml
Market Data Channels:
  - ticker.{symbol}
  - orderbook.{symbol}
  - trades.{symbol}
  - kline.{symbol}.{interval}

Portfolio Channels:
  - portfolio.{user_id}
  - orders.{user_id}
  - notifications.{user_id}

System Channels:
  - system.status
  - system.announcements
```

### State Management
```typescript
// React Query Configuration
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30000, // 30 seconds
      cacheTime: 300000, // 5 minutes
      retry: 3,
      refetchOnWindowFocus: false
    }
  }
});

// Zustand Store Configuration
interface AppState {
  auth: AuthState;
  market: MarketState;
  portfolio: PortfolioState;
  ui: UIState;
}
```

## Environment Configuration

### Development Environment
```bash
# Frontend (.env.local)
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws
NEXT_PUBLIC_ENVIRONMENT=development
NEXT_PUBLIC_ENABLE_DEVTOOLS=true

# Backend (.env)
DATABASE_URL=postgresql+asyncpg://htxv2_user:password@localhost:5432/htxv2
REDIS_URL=redis://localhost:6379/0
CORS_ORIGINS=["http://localhost:3000"]
```

### Production Environment
```bash
# Frontend (.env.production)
NEXT_PUBLIC_API_URL=https://api.htxv2.com/api/v1
NEXT_PUBLIC_WS_URL=wss://api.htxv2.com/ws
NEXT_PUBLIC_ENVIRONMENT=production
NEXT_PUBLIC_ENABLE_DEVTOOLS=false

# Backend (.env.production)
DATABASE_URL=postgresql+asyncpg://username:password@prod-db:5432/htxv2
REDIS_URL=redis://prod-redis:6379/0
CORS_ORIGINS=["https://htxv2.com", "https://app.htxv2.com"]
```

## Data Flow Patterns

### Request/Response Pattern
```typescript
// API Client with Error Handling
class ApiClient {
  async request<T>(
    endpoint: string,
    options: RequestOptions = {}
  ): Promise<ApiResponse<T>> {
    try {
      const response = await fetch(`${API_CONFIG.baseURL}${endpoint}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getAccessToken()}`,
          ...options.headers
        }
      });
      
      if (!response.ok) {
        throw new ApiError(response.status, await response.text());
      }
      
      return await response.json();
    } catch (error) {
      throw new ApiError(500, error.message);
    }
  }
}
```

### Real-time Data Pattern
```typescript
// WebSocket Manager
class WebSocketManager {
  private connection: WebSocket | null = null;
  private subscriptions: Map<string, Set<Function>> = new Map();
  
  connect(): void {
    this.connection = new WebSocket(WS_CONFIG.url);
    this.setupEventHandlers();
  }
  
  subscribe(channel: string, callback: Function): void {
    if (!this.subscriptions.has(channel)) {
      this.subscriptions.set(channel, new Set());
      this.send({ type: 'subscribe', channel });
    }
    this.subscriptions.get(channel)!.add(callback);
  }
}
```

## Error Handling Strategy

### Frontend Error Boundaries
```typescript
// Global Error Handler
const errorHandler = (error: Error, errorInfo: ErrorInfo) => {
  console.error('Application Error:', error, errorInfo);
  
  // Send to monitoring service
  if (process.env.NODE_ENV === 'production') {
    trackError(error, {
      component: errorInfo.componentStack,
      timestamp: new Date().toISOString()
    });
  }
};
```

### Backend Error Responses
```python
# Standardized Error Response Format
class ErrorResponse(BaseModel):
    error: str
    message: str
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime
    request_id: str
```

## Performance Optimization

### Frontend Optimization
```typescript
// Code Splitting Strategy
const TradingPage = lazy(() => import('@/pages/trading'));
const PortfolioPage = lazy(() => import('@/pages/portfolio'));
const AnalysisPage = lazy(() => import('@/pages/analysis'));

// Caching Strategy
const CACHE_KEYS = {
  market_data: 'market_data',
  portfolio: 'portfolio',
  user_preferences: 'user_preferences'
};
```

### Backend Optimization
```python
# Redis Caching Configuration
CACHE_SETTINGS = {
    "market_data": {"ttl": 30, "key_prefix": "market:"},
    "portfolio": {"ttl": 300, "key_prefix": "portfolio:"},
    "analysis": {"ttl": 600, "key_prefix": "analysis:"}
}

# Database Connection Pool
DATABASE_POOL_SETTINGS = {
    "pool_size": 20,
    "max_overflow": 30,
    "pool_timeout": 30,
    "pool_recycle": 3600
}
```

## Monitoring and Logging

### Frontend Monitoring
```typescript
// Performance Monitoring
const performanceObserver = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.entryType === 'navigation') {
      trackPerformance('page_load', entry.duration);
    }
  }
});

// User Action Tracking
const trackUserAction = (action: string, metadata: Record<string, any>) => {
  analytics.track(action, {
    ...metadata,
    timestamp: Date.now(),
    sessionId: getSessionId()
  });
};
```

### Backend Monitoring
```python
# Structured Logging
import structlog

logger = structlog.get_logger()

# Request Middleware
async def logging_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        "api_request",
        method=request.method,
        url=str(request.url),
        status_code=response.status_code,
        process_time=process_time
    )
    
    return response
```

## Testing Strategy

### Frontend Testing
```typescript
// API Mocking for Tests
const mockApiResponses = {
  '/auth/login': { access_token: 'mock_token', user: mockUser },
  '/portfolio/positions': { positions: mockPositions },
  '/market/prices': { prices: mockPrices }
};

// Component Testing
describe('TradingComponent', () => {
  it('should display market data correctly', async () => {
    render(<TradingComponent />);
    expect(await screen.findByText('BTC/USDT')).toBeInTheDocument();
  });
});
```

### Backend Testing
```python
# API Integration Tests
class TestTradingAPI:
    async def test_create_order(self, client: AsyncClient):
        order_data = {
            "symbol": "BTCUSDT",
            "side": "buy",
            "quantity": "0.001",
            "price": "50000"
        }
        
        response = await client.post("/api/v1/trading/orders", json=order_data)
        assert response.status_code == 201
        assert response.json()["symbol"] == "BTCUSDT"
```

## Deployment Coordination

### Docker Configuration
```yaml
# docker-compose.yml
version: '3.8'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000/api/v1
    depends_on:
      - backend
      
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://user:pass@postgres:5432/htxv2
    depends_on:
      - postgres
      - redis
```

### CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy HTXV2
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Test Frontend
        run: cd frontend && npm test
      - name: Test Backend
        run: cd backend && pytest
        
  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy htxv2-backend --source ./backend
          gcloud run deploy htxv2-frontend --source ./frontend
```

## Feature Flags and Configuration

### Frontend Feature Flags
```typescript
const FEATURE_FLAGS = {
  ENABLE_ADVANCED_TRADING: process.env.NEXT_PUBLIC_ENABLE_ADVANCED_TRADING === 'true',
  ENABLE_AI_ANALYSIS: process.env.NEXT_PUBLIC_ENABLE_AI_ANALYSIS === 'true',
  ENABLE_REAL_TIME_CHAT: process.env.NEXT_PUBLIC_ENABLE_CHAT === 'true'
};
```

### Backend Feature Configuration
```python
class Settings(BaseSettings):
    # Trading Features
    enable_paper_trading: bool = True
    enable_live_trading: bool = False
    enable_margin_trading: bool = False
    
    # AI Features
    enable_local_llm: bool = True
    enable_vertex_ai: bool = True
    enable_openai_fallback: bool = True
    
    # Data Sources
    enable_htx_data: bool = True
    enable_coingecko_data: bool = True
    enable_cryptopanic_data: bool = True
```