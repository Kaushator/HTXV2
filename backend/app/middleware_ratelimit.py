from __future__ import annotations

from typing import Optional

from .config import settings
from .utils.api_keys import extract_api_key
from .utils.ratelimit import RateLimiter


class GlobalRateLimitMiddleware:
    """ASGI middleware applying global rate limits per API key or client IP.

    - Disabled unless RATE_LIMIT_ENABLED=true
    - Excludes paths by prefix (health/metrics/docs by default)
    - Per-API-key quotas resolved from DB via services.quotas (best-effort)
    - Falls back to defaults when no key/quotas
    """

    def __init__(self, app):
        self.app = app
        self._rl = RateLimiter(settings.redis_url)

    async def __call__(self, scope, receive, send):  # type: ignore[override]
        if scope.get("type") != "http":
            return await self.app(scope, receive, send)

        if not settings.rate_limit_enabled:
            return await self.app(scope, receive, send)

        path: str = scope.get("path", "")
        for pref in settings.rate_limit_exclude_prefixes:
            if path.startswith(pref):
                return await self.app(scope, receive, send)

        # Build a lightweight Request-like accessor for extract_api_key
        class _Req:
            def __init__(self, sc):
                self.headers = {k.decode(): v.decode(errors="ignore") for k, v in sc.get("headers", [])}
                from urllib.parse import parse_qs

                try:
                    raw = sc.get("query_string", b"")
                    q = raw.decode("utf-8") if isinstance(raw, (bytes, bytearray)) else str(raw)
                except Exception:
                    q = ""
                self.query_params = {k: v[0] if isinstance(v, list) else v for k, v in parse_qs(q, keep_blank_values=True).items()}

        req = _Req(scope)
        api_key, _ = extract_api_key(req)  # type: ignore[arg-type]

        # Resolve quotas
        max_calls = settings.rate_limit_default_max
        window_sec = settings.rate_limit_default_window
        if api_key:
            try:
                from .services.quotas import get_rate_limit_for_api_key

                res = await get_rate_limit_for_api_key(api_key)
                if res:
                    max_calls, window_sec = res
            except Exception:
                pass

        # Bucket key: scope by API key or client IP
        if api_key:
            bucket = f"rl:global:key:{api_key.split('.',1)[0]}"
        else:
            client_ip = scope.get("client")[0] if scope.get("client") else "unknown"
            bucket = f"rl:global:ip:{client_ip}"

        allowed = await self._rl.allow(bucket, max_calls, window_sec)
        if allowed:
            return await self.app(scope, receive, send)

        # Short-circuit with 429
        async def limited_sender(message):
            await send(message)

        start_headers = {
            b"content-type": b"application/json; charset=utf-8",
        }
        await send({
            "type": "http.response.start",
            "status": 429,
            "headers": list(start_headers.items()),
        })
        await send({
            "type": "http.response.body",
            "body": b'{"status":"error","error":{"code":"http_429","message":"Rate limit exceeded"},"http_status":429}',
            "more_body": False,
        })

