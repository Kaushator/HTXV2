# Data Flow Diagrams

This document describes the data flows and interactions between different components of the HTX Interface system using Mermaid diagrams.

## WebSocket Ticker Flow

This diagram shows the real-time data flow for cryptocurrency ticker updates via WebSocket connection.

```mermaid
sequenceDiagram
    participant Client as Frontend Client
    participant WSServer as WebSocket Server
    participant HTXService as HTX Service
    participant RedisCache as Redis Cache
    participant HTXAPI as HTX API

    Client->>WSServer: Connect to /ws/ticker
    WSServer->>Client: Connection established

    Note over WSServer: Client requests ticker subscription
    Client->>WSServer: Subscribe {"symbol": "BTCUSDT"}
    WSServer->>HTXService: requestTicker("BTCUSDT")
    
    HTXService->>RedisCache: Check cache for BTCUSDT
    alt Cache hit (TTL valid)
        RedisCache->>HTXService: Return cached data
    else Cache miss or expired
        HTXService->>HTXAPI: GET /market/detail/merged
        HTXAPI->>HTXService: Ticker data response
        HTXService->>RedisCache: Store with TTL
    end
    
    HTXService->>WSServer: Ticker data
    WSServer->>Client: Real-time ticker update
    
    Note over WSServer: Periodic updates
    loop Every 5 seconds
        WSServer->>HTXService: Auto-refresh subscribed tickers
        HTXService->>RedisCache: Check cache
        alt Fresh data available
            HTXService->>WSServer: Updated ticker
            WSServer->>Client: Broadcast update
        end
    end
    
    Note over Client: Client disconnects
    Client->>WSServer: Disconnect
    WSServer->>WSServer: Cleanup subscriptions
```

## HTTP API Ticker Flow

This diagram shows the traditional HTTP request-response flow for ticker data.

```mermaid
sequenceDiagram
    participant Client as Frontend/API Client
    participant APIServer as FastAPI Server
    participant HTXService as HTX Service
    participant RedisCache as Redis Cache
    participant HTXAPI as HTX API
    participant RateLimiter as Rate Limiter

    Client->>APIServer: GET /api/data/htx/ticker?symbol=BTCUSDT
    APIServer->>RateLimiter: Check rate limits
    
    alt Rate limit exceeded
        RateLimiter->>APIServer: Rate limit error
        APIServer->>Client: 429 Too Many Requests
    else Rate limit OK
        RateLimiter->>APIServer: Allow request
        APIServer->>HTXService: getTicker("BTCUSDT")
        
        HTXService->>RedisCache: Check cache for BTCUSDT
        alt Cache hit (TTL valid)
            RedisCache->>HTXService: Return cached data
            Note over HTXService: Data is fresh, no API call needed
        else Cache miss or expired
            HTXService->>HTXAPI: GET /market/detail/merged?symbol=btcusdt
            HTXAPI->>HTXService: Raw ticker response
            HTXService->>HTXService: Transform & validate data
            HTXService->>RedisCache: Store with TTL (default 30s)
        end
        
        HTXService->>APIServer: Processed ticker data
        APIServer->>Client: JSON response with ticker
    end
```

## Health Check Flow

This diagram shows the health monitoring and system status checking flow.

```mermaid
flowchart TD
    A[Health Check Request] --> B{Check API Server}
    B -->|OK| C{Check Redis Connection}
    B -->|Fail| J[API Server Down]
    
    C -->|OK| D{Check HTX API}
    C -->|Fail| K[Redis Connection Failed]
    
    D -->|OK| E{Check WebSocket Server}
    D -->|Fail| L[HTX API Unreachable]
    
    E -->|OK| F[All Systems Healthy]
    E -->|Fail| M[WebSocket Server Down]
    
    J --> N[Return 503 Service Unavailable]
    K --> O[Return 503 Cache Unavailable]
    L --> P[Return 503 External API Failed]
    M --> Q[Return 503 WebSocket Failed]
    F --> R[Return 200 OK with Status]
    
    style F fill:#90EE90
    style N fill:#FFB6C1
    style O fill:#FFB6C1
    style P fill:#FFB6C1
    style Q fill:#FFB6C1
```

## Error Handling and Retry Logic

This diagram shows how the system handles errors and implements retry mechanisms.

```mermaid
flowchart TD
    A[API Request] --> B{HTX API Call}
    B -->|Success| C[Return Data]
    B -->|Network Error| D[Retry Logic]
    B -->|Rate Limited| E[Exponential Backoff]
    B -->|Invalid Response| F[Log Error & Use Cache]
    
    D --> G{Retry Count < 3?}
    G -->|Yes| H[Wait 1s * retry_count]
    G -->|No| I[Return Error]
    H --> B
    
    E --> J[Wait rate limit period]
    J --> B
    
    F --> K{Cache Available?}
    K -->|Yes| L[Return Stale Data with Warning]
    K -->|No| M[Return Error]
    
    style C fill:#90EE90
    style I fill:#FFB6C1
    style L fill:#FFFFE0
    style M fill:#FFB6C1
```

## WebSocket Connection Lifecycle

This diagram shows the complete lifecycle of a WebSocket connection.

```mermaid
stateDiagram-v2
    [*] --> Disconnected
    Disconnected --> Connecting: Client initiates connection
    Connecting --> Connected: Handshake successful
    Connecting --> Disconnected: Connection failed
    
    Connected --> Subscribed: Client sends subscription
    Subscribed --> Connected: Unsubscribe request
    
    Connected --> Reconnecting: Connection lost
    Subscribed --> Reconnecting: Connection lost
    Reconnecting --> Connected: Reconnection successful
    Reconnecting --> Disconnected: Max retries exceeded
    
    Connected --> Disconnected: Client disconnect
    Subscribed --> Disconnected: Client disconnect
    
    note right of Subscribed
        Active data streaming
        Periodic updates
        Error handling
    end note
    
    note right of Reconnecting
        Exponential backoff
        Auto-retry logic
        State preservation
    end note
```

## Data Caching Strategy

This diagram illustrates the multi-level caching strategy used in the system.

```mermaid
flowchart LR
    A[Client Request] --> B{Redis Cache}
    B -->|Hit| C[Return Cached Data]
    B -->|Miss| D[HTX API Call]
    
    D --> E[Process Response]
    E --> F[Store in Redis]
    F --> G[Return Fresh Data]
    
    F --> H{TTL Strategy}
    H -->|High Volume Symbol| I[TTL: 10s]
    H -->|Medium Volume Symbol| J[TTL: 30s]
    H -->|Low Volume Symbol| K[TTL: 60s]
    
    I --> L[Redis Expiry]
    J --> L
    K --> L
    L --> M[Next Request Cache Miss]
    
    style C fill:#90EE90
    style G fill:#90EE90
    style L fill:#FFB6C1
```

## Frontend Component Data Flow

This diagram shows how data flows through the React frontend components.

```mermaid
flowchart TD
    A[App Component] --> B[WebSocket Provider]
    B --> C[useWebSocket Hook]
    
    C --> D{Connection Status}
    D -->|Connected| E[Subscribe to Tickers]
    D -->|Disconnected| F[Show Connection Error]
    
    E --> G[Receive Real-time Data]
    G --> H[Update Component State]
    H --> I[TickerCard Component]
    
    I --> J[Display Price]
    I --> K[Display Change %]
    I --> L[Display Volume]
    I --> M[Price Direction Indicator]
    
    A --> N[HTTP API Fallback]
    N --> O[Fetch Initial Data]
    O --> I
    
    style G fill:#90EE90
    style F fill:#FFB6C1
    style I fill:#ADD8E6
```

## Integration with External Systems

This diagram shows how the system integrates with external services and infrastructure.

```mermaid
C4Context
    title System Context Diagram - HTX Interface

    Person(user, "End User", "Crypto trader/investor")
    System(htx_interface, "HTX Interface", "Real-time crypto data platform")
    
    System_Ext(htx_api, "HTX Exchange API", "External crypto exchange")
    System_Ext(redis_cloud, "Redis Cache", "In-memory data store")
    System_Ext(gcp, "Google Cloud Platform", "Cloud infrastructure")
    
    Rel(user, htx_interface, "Views real-time prices", "HTTPS/WSS")
    Rel(htx_interface, htx_api, "Fetches market data", "HTTPS")
    Rel(htx_interface, redis_cloud, "Caches responses", "Redis Protocol")
    Rel(htx_interface, gcp, "Deployed on", "Cloud Run")
```

---

## Notes

- All diagrams use standard Mermaid syntax and should render properly in GitHub
- WebSocket connections implement automatic reconnection with exponential backoff
- HTTP API includes rate limiting to prevent abuse
- Caching strategy reduces external API calls and improves response times
- Error handling ensures graceful degradation when external services are unavailable
- Health checks provide visibility into system status and dependencies
