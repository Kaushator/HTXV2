from __future__ import annotations

import json
from typing import Any, Optional

try:
    import redis.asyncio as redis
except Exception:  # pragma: no cover
    redis = None  # type: ignore

from app.core.config import settings

_client: Optional["redis.Redis"] = None


async def _get_client() -> Optional["redis.Redis"]:
    global _client
    if redis is None:
        return None
    if _client is None:
        try:
            _client = redis.from_url(settings.REDIS_URL)
            await _client.ping()
        except Exception:
            _client = None
    return _client


async def get_json(key: str) -> Optional[dict[str, Any]]:
    client = await _get_client()
    if not client:
        return None
    try:
        raw = await client.get(key)
        if not raw:
            return None
        return json.loads(raw)
    except Exception:
        return None


async def set_json(key: str, value: dict[str, Any], ttl_seconds: int) -> None:
    client = await _get_client()
    if not client:
        return
    try:
        await client.setex(key, ttl_seconds, json.dumps(value))
    except Exception:
        return

