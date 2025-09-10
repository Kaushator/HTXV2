# HTX Interface v2 - OpenAPI Specification

## Quick Access

- **📄 OpenAPI Spec**: [`openapi.json`](openapi.json)
- **📖 Sync Guide**: [`openapi-sync-guide.md`](openapi-sync-guide.md)
- **🔄 Live Docs**: `http://localhost:8000/docs` (when backend running)

## API Overview

**HTX Interface v2 API** provides comprehensive cryptocurrency data and ML analytics:

- **🏷️ Title**: HTX Interface v2 API
- **📝 Version**: 0.1.0
- **🔌 OpenAPI**: 3.1.0  
- **📊 Endpoints**: 20

## Quick Start

### View Documentation
```bash
# Start backend server
cd backend
uvicorn app.main:app --reload --port 8000

# Open browser to:
# http://localhost:8000/docs (Swagger UI)
# http://localhost:8000/redoc (ReDoc)
```

### Update OpenAPI Spec
```bash
cd backend
python export_openapi.py
```

### Validate Spec
```bash
npx @apidevtools/swagger-parser validate docs/openapi.json
```

## API Categories

### 📈 Market Data
- HTX ticker data (`/api/data/htx/ticker/{symbol}`)
- CoinGecko coin info (`/api/data/coingecko/coin/{coin_id}`)

### 🔄 Real-time
- WebSocket ticker subscriptions (`/ws/ticker`)

### 📁 File Operations  
- Signed upload URLs (`/api/uploads/*`)

### 📰 News & Analytics
- CryptoPanic news (`/api/news/cryptopanic`)
- ML predictions (`/api/llm/predict`)

### 🔑 API Management
- API key operations (`/api/keys/*`)

### 🏥 System
- Health checks (`/health`)
- Metrics (`/metrics`)

## Integration

### Frontend Client Generation
```bash
# Generate TypeScript types
npm run api:generate

# Use typed client
import { createApiClient } from '@/types/client'
const api = createApiClient()
const ticker = await api.get('/api/data/htx/ticker/{symbol}', {
  path: { symbol: 'BTCUSDT' }
})
```

### Postman Collection
Import `docs/openapi.json` into Postman for instant API testing.

### API Testing
Use the OpenAPI spec for automated testing and validation.

---

For detailed synchronization instructions and best practices, see [`openapi-sync-guide.md`](openapi-sync-guide.md).
