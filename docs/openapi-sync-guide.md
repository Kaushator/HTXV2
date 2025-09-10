# OpenAPI Synchronization Guide

This guide explains how to keep the OpenAPI specification (`docs/openapi.json`) synchronized with the HTX Backend API.

## Overview

The HTX Backend API automatically generates OpenAPI 3.1.0 specification using FastAPI's built-in OpenAPI support. This specification provides:

- **Complete API Documentation** - All endpoints, parameters, and response schemas
- **Interactive API Explorer** - Swagger UI for testing endpoints
- **Client Code Generation** - Generate clients for various programming languages
- **API Validation** - Ensure consistency between implementation and documentation

## Current API Status

```json
{
  "title": "HTX Interface v2 API",
  "description": "Backend API for HTX cryptocurrency trading platform with ML analytics",
  "version": "0.1.0",
  "openapi": "3.1.0",
  "endpoints": 20
}
```

## Automatic Synchronization

### 1. Export Script

Use the provided export script to update the OpenAPI specification:

```bash
# From backend directory
cd backend
python export_openapi.py
```

**Output:**
```
✅ OpenAPI specification exported to: docs/openapi.json
📊 Endpoints found: 20
🏷️ API Title: HTX Interface v2 API
📝 API Version: 0.1.0
```

### 2. Manual Export via API

Start the backend server and export directly:

```bash
# Start backend server
cd backend
uvicorn app.main:app --reload --port 8000

# Export OpenAPI JSON
curl http://localhost:8000/openapi.json > ../docs/openapi.json
```

### 3. Interactive Documentation

Access live documentation while server is running:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## Synchronization Workflow

### Development Workflow

1. **Make API Changes** - Add/modify endpoints in FastAPI
2. **Test Locally** - Verify changes work correctly
3. **Export OpenAPI** - Run `python export_openapi.py`
4. **Commit Changes** - Include both code and `docs/openapi.json` in PR
5. **Review Documentation** - Ensure API docs are accurate

### CI/CD Integration

Add OpenAPI validation to GitHub Actions:

```yaml
# .github/workflows/ci.yml
- name: Validate OpenAPI Sync
  run: |
    cd backend
    python export_openapi.py
    git diff --exit-code ../docs/openapi.json || {
      echo "❌ OpenAPI spec is out of sync!"
      echo "Run: cd backend && python export_openapi.py"
      exit 1
    }
```

## API Endpoints Overview

### Market Data APIs
- `GET /api/data/htx/ticker/{symbol}` - HTX market ticker data
- `GET /api/data/coingecko/coin/{coin_id}` - CoinGecko coin information

### WebSocket APIs  
- `WS /ws/ticker` - Real-time ticker subscriptions

### Upload APIs
- `POST /api/uploads/request` - Request signed upload URL
- `POST /api/uploads/confirm` - Confirm upload completion
- `GET /api/uploads/{upload_id}/status` - Check upload status

### News APIs
- `GET /api/news/cryptopanic` - Cryptocurrency news from CryptoPanic
- `GET /api/news/search` - Search news articles

### LLM/AI APIs
- `POST /api/llm/predict` - ML model predictions
- `GET /api/llm/models` - Available models

### API Keys Management
- `POST /api/keys/create` - Create new API key
- `GET /api/keys/list` - List user API keys
- `DELETE /api/keys/{key_id}` - Revoke API key

### System APIs
- `GET /health` - System health check
- `GET /metrics` - Prometheus metrics

## OpenAPI Features

### Request/Response Schemas

All endpoints include comprehensive schemas:

```json
{
  "components": {
    "schemas": {
      "TickerResponse": {
        "type": "object",
        "properties": {
          "symbol": {"type": "string"},
          "price": {"type": "number"},
          "change_24h": {"type": "number"},
          "volume_24h": {"type": "number"}
        }
      }
    }
  }
}
```

### Error Response Documentation

Standard error responses across all endpoints:

```json
{
  "responses": {
    "422": {
      "description": "Validation Error",
      "content": {
        "application/json": {
          "schema": {"$ref": "#/components/schemas/HTTPValidationError"}
        }
      }
    }
  }
}
```

### Security Schemes

API key authentication documented:

```json
{
  "components": {
    "securitySchemes": {
      "APIKeyQuery": {
        "type": "apiKey",
        "in": "query",
        "name": "api_key"
      }
    }
  }
}
```

## Best Practices

### 1. Keep Documentation Current

- **Update on API Changes** - Always export after modifying endpoints
- **Version Bumping** - Update API version in `backend/app/main.py` for breaking changes
- **Description Updates** - Keep endpoint descriptions accurate and helpful

### 2. Validation

```bash
# Validate OpenAPI spec syntax
npx @apidevtools/swagger-parser validate docs/openapi.json

# Check for breaking changes
npx @apidevtools/swagger-diff docs/openapi-old.json docs/openapi.json
```

### 3. Client Generation

Generate client libraries from the OpenAPI spec:

```bash
# TypeScript client for frontend
npx @openapitools/openapi-generator-cli generate \
  -i docs/openapi.json \
  -g typescript-fetch \
  -o frontend/src/api/generated

# Python client
pip install openapi-generator-cli
openapi-generator generate \
  -i docs/openapi.json \
  -g python \
  -o clients/python
```

## Integration with Development Tools

### VS Code Extensions

- **OpenAPI (Swagger) Editor** - Edit and preview OpenAPI specs
- **REST Client** - Test endpoints directly from OpenAPI spec

### Postman Integration

Import OpenAPI spec into Postman:

1. Open Postman
2. Click "Import" → "File" → Select `docs/openapi.json`
3. Collection with all endpoints will be created

### API Testing

Use OpenAPI spec for automated testing:

```python
# pytest with openapi-core
from openapi_core import create_spec
from openapi_core.validation.request.validators import RequestValidator

spec = create_spec("docs/openapi.json")
validator = RequestValidator(spec)
```

## Troubleshooting

### Common Issues

**Import Errors During Export:**
```bash
# Install missing dependencies
pip install fastapi uvicorn sqlalchemy asyncpg redis
```

**Schema Generation Issues:**
```python
# Ensure proper Pydantic models
from pydantic import BaseModel

class TickerResponse(BaseModel):
    symbol: str
    price: float
    change_24h: float
```

**Outdated Documentation:**
```bash
# Check if export script ran successfully
python export_openapi.py
echo $?  # Should be 0 for success
```

## Maintenance Schedule

### Weekly Tasks
- [ ] Verify OpenAPI spec is current
- [ ] Test generated documentation links
- [ ] Validate example requests/responses

### Release Tasks
- [ ] Export latest OpenAPI specification
- [ ] Update API version if needed
- [ ] Generate updated client libraries
- [ ] Update integration documentation

## Version History

- **v0.1.0** - Initial API specification with 20 endpoints
- **Future** - Planned versioning strategy for breaking changes

---

**Last Updated**: September 9, 2025  
**OpenAPI Version**: 3.1.0  
**API Version**: 0.1.0  
**Endpoints**: 20
