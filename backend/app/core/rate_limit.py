from __future__ import annotations

import asyncio
from typing import Optional

from fastapi import HTTPException, Request, status

try:
    import redis.asyncio as redis
except Exception:  # pragma: no cover - fallback import
    redis = None  # type: ignore

from app.core.config import settings

_redis_client: Optional["redis.Redis"] = None
_redis_lock = asyncio.Lock()


async def _get_redis() -> Optional["redis.Redis"]:
    global _redis_client
    if redis is None:
        return None
    if _redis_client is None:
        async with _redis_lock:
            if _redis_client is None:
                try:
                    _redis_client = redis.from_url(settings.REDIS_URL)
                    await _redis_client.ping()
                except Exception:
                    _redis_client = None
    return _redis_client


def trading_rate_limit(requests_per_minute: int = 60):
    """FastAPI dependency for simple IP+path rate limiting using Redis.

    Usage: add `Depends(trading_rate_limit(60))` to endpoint parameters.
    """

    window = 60

    async def limiter(request: Request) -> None:
        client = await _get_redis()
        if client is None:
            # If Redis not available, do not block requests
            return

        ip = request.client.host if request.client else "unknown"
        path = request.url.path
        key = f"rl:{path}:{ip}"

        try:
            # Atomically increment and set expiry if first hit
            hits = await client.incr(key)
            if hits == 1:
                await client.expire(key, window)

            if hits > requests_per_minute:
                ttl = await client.ttl(key)
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={
                        "error": "rate_limited",
                        "message": "Too many requests. Please slow down.",
                        "retry_after_seconds": max(ttl or 0, 0),
                    },
                )
        except HTTPException:
            raise
        except Exception:
            # Fail-open on Redis errors
            return

    return limiter


async def websocket_rate_limit(
    websocket_id: str, max_messages_per_minute: int = 120
) -> bool:
    """Rate limit WebSocket messages per connection"""
    client = await _get_redis()
    if client is None:
        # If Redis not available, allow all requests
        return True

    key = f"ws_rl:{websocket_id}"
    window = 60

    try:
        # Atomically increment and set expiry if first hit
        hits = await client.incr(key)
        if hits == 1:
            await client.expire(key, window)

        return hits <= max_messages_per_minute
    except Exception:
        # Fail-open on Redis errors
        return True
