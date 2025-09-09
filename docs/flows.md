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

## GCS Upload Flow with Signed URLs

This diagram shows the secure file upload process using Google Cloud Storage signed URLs.

```mermaid
sequenceDiagram
    participant Client as Frontend Client
    participant API as FastAPI Server
    participant GCS as Google Cloud Storage
    participant Validator as File Validator
    participant DB as Database

    Client->>API: POST /api/uploads/request
    Note over Client,API: Request includes: filename, file_size, content_type
    
    API->>Validator: Validate file metadata
    Validator->>Validator: Check file size < 100MB
    Validator->>Validator: Check allowed extensions
    Validator->>Validator: Check content type
    
    alt Validation failed
        Validator->>API: Validation error
        API->>Client: 400 Bad Request
    else Validation passed
        Validator->>API: Validation OK
        API->>GCS: Generate signed URL
        GCS->>API: Signed URL (15min TTL)
        API->>DB: Log upload request
        API->>Client: 200 OK with signed URL
        
        Note over Client: Direct upload to GCS
        Client->>GCS: PUT file to signed URL
        GCS->>Client: Upload confirmation
        
        Note over Client: Confirm upload completion
        Client->>API: POST /api/uploads/confirm
        API->>DB: Update upload status
        API->>Client: 200 Upload confirmed
    end
```

## Enhanced WebSocket Flow with Reconnection

This diagram shows the enhanced WebSocket flow with exponential backoff and UX improvements.

```mermaid
sequenceDiagram
    participant UI as React UI
    participant Hook as useWebSocket Hook
    participant WS as WebSocket Connection
    participant Server as Backend Server
    participant Status as ConnectionStatus Component

    UI->>Hook: Initialize connection
    Hook->>Status: Update status: "connecting"
    Hook->>WS: new WebSocket(url)
    
    alt Connection successful
        WS->>Hook: onopen event
        Hook->>Status: Update status: "connected"
        Hook->>UI: Connection ready
        
        Note over UI,Server: Normal operation
        UI->>Hook: sendMessage(data)
        Hook->>WS: ws.send(data)
        WS->>Server: Message delivered
        Server->>WS: Response data
        WS->>Hook: onmessage event
        Hook->>UI: Update with new data
        
    else Connection failed
        WS->>Hook: onerror/onclose event
        Hook->>Status: Update status: "reconnecting"
        Hook->>Hook: Start exponential backoff
        
        Note over Hook: Reconnection logic
        loop Retry attempts (max 5)
            Hook->>Hook: Wait interval (1s, 1.5s, 2.25s...)
            Hook->>Status: Update countdown timer
            Hook->>WS: Attempt reconnection
            
            alt Reconnection successful
                WS->>Hook: onopen event
                Hook->>Status: Update status: "connected"
                Hook->>Hook: Reset retry counter
            else Reconnection failed
                Hook->>Hook: Increment retry counter
                Hook->>Hook: Increase backoff interval
            end
        end
        
        alt Max retries exceeded
            Hook->>Status: Update status: "error"
            Hook->>UI: Show manual reconnect option
        end
    end
    
    Note over UI: Manual reconnection
    UI->>Status: Click reconnect button
    Status->>Hook: triggerReconnect()
    Hook->>Hook: Reset counters and retry
```

## Advanced Error Handling and Recovery Flow

This comprehensive diagram shows error handling across different system layers.

```mermaid
flowchart TD
    A[Incoming Request] --> B{Request Type}
    B -->|HTTP API| C[HTTP Handler]
    B -->|WebSocket| D[WebSocket Handler]
    
    C --> E{HTX API Call}
    D --> E
    
    E -->|Success| F[Process Response]
    E -->|Network Timeout| G[Network Error Handler]
    E -->|Rate Limited 429| H[Rate Limit Handler]
    E -->|Server Error 5xx| I[Server Error Handler]
    E -->|Invalid Data| J[Data Error Handler]
    
    G --> K{Retry Attempt < 3?}
    K -->|Yes| L[Exponential Backoff]
    K -->|No| M[Use Fallback Strategy]
    L --> N[Wait: 1s * 2^attempt]
    N --> E
    
    H --> O[Parse Rate Limit Headers]
    O --> P[Wait Until Reset Time]
    P --> E
    
    I --> Q{Server Error Type}
    Q -->|502/503| R[Temporary Error - Retry]
    Q -->|500| S[Log Error - Use Cache]
    R --> K
    S --> T{Cache Available?}
    
    J --> U[Log Invalid Data]
    U --> T
    
    T -->|Yes| V[Return Stale Data + Warning]
    T -->|No| W[Return Error Response]
    
    M --> X{Fallback Options}
    X -->|Cache Available| V
    X -->|Alternative API| Y[Try Alternative Source]
    X -->|No Options| W
    
    Y --> Z{Alternative Success?}
    Z -->|Yes| F
    Z -->|No| W
    
    F --> AA[Update Cache]
    AA --> BB[Return Success Response]
    
    V --> CC[Log Degraded Service]
    W --> DD[Log Service Failure]
    
    style BB fill:#90EE90
    style V fill:#FFFFE0
    style W fill:#FFB6C1
    style CC fill:#FFA500
    style DD fill:#FF6B6B
```

## WebSocket Connection State Machine

This detailed state machine shows all possible WebSocket connection states and transitions.

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    Idle --> Connecting: connect()
    Connecting --> Connected: WebSocket.onopen
    Connecting --> Failed: WebSocket.onerror
    
    Connected --> Disconnected: Manual disconnect()
    Connected --> Reconnecting: Connection lost
    Connected --> Failed: WebSocket.onerror
    
    Failed --> Reconnecting: Auto-retry enabled
    Failed --> Error: Max retries exceeded
    Failed --> Idle: Manual reset
    
    Reconnecting --> Connected: Reconnection successful
    Reconnecting --> Failed: Reconnection failed
    Reconnecting --> Error: Max retries exceeded
    
    Error --> Connecting: Manual reconnect()
    Error --> Idle: Reset connection
    
    Disconnected --> Connecting: Reconnect request
    Disconnected --> Idle: Reset to initial state
    
    note right of Connecting
        - Show loading indicator
        - Disable user actions
        - Timeout after 10s
    end note
    
    note right of Connected
        - Enable all features
        - Active message exchange
        - Monitor connection health
    end note
    
    note right of Reconnecting
        - Show reconnection status
        - Display countdown timer
        - Exponential backoff delay
        - Track retry attempts
    end note
    
    note right of Error
        - Show error message
        - Offer manual reconnect
        - Log error details
        - Disable auto-retry
    end note
```

## System Integration and Data Flow Architecture

This high-level diagram shows the complete system architecture and data flow.

```mermaid
graph TB
    subgraph "Frontend Layer"
        A[React App] 
        B[WebSocket Client]
        C[HTTP Client]
        D[State Management]
    end
    
    subgraph "API Gateway Layer"
        E[FastAPI Server]
        F[WebSocket Server]
        G[Rate Limiter]
        H[Auth Middleware]
    end
    
    subgraph "Service Layer"
        I[HTX Service]
        J[Upload Service] 
        K[News Service]
        L[LLM Service]
    end
    
    subgraph "Cache Layer"
        M[Redis Cache]
        N[Cache Manager]
        O[TTL Policies]
    end
    
    subgraph "External APIs"
        P[HTX Exchange API]
        Q[Google Cloud Storage]
        R[CryptoPanic API]
        S[FinGPT Service]
    end
    
    subgraph "Database Layer"
        T[(PostgreSQL)]
        U[Alembic Migrations]
        V[Connection Pool]
    end
    
    subgraph "Monitoring"
        W[Prometheus Metrics]
        X[Grafana Dashboards]
        Y[Alert Manager]
        Z[Health Checks]
    end
    
    A --> B
    A --> C
    A --> D
    
    B --> F
    C --> E
    
    E --> G
    E --> H
    F --> G
    F --> H
    
    E --> I
    E --> J
    E --> K
    E --> L
    F --> I
    
    I --> M
    J --> M
    K --> M
    L --> M
    
    M --> N
    N --> O
    
    I --> P
    J --> Q
    K --> R
    L --> S
    
    I --> T
    J --> T
    K --> T
    T --> U
    T --> V
    
    E --> W
    F --> W
    I --> W
    W --> X
    X --> Y
    E --> Z
    
    style A fill:#E1F5FE
    style E fill:#E8F5E8
    style I fill:#FFF3E0
    style M fill:#F3E5F5
    style P fill:#FFEBEE
    style T fill:#E0F2F1
    style W fill:#FFF8E1
```

---

## Notes

- All diagrams use standard Mermaid syntax and should render properly in GitHub
- WebSocket connections implement automatic reconnection with exponential backoff (1s → 30s max)
- HTTP API includes comprehensive rate limiting and retry mechanisms
- GCS uploads use signed URLs for secure, direct-to-cloud file transfers
- Caching strategy with intelligent TTL policies reduces external API load
- Error handling ensures graceful degradation with multiple fallback strategies
- Enhanced UX provides clear connection status and manual recovery options
- Monitoring infrastructure provides comprehensive observability across all layers
- State machines ensure predictable connection behavior and user experience
