# Master Control Program (MCP) Server

The MCP server is the central orchestration and monitoring system for the HTXV2 platform. It provides real-time communication, system health monitoring, and task management capabilities.

## Features

### 🔌 Real-time Communication
- WebSocket endpoint for bidirectional client-server communication
- Authenticated connections with JWT token validation
- Real-time broadcasting of market data, trading signals, and portfolio updates
- Connection management with automatic cleanup

### 🏥 System Health Monitoring
- Comprehensive health checks for all critical dependencies:
  - PostgreSQL database
  - Redis cache
  - HTX API
  - CoinGecko API
- Response time tracking
- Automatic degraded service detection
- Real-time health status updates

### 📋 Task Orchestration
- Background task scheduling and management
- Task status tracking and monitoring
- Redis-based task persistence
- Integration ready for Celery workers

### 🔐 Security & Authentication
- JWT-based authentication for all endpoints
- WebSocket connection authentication
- Role-based access control (superuser permissions for broadcasting)
- User-specific data isolation

## API Endpoints

### Health Monitoring
```
GET /api/v1/mcp/health
```
Returns comprehensive system health status including all monitored services.

**Response:**
```json
{
  "status": "healthy",
  "services": [
    {
      "name": "PostgreSQL",
      "status": "healthy",
      "response_time_ms": 45.2,
      "last_checked": "2025-09-10T07:38:53.947336Z"
    }
  ],
  "timestamp": "2025-09-10T07:38:53.947448Z"
}
```

### Task Management
```
GET /api/v1/mcp/tasks                  # List active tasks
GET /api/v1/mcp/tasks/{task_id}        # Get task status
POST /api/v1/mcp/tasks                 # Schedule new task
```

**Schedule Task Request:**
```json
{
  "task_name": "fetch_crypto_prices",
  "parameters": {
    "symbols": ["BTC", "ETH", "BNB"],
    "interval": "1m"
  },
  "priority": 1
}
```

### Data Broadcasting (Superuser Only)
```
POST /api/v1/mcp/broadcast/market-data      # Broadcast market data
POST /api/v1/mcp/broadcast/trading-signal   # Broadcast trading signals
POST /api/v1/mcp/broadcast/portfolio-update # Broadcast portfolio updates
```

## WebSocket Communication

### Connection
```
ws://localhost:8000/api/v1/mcp/ws
```

### Authentication Flow
1. Connect to WebSocket endpoint
2. Send authentication message:
```json
{
  "type": "auth",
  "token": "your-jwt-token"
}
```
3. Receive authentication confirmation:
```json
{
  "type": "auth_success",
  "message": "Authentication successful",
  "user_id": 123
}
```

### Message Types

**Client → Server:**
- `ping` - Heartbeat/keepalive
- `get_health` - Request current system health
- `get_tasks` - Request active tasks list

**Server → Client:**
- `pong` - Heartbeat response
- `system_health` - Health status updates
- `tasks` - Task list updates
- `market_data` - Real-time market data
- `trading_signal` - Trading signals
- `portfolio_update` - Portfolio changes
- `error` - Error messages

### Example Message Flow
```json
// Client sends ping
{"type": "ping"}

// Server responds with pong
{
  "type": "pong",
  "timestamp": "2025-09-10T07:38:53.948133Z"
}

// Server broadcasts market data
{
  "type": "market_data",
  "data": {
    "symbol": "BTC",
    "price": 45250.67,
    "volume": 1234567.89,
    "change_24h": 2.45,
    "timestamp": "2025-09-10T07:38:53.948218Z"
  },
  "timestamp": "2025-09-10T07:38:53.948246Z"
}
```

## Configuration

Add these settings to your environment configuration:

```python
# MCP Configuration
MCP_TASK_CLEANUP_INTERVAL = 3600       # Task cleanup interval (seconds)
MCP_HEALTH_CHECK_INTERVAL = 60         # Health check interval (seconds)
MCP_MAX_WEBSOCKET_CONNECTIONS = 1000   # Maximum WebSocket connections
MCP_WEBSOCKET_HEARTBEAT_INTERVAL = 30  # WebSocket heartbeat interval (seconds)
```

## Integration Examples

### Client-side WebSocket Integration
```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/mcp/ws');

ws.onopen = () => {
  // Authenticate
  ws.send(JSON.stringify({
    type: 'auth',
    token: localStorage.getItem('jwt_token')
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  
  switch(message.type) {
    case 'market_data':
      updateMarketDisplay(message.data);
      break;
    case 'trading_signal':
      showTradingAlert(message.data);
      break;
    case 'portfolio_update':
      refreshPortfolio(message.data);
      break;
  }
};
```

### Task Scheduling Integration
```python
import httpx

async def schedule_data_collection():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            'http://localhost:8000/api/v1/mcp/tasks',
            json={
                'task_name': 'fetch_crypto_prices',
                'parameters': {'symbols': ['BTC', 'ETH']},
                'priority': 1
            },
            headers={'Authorization': f'Bearer {jwt_token}'}
        )
        return response.json()
```

### Health Monitoring Integration
```python
async def check_system_health():
    async with httpx.AsyncClient() as client:
        response = await client.get(
            'http://localhost:8000/api/v1/mcp/health',
            headers={'Authorization': f'Bearer {jwt_token}'}
        )
        health_data = response.json()
        
        for service in health_data['services']:
            if service['status'] != 'healthy':
                await send_alert(f"Service {service['name']} is {service['status']}")
```

## Architecture

The MCP server follows the existing HTXV2 architecture patterns:

- **Service Layer** (`MCPService`): Core business logic and external integrations
- **API Layer** (`mcp.py`): FastAPI endpoints and WebSocket handling
- **Schema Layer** (`mcp.py`): Pydantic models for data validation
- **Configuration**: Integrated with existing settings system

## Dependencies

The MCP server integrates with existing HTXV2 infrastructure:

- **PostgreSQL**: Database connectivity monitoring
- **Redis**: Task storage and caching
- **External APIs**: HTX and CoinGecko health monitoring
- **Authentication**: JWT token validation
- **WebSockets**: Real-time communication

## Future Enhancements

- Celery worker integration for background task execution
- Advanced metrics collection and alerting
- WebSocket message queuing and delivery guarantees
- Real-time system performance monitoring
- Task scheduling with cron-like expressions