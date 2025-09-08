import time
from typing import Optional

try:
    from redis import asyncio as aioredis  # type: ignore
except Exception:  # pragma: no cover
    aioredis = None  # type: ignore


class RateLimiter:
    """Simple fixed-window rate limiter with Redis or in-memory fallback.

    Key space is up to caller (e.g., per-IP or per-endpoint).
    """

    def __init__(self, redis_url: Optional[str] = None):
        self._redis_url = redis_url
        self._mem_store: dict[str, tuple[int, float]] = {}

    async def allow(self, key: str, max_calls: int, window_sec: int) -> bool:
        if self._redis_url and aioredis is not None:
            try:
                r = aioredis.from_url(self._redis_url, decode_responses=True)
                # start window with expire on first increment
                current = await r.incr(key)
                if current == 1:
                    await r.expire(key, window_sec)
                return current <= max_calls
            except Exception:
                # fall through to memory
                pass

        # in-memory fallback (per-process, not distributed)
        now = time.time()
        count, reset_at = self._mem_store.get(key, (0, now + window_sec))
        if now > reset_at:
            count, reset_at = 0, now + window_sec
        count += 1
        self._mem_store[key] = (count, reset_at)
        return count <= max_calls

