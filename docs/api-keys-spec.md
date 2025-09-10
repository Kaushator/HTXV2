# API Keys Management Specification

## 1. Общий обзор

Данная спецификация описывает систему управления API ключами для HTX Interface v2, включая модели данных, эндпоинты, политики безопасности, квоты и механизмы аутентификации.

### 1.1. Цели системы
- **Аутентификация**: Secure API access через API keys
- **Авторизация**: Role-based access control (RBAC)  
- **Квотирование**: Per-key rate limiting и usage quotas
- **Аудит**: Tracking API usage и security events
- **Ротация**: Automated key rotation и lifecycle management

### 1.2. Архитектурные принципы
- **Security by Design**: SHA-256 hashing, secure storage
- **Zero-Knowledge**: Сервер не хранит plaintext keys
- **Fault Tolerance**: Graceful degradation при сбоях  
- **Scalability**: Redis-based distributed rate limiting
- **Observability**: Comprehensive logging и metrics

## 2. Модель данных

### 2.1. Таблица `api_keys`

```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_hash VARCHAR(64) NOT NULL UNIQUE,  -- SHA-256 hash
    key_prefix VARCHAR(8) NOT NULL,        -- First 8 chars for identification
    name VARCHAR(100) NOT NULL,            -- Human-readable name
    description TEXT,                      -- Optional description
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
    
    -- Quotas and limits
    rate_limit_per_minute INTEGER DEFAULT 60,
    rate_limit_per_hour INTEGER DEFAULT 3600,
    daily_request_quota INTEGER DEFAULT 100000,
    monthly_request_quota INTEGER DEFAULT 3000000,
    
    -- Status and lifecycle  
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Security
    allowed_ips TEXT[],                    -- Optional IP whitelist
    allowed_origins TEXT[],                -- Optional CORS origins
    scopes TEXT[] DEFAULT ARRAY['read'],   -- Permission scopes
    
    -- Usage tracking (updated by background job)
    total_requests BIGINT DEFAULT 0,
    requests_today INTEGER DEFAULT 0,
    requests_this_month INTEGER DEFAULT 0,
    last_request_ip INET,
    
    -- Audit trail
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    revocation_reason TEXT
);

-- Indexes for performance
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_active ON api_keys(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_api_keys_expires ON api_keys(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_api_keys_created_by ON api_keys(created_by);
```

### 2.2. Таблица `roles`

```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Default quotas for role
    default_rate_limit_per_minute INTEGER DEFAULT 60,
    default_rate_limit_per_hour INTEGER DEFAULT 3600,
    default_daily_quota INTEGER DEFAULT 100000,
    default_monthly_quota INTEGER DEFAULT 3000000,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Predefined roles
INSERT INTO roles (name, description, permissions) VALUES
('read_only', 'Read-only access to public endpoints', 
 '{"htx": {"ticker": "read"}, "data": {"export": "none"}}'),
('standard', 'Standard API access with moderate quotas',
 '{"htx": {"ticker": "read"}, "data": {"export": "csv"}, "uploads": "read"}'),
('premium', 'Premium access with higher quotas and additional features',
 '{"htx": {"ticker": "read", "historical": "read"}, "data": {"export": "all"}, "uploads": "write", "analytics": "read"}'),
('admin', 'Administrative access to all features',
 '{"*": "*"}');
```

### 2.3. Таблица `api_key_usage_logs`

```sql
CREATE TABLE api_key_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
    
    -- Request details
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    
    -- Client information
    client_ip INET NOT NULL,
    user_agent TEXT,
    referer TEXT,
    
    -- Request metadata
    request_size_bytes INTEGER,
    response_size_bytes INTEGER,
    cache_hit BOOLEAN DEFAULT FALSE,
    
    -- Timestamp
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Rate limiting context
    rate_limit_hit BOOLEAN DEFAULT FALSE,
    quota_exceeded BOOLEAN DEFAULT FALSE,
    
    -- Error information (if any)
    error_code VARCHAR(50),
    error_message TEXT
);

-- Partitioning by month for performance
CREATE TABLE api_key_usage_logs_y2024m12 PARTITION OF api_key_usage_logs
FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Indexes
CREATE INDEX idx_usage_logs_api_key_timestamp ON api_key_usage_logs(api_key_id, timestamp);
CREATE INDEX idx_usage_logs_timestamp ON api_key_usage_logs(timestamp);
CREATE INDEX idx_usage_logs_endpoint ON api_key_usage_logs(endpoint);
```

## 3. API Key Generation и Formats

### 3.1. Key Format

API keys используют следующий format:
```
htx_[environment]_[random_32_chars]

Examples:
htx_prod_k7j3n9q8w2e5r4t6y1u8i9o0p3a5s7d9
htx_dev_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
htx_test_x9z8y7w6v5u4t3s2r1q0p9o8n7m6l5k4
```

### 3.2. Generation Algorithm

```python
import secrets
import hashlib
import string
from datetime import datetime, timezone

class APIKeyGenerator:
    def __init__(self, environment: str = "prod"):
        self.environment = environment
        self.alphabet = string.ascii_lowercase + string.digits
    
    def generate_key(self) -> tuple[str, str, str]:
        """
        Generates new API key.
        
        Returns:
            tuple: (full_key, key_hash, key_prefix)
        """
        # Generate 32 random characters
        random_part = ''.join(secrets.choice(self.alphabet) for _ in range(32))
        
        # Construct full key
        full_key = f"htx_{self.environment}_{random_part}"
        
        # Generate hash for storage (never store plaintext)
        key_hash = hashlib.sha256(full_key.encode()).hexdigest()
        
        # Extract prefix for identification
        key_prefix = full_key[:8]  # "htx_prod" or "htx_dev_"
        
        return full_key, key_hash, key_prefix
    
    def verify_key(self, provided_key: str, stored_hash: str) -> bool:
        """Verify provided key against stored hash."""
        provided_hash = hashlib.sha256(provided_key.encode()).hexdigest()
        return secrets.compare_digest(provided_hash, stored_hash)
```

### 3.3. Key Validation

```python
import re

def validate_api_key_format(key: str) -> bool:
    """Validate API key format without checking existence."""
    pattern = r'^htx_(prod|dev|test)_[a-z0-9]{32}$'
    return bool(re.match(pattern, key))

def extract_environment(key: str) -> str:
    """Extract environment from API key."""
    if not validate_api_key_format(key):
        raise ValueError("Invalid API key format")
    return key.split('_')[1]
```

## 4. Authentication Flow

### 4.1. Request Authentication

```python
from fastapi import HTTPException, Depends, Header
from typing import Optional
import hashlib

async def authenticate_api_key(
    x_api_key: Optional[str] = Header(None),
    api_key: Optional[str] = None  # Query parameter fallback
) -> dict:
    """
    Authenticate request using API key.
    
    Supports both header and query parameter:
    - Header: X-API-Key: htx_prod_...
    - Query: ?api_key=htx_prod_...
    """
    key = x_api_key or api_key
    
    if not key:
        raise HTTPException(
            status_code=401,
            detail="API key required. Provide via X-API-Key header or api_key parameter."
        )
    
    if not validate_api_key_format(key):
        raise HTTPException(
            status_code=401,
            detail="Invalid API key format"
        )
    
    # Hash the provided key
    key_hash = hashlib.sha256(key.encode()).hexdigest()
    
    # Look up in database
    api_key_record = await get_api_key_by_hash(key_hash)
    
    if not api_key_record:
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )
    
    if not api_key_record.is_active:
        raise HTTPException(
            status_code=401,
            detail="API key is disabled"
        )
    
    if api_key_record.expires_at and api_key_record.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=401,
            detail="API key has expired"
        )
    
    # Update last used timestamp (async background task)
    await update_key_last_used(api_key_record.id)
    
    return {
        "api_key_id": api_key_record.id,
        "role": api_key_record.role,
        "scopes": api_key_record.scopes,
        "rate_limits": {
            "per_minute": api_key_record.rate_limit_per_minute,
            "per_hour": api_key_record.rate_limit_per_hour
        }
    }
```

### 4.2. Rate Limiting Integration

```python
from app.utils.ratelimit import RateLimiter

class APIKeyRateLimiter:
    def __init__(self, redis_url: Optional[str] = None):
        self.limiter = RateLimiter(redis_url)
    
    async def check_rate_limit(self, api_key_id: str, limits: dict) -> bool:
        """Check if API key is within rate limits."""
        
        # Check per-minute limit
        minute_key = f"api_key:{api_key_id}:minute:{int(time.time() // 60)}"
        minute_allowed = await self.limiter.allow(
            minute_key, 
            limits["per_minute"], 
            60
        )
        
        if not minute_allowed:
            return False
        
        # Check per-hour limit
        hour_key = f"api_key:{api_key_id}:hour:{int(time.time() // 3600)}"
        hour_allowed = await self.limiter.allow(
            hour_key,
            limits["per_hour"],
            3600
        )
        
        return hour_allowed
    
    async def get_rate_limit_status(self, api_key_id: str) -> dict:
        """Get current rate limit status for API key."""
        # Implementation would query Redis for current counts
        # and return remaining requests per window
        pass
```

## 5. CRUD API Endpoints

### 5.1. Create API Key

```python
@router.post("/api/v1/keys", response_model=APIKeyResponse)
async def create_api_key(
    request: CreateAPIKeyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create new API key.
    
    Requires admin role or key creation permission.
    """
    
    # Generate new key
    generator = APIKeyGenerator(environment="prod")
    full_key, key_hash, key_prefix = generator.generate_key()
    
    # Create database record
    api_key = await create_api_key_record(
        db=db,
        key_hash=key_hash,
        key_prefix=key_prefix,
        name=request.name,
        description=request.description,
        role_id=request.role_id,
        created_by=current_user.id,
        expires_at=request.expires_at,
        scopes=request.scopes,
        allowed_ips=request.allowed_ips
    )
    
    # Return full key only once (never stored)
    return APIKeyResponse(
        id=api_key.id,
        key=full_key,  # Only returned on creation
        name=api_key.name,
        key_prefix=key_prefix,
        created_at=api_key.created_at,
        expires_at=api_key.expires_at,
        scopes=api_key.scopes
    )
```

### 5.2. List API Keys

```python
@router.get("/api/v1/keys", response_model=List[APIKeyListResponse])
async def list_api_keys(
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List API keys for current user or all (if admin)."""
    
    filters = {"is_active": True} if not include_inactive else {}
    
    if not current_user.is_admin:
        filters["created_by"] = current_user.id
    
    api_keys = await get_api_keys(
        db=db,
        skip=skip,
        limit=limit,
        filters=filters
    )
    
    return [
        APIKeyListResponse(
            id=key.id,
            name=key.name,
            key_prefix=key.key_prefix,  # Never return full key
            role=key.role.name if key.role else None,
            is_active=key.is_active,
            created_at=key.created_at,
            expires_at=key.expires_at,
            last_used_at=key.last_used_at,
            total_requests=key.total_requests
        )
        for key in api_keys
    ]
```

### 5.3. Get API Key Details

```python
@router.get("/api/v1/keys/{key_id}", response_model=APIKeyDetailResponse)
async def get_api_key(
    key_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information about specific API key."""
    
    api_key = await get_api_key_by_id(db, key_id)
    
    if not api_key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    # Access control
    if not current_user.is_admin and api_key.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get usage statistics
    usage_stats = await get_api_key_usage_stats(db, key_id)
    
    return APIKeyDetailResponse(
        id=api_key.id,
        name=api_key.name,
        key_prefix=api_key.key_prefix,
        role=api_key.role.name if api_key.role else None,
        scopes=api_key.scopes,
        rate_limits={
            "per_minute": api_key.rate_limit_per_minute,
            "per_hour": api_key.rate_limit_per_hour,
            "daily_quota": api_key.daily_request_quota,
            "monthly_quota": api_key.monthly_request_quota
        },
        usage_stats=usage_stats,
        security={
            "allowed_ips": api_key.allowed_ips,
            "allowed_origins": api_key.allowed_origins
        },
        is_active=api_key.is_active,
        created_at=api_key.created_at,
        expires_at=api_key.expires_at,
        last_used_at=api_key.last_used_at
    )
```

### 5.4. Update API Key

```python
@router.patch("/api/v1/keys/{key_id}", response_model=APIKeyDetailResponse)
async def update_api_key(
    key_id: UUID,
    request: UpdateAPIKeyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update API key settings (name, quotas, expiration, etc.)."""
    
    api_key = await get_api_key_by_id(db, key_id)
    
    if not api_key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    # Access control
    if not current_user.is_admin and api_key.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Update fields
    update_data = request.dict(exclude_unset=True)
    updated_key = await update_api_key_record(db, key_id, update_data)
    
    return APIKeyDetailResponse.from_orm(updated_key)
```

### 5.5. Revoke API Key

```python
@router.delete("/api/v1/keys/{key_id}")
async def revoke_api_key(
    key_id: UUID,
    reason: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Revoke (disable) API key."""
    
    api_key = await get_api_key_by_id(db, key_id)
    
    if not api_key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    # Access control
    if not current_user.is_admin and api_key.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Revoke key
    await revoke_api_key_record(
        db=db,
        key_id=key_id,
        revoked_by=current_user.id,
        reason=reason
    )
    
    return {"message": "API key revoked successfully"}
```

## 6. Quotas и Usage Tracking

### 6.1. Quota Types

1. **Rate Limits**: Requests per time window (minute/hour)
2. **Daily Quotas**: Maximum requests per day
3. **Monthly Quotas**: Maximum requests per month  
4. **Feature Quotas**: Access to specific endpoints/features

### 6.2. Usage Tracking Implementation

```python
class UsageTracker:
    def __init__(self, db: AsyncSession, redis_client: Optional[Redis] = None):
        self.db = db
        self.redis = redis_client
    
    async def track_request(
        self,
        api_key_id: UUID,
        endpoint: str,
        method: str,
        status_code: int,
        response_time_ms: int,
        client_ip: str,
        request_size: int = 0,
        response_size: int = 0,
        cache_hit: bool = False
    ):
        """Track API request for usage statistics."""
        
        # Log to database (async background task)
        log_entry = APIKeyUsageLog(
            api_key_id=api_key_id,
            endpoint=endpoint,
            method=method,
            status_code=status_code,
            response_time_ms=response_time_ms,
            client_ip=client_ip,
            request_size_bytes=request_size,
            response_size_bytes=response_size,
            cache_hit=cache_hit,
            timestamp=datetime.now(timezone.utc)
        )
        
        await self.db.add(log_entry)
        
        # Update counters in Redis for real-time tracking
        if self.redis:
            today = datetime.now(timezone.utc).date()
            month = today.strftime("%Y-%m")
            
            pipe = self.redis.pipeline()
            pipe.incr(f"usage:{api_key_id}:total")
            pipe.incr(f"usage:{api_key_id}:daily:{today}")
            pipe.incr(f"usage:{api_key_id}:monthly:{month}")
            pipe.expire(f"usage:{api_key_id}:daily:{today}", 86400 * 2)  # Keep 2 days
            pipe.expire(f"usage:{api_key_id}:monthly:{month}", 86400 * 32)  # Keep 32 days
            await pipe.execute()
    
    async def check_quotas(self, api_key_id: UUID, quotas: dict) -> dict:
        """Check if API key is within daily/monthly quotas."""
        
        today = datetime.now(timezone.utc).date()
        month = today.strftime("%Y-%m")
        
        if self.redis:
            # Get from Redis (real-time)
            daily_count = await self.redis.get(f"usage:{api_key_id}:daily:{today}") or 0
            monthly_count = await self.redis.get(f"usage:{api_key_id}:monthly:{month}") or 0
        else:
            # Fallback to database query
            daily_count = await self.get_daily_usage_from_db(api_key_id, today)
            monthly_count = await self.get_monthly_usage_from_db(api_key_id, month)
        
        return {
            "daily": {
                "used": int(daily_count),
                "limit": quotas.get("daily_quota", 100000),
                "remaining": max(0, quotas.get("daily_quota", 100000) - int(daily_count))
            },
            "monthly": {
                "used": int(monthly_count),
                "limit": quotas.get("monthly_quota", 3000000),
                "remaining": max(0, quotas.get("monthly_quota", 3000000) - int(monthly_count))
            }
        }
```

## 7. Security Considerations

### 7.1. Key Storage Security

- **Never store plaintext keys**: Только SHA-256 hashes
- **Prefix storage**: Храним первые 8 символов для идентификации  
- **Secure generation**: `secrets` module для cryptographically secure randomness
- **Environment separation**: Разные префиксы для prod/dev/test

### 7.2. Access Control

- **IP Whitelisting**: Optional restriction по IP адресам
- **CORS Origins**: Optional restriction по origin headers
- **Scope-based permissions**: Granular access control
- **Role-based quotas**: Разные лимиты для разных ролей

### 7.3. Audit Trail

```python
async def log_security_event(
    event_type: str,
    api_key_id: Optional[UUID],
    user_id: Optional[UUID],
    details: dict,
    severity: str = "INFO",
    client_ip: Optional[str] = None
):
    """Log security-related events for audit."""
    
    event = SecurityAuditLog(
        event_type=event_type,  # "KEY_CREATED", "KEY_REVOKED", "AUTH_FAILED", etc.
        api_key_id=api_key_id,
        user_id=user_id,
        details=details,
        severity=severity,
        client_ip=client_ip,
        timestamp=datetime.now(timezone.utc)
    )
    
    await db.add(event)
    
    # Also log to external security monitoring if configured
    if severity in ["WARNING", "ERROR", "CRITICAL"]:
        await send_security_alert(event)
```

## 8. Key Rotation и Lifecycle

### 8.1. Automated Rotation

```python
class KeyRotationService:
    def __init__(self, db: AsyncSession, notification_service: NotificationService):
        self.db = db
        self.notifications = notification_service
    
    async def check_expiring_keys(self, days_before: int = 7):
        """Check for keys expiring within specified days."""
        
        cutoff_date = datetime.now(timezone.utc) + timedelta(days=days_before)
        
        expiring_keys = await self.db.execute(
            select(APIKey)
            .where(
                and_(
                    APIKey.expires_at <= cutoff_date,
                    APIKey.expires_at > datetime.now(timezone.utc),
                    APIKey.is_active == True
                )
            )
        )
        
        for key in expiring_keys.scalars():
            await self.send_expiration_notice(key)
    
    async def rotate_key(self, key_id: UUID, created_by: UUID) -> tuple[str, UUID]:
        """
        Rotate API key - create new one and mark old as deprecated.
        
        Returns: (new_key, new_key_id)
        """
        
        old_key = await self.get_api_key_by_id(key_id)
        if not old_key:
            raise ValueError("Key not found")
        
        # Generate new key with same settings
        generator = APIKeyGenerator()
        new_full_key, new_key_hash, new_key_prefix = generator.generate_key()
        
        # Create new key record
        new_key = APIKey(
            key_hash=new_key_hash,
            key_prefix=new_key_prefix,
            name=f"{old_key.name} (rotated)",
            description=f"Rotated from {old_key.key_prefix}...",
            role_id=old_key.role_id,
            rate_limit_per_minute=old_key.rate_limit_per_minute,
            rate_limit_per_hour=old_key.rate_limit_per_hour,
            daily_request_quota=old_key.daily_request_quota,
            monthly_request_quota=old_key.monthly_request_quota,
            scopes=old_key.scopes,
            allowed_ips=old_key.allowed_ips,
            allowed_origins=old_key.allowed_origins,
            created_by=created_by,
            expires_at=old_key.expires_at
        )
        
        await self.db.add(new_key)
        await self.db.flush()
        
        # Mark old key for deprecation (30 day grace period)
        old_key.expires_at = datetime.now(timezone.utc) + timedelta(days=30)
        old_key.description = f"DEPRECATED - Rotated to {new_key_prefix}..."
        
        await self.db.commit()
        
        return new_full_key, new_key.id
```

### 8.2. Grace Period Management

- **30-day grace period**: Старые ключи остаются активными 30 дней после ротации
- **Deprecation warnings**: API возвращает headers с предупреждениями
- **Usage monitoring**: Tracking использования deprecated keys
- **Automatic cleanup**: Background job для удаления expired keys

## 9. Monitoring и Metrics

### 9.1. Key Metrics

```python
class APIKeyMetrics:
    """Metrics collection for API key usage."""
    
    @staticmethod
    async def collect_metrics(db: AsyncSession, redis: Redis) -> dict:
        """Collect comprehensive API key metrics."""
        
        # Active keys count
        active_keys = await db.scalar(
            select(func.count(APIKey.id))
            .where(APIKey.is_active == True)
        )
        
        # Keys by role
        keys_by_role = await db.execute(
            select(Role.name, func.count(APIKey.id))
            .join(APIKey.role)
            .where(APIKey.is_active == True)
            .group_by(Role.name)
        )
        
        # Usage statistics (last 24 hours)
        yesterday = datetime.now(timezone.utc) - timedelta(days=1)
        recent_usage = await db.execute(
            select(
                func.count(APIKeyUsageLog.id).label('total_requests'),
                func.avg(APIKeyUsageLog.response_time_ms).label('avg_response_time'),
                func.count(APIKeyUsageLog.id)
                .filter(APIKeyUsageLog.status_code >= 400)
                .label('error_count')
            )
            .where(APIKeyUsageLog.timestamp >= yesterday)
        )
        
        usage_stats = recent_usage.first()
        
        # Rate limiting hits
        rate_limit_hits = await redis.get("metrics:rate_limits:24h") or 0
        
        return {
            "active_keys": active_keys,
            "keys_by_role": dict(keys_by_role.all()),
            "usage_24h": {
                "total_requests": usage_stats.total_requests or 0,
                "avg_response_time_ms": float(usage_stats.avg_response_time or 0),
                "error_count": usage_stats.error_count or 0,
                "rate_limit_hits": int(rate_limit_hits)
            }
        }
```

### 9.2. Health Checks

```python
@router.get("/api/v1/keys/health")
async def api_keys_health_check(
    db: AsyncSession = Depends(get_db),
    redis: Redis = Depends(get_redis)
):
    """Health check endpoint for API key system."""
    
    try:
        # Check database connectivity
        db_check = await db.execute(select(1))
        db_healthy = db_check.scalar() == 1
        
        # Check Redis connectivity
        redis_healthy = await redis.ping()
        
        # Check key creation capability
        generator = APIKeyGenerator("test")
        test_key, test_hash, test_prefix = generator.generate_key()
        generation_healthy = len(test_key) == 44  # Expected length
        
        # Check rate limiter
        limiter = RateLimiter(redis_url=str(redis.connection_pool.connection_kwargs['host']))
        rate_limit_healthy = await limiter.allow("health_check", 1, 60)
        
        health_status = {
            "database": db_healthy,
            "redis": redis_healthy,
            "key_generation": generation_healthy,
            "rate_limiting": rate_limit_healthy,
            "overall": all([db_healthy, redis_healthy, generation_healthy, rate_limit_healthy])
        }
        
        status_code = 200 if health_status["overall"] else 503
        
        return JSONResponse(
            status_code=status_code,
            content={
                "status": "healthy" if health_status["overall"] else "unhealthy",
                "checks": health_status,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        )
        
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        )
```

## 10. Implementation Roadmap

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Database schema creation (tables + indexes)
- [ ] API key generation и validation utilities
- [ ] Basic CRUD endpoints (create, list, get, revoke)
- [ ] Authentication middleware integration
- [ ] Unit tests for core functionality

### Phase 2: Rate Limiting Integration (Week 3)
- [ ] Rate limiter integration with API keys
- [ ] Quota tracking implementation
- [ ] Usage logging system
- [ ] Basic metrics collection
- [ ] Integration tests

### Phase 3: Security Features (Week 4)
- [ ] IP whitelisting implementation
- [ ] CORS origin restrictions
- [ ] Scope-based permissions
- [ ] Security audit logging
- [ ] Security testing

### Phase 4: Advanced Features (Week 5-6)
- [ ] Key rotation system
- [ ] Automated expiration handling
- [ ] Advanced monitoring и alerting
- [ ] Performance optimization
- [ ] Documentation и examples

### Phase 5: Production Readiness (Week 7-8)
- [ ] Load testing
- [ ] Security audit
- [ ] Migration scripts
- [ ] Monitoring dashboards
- [ ] Production deployment

## 11. Database Migration

### 11.1. Alembic Migration Script

```python
"""Add API keys management tables

Revision ID: api_keys_001
Revises: previous_revision
Create Date: 2024-12-19 12:00:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = 'api_keys_001'
down_revision = 'previous_revision'
branch_labels = None
depends_on = None

def upgrade():
    # Create roles table
    op.create_table('roles',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('name', sa.String(50), nullable=False, unique=True),
        sa.Column('description', sa.Text()),
        sa.Column('permissions', postgresql.JSONB(), nullable=False, server_default="'{}'::jsonb"),
        sa.Column('default_rate_limit_per_minute', sa.Integer(), server_default='60'),
        sa.Column('default_rate_limit_per_hour', sa.Integer(), server_default='3600'),
        sa.Column('default_daily_quota', sa.Integer(), server_default='100000'),
        sa.Column('default_monthly_quota', sa.Integer(), server_default='3000000'),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.func.now())
    )
    
    # Create api_keys table
    op.create_table('api_keys',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('key_hash', sa.String(64), nullable=False, unique=True),
        sa.Column('key_prefix', sa.String(8), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('description', sa.Text()),
        sa.Column('role_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('roles.id', ondelete='SET NULL')),
        sa.Column('rate_limit_per_minute', sa.Integer(), server_default='60'),
        sa.Column('rate_limit_per_hour', sa.Integer(), server_default='3600'),
        sa.Column('daily_request_quota', sa.Integer(), server_default='100000'),
        sa.Column('monthly_request_quota', sa.Integer(), server_default='3000000'),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.Column('expires_at', sa.TIMESTAMP(timezone=True)),
        sa.Column('last_used_at', sa.TIMESTAMP(timezone=True)),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.func.now()),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.func.now()),
        sa.Column('allowed_ips', postgresql.ARRAY(sa.Text())),
        sa.Column('allowed_origins', postgresql.ARRAY(sa.Text())),
        sa.Column('scopes', postgresql.ARRAY(sa.Text()), server_default="ARRAY['read']"),
        sa.Column('total_requests', sa.BigInteger(), server_default='0'),
        sa.Column('requests_today', sa.Integer(), server_default='0'),
        sa.Column('requests_this_month', sa.Integer(), server_default='0'),
        sa.Column('last_request_ip', postgresql.INET()),
        sa.Column('revoked_at', sa.TIMESTAMP(timezone=True)),
        sa.Column('revoked_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL')),
        sa.Column('revocation_reason', sa.Text())
    )
    
    # Create indexes
    op.create_index('idx_api_keys_hash', 'api_keys', ['key_hash'])
    op.create_index('idx_api_keys_prefix', 'api_keys', ['key_prefix'])
    op.create_index('idx_api_keys_active', 'api_keys', ['is_active'], postgresql_where=sa.text('is_active = true'))
    op.create_index('idx_api_keys_expires', 'api_keys', ['expires_at'], postgresql_where=sa.text('expires_at IS NOT NULL'))
    op.create_index('idx_api_keys_created_by', 'api_keys', ['created_by'])
    
    # Create usage logs table (partitioned)
    op.create_table('api_key_usage_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('api_key_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('api_keys.id', ondelete='CASCADE')),
        sa.Column('endpoint', sa.String(255), nullable=False),
        sa.Column('method', sa.String(10), nullable=False),
        sa.Column('status_code', sa.Integer(), nullable=False),
        sa.Column('response_time_ms', sa.Integer()),
        sa.Column('client_ip', postgresql.INET(), nullable=False),
        sa.Column('user_agent', sa.Text()),
        sa.Column('referer', sa.Text()),
        sa.Column('request_size_bytes', sa.Integer()),
        sa.Column('response_size_bytes', sa.Integer()),
        sa.Column('cache_hit', sa.Boolean(), server_default='false'),
        sa.Column('timestamp', sa.TIMESTAMP(timezone=True), server_default=sa.func.now()),
        sa.Column('rate_limit_hit', sa.Boolean(), server_default='false'),
        sa.Column('quota_exceeded', sa.Boolean(), server_default='false'),
        sa.Column('error_code', sa.String(50)),
        sa.Column('error_message', sa.Text())
    ) # Note: Partitioning setup would need additional SQL
    
    # Insert default roles
    op.execute("""
        INSERT INTO roles (name, description, permissions) VALUES
        ('read_only', 'Read-only access to public endpoints', 
         '{"htx": {"ticker": "read"}, "data": {"export": "none"}}'),
        ('standard', 'Standard API access with moderate quotas',
         '{"htx": {"ticker": "read"}, "data": {"export": "csv"}, "uploads": "read"}'),
        ('premium', 'Premium access with higher quotas and additional features',
         '{"htx": {"ticker": "read", "historical": "read"}, "data": {"export": "all"}, "uploads": "write", "analytics": "read"}'),
        ('admin', 'Administrative access to all features',
         '{"*": "*"}')
    """)

def downgrade():
    op.drop_table('api_key_usage_logs')
    op.drop_table('api_keys')
    op.drop_table('roles')
```

## 12. Configuration Examples

### 12.1. Environment Variables

```bash
# API Keys Configuration
API_KEYS_ENABLED=true
API_KEYS_DEFAULT_ENVIRONMENT=prod
API_KEYS_ROTATION_DAYS=90
API_KEYS_GRACE_PERIOD_DAYS=30

# Rate Limiting
API_KEYS_DEFAULT_RATE_LIMIT_MINUTE=60
API_KEYS_DEFAULT_RATE_LIMIT_HOUR=3600
API_KEYS_DEFAULT_DAILY_QUOTA=100000
API_KEYS_DEFAULT_MONTHLY_QUOTA=3000000

# Security
API_KEYS_REQUIRE_IP_WHITELIST=false
API_KEYS_ENABLE_CORS_RESTRICTION=true
API_KEYS_LOG_ALL_REQUESTS=true

# Redis (for rate limiting and usage tracking)
REDIS_URL=redis://localhost:6379/1
```

### 12.2. FastAPI Integration

```python
# app/main.py
from fastapi import FastAPI, Depends, HTTPException
from app.middleware.api_keys import APIKeyMiddleware
from app.utils.auth import authenticate_api_key

app = FastAPI(title="HTX Interface v2 API")

# Add API key middleware
app.add_middleware(APIKeyMiddleware)

# Example protected endpoint
@app.get("/api/data/htx/ticker/{symbol}")
async def get_ticker(
    symbol: str,
    api_key_info: dict = Depends(authenticate_api_key)
):
    """Get HTX ticker data - requires valid API key."""
    
    # Check permissions
    if "htx" not in api_key_info.get("scopes", []):
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    
    # Your existing ticker logic here
    return {"symbol": symbol, "price": "...", "api_key_id": api_key_info["api_key_id"]}
```

---

**Документ подготовлен**: 2024-12-19  
**Версия**: 1.0  
**Статус**: Ready for implementation

Данная спецификация предоставляет comprehensive план для реализации системы управления API ключами в HTX Interface v2, включая security best practices, scalable architecture и monitoring capabilities.
