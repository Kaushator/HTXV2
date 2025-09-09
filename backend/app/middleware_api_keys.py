from __future__ import annotations

import asyncio
from typing import Optional


class ApiKeyUsageMiddleware:
    """ASGI middleware that updates last_used_at for any request carrying an API key.

    Extracts API key from query param `api_key` or header `X-API-Key` and updates usage
    after the response is sent. Best-effort; failures are ignored.
    """

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):  # type: ignore[override]
        if scope.get("type") != "http":
            return await self.app(scope, receive, send)

        # Lazy import to avoid overhead on non-HTTP
        from .utils.api_keys import extract_api_key
        from .services.api_keys import touch_api_key_usage

        # Build a fake Request-like accessor for headers/query extraction
        class _Req:
            def __init__(self, sc):
                self.headers = {k.decode(): v.decode(errors="ignore") for k, v in sc.get("headers", [])}
                try:
                    raw_q = sc.get("query_string", b"")
                    qs = raw_q.decode("utf-8") if isinstance(raw_q, (bytes, bytearray)) else str(raw_q)
                except Exception:
                    qs = ""
                from urllib.parse import parse_qs

                self.query_params = {k: v[0] if isinstance(v, list) else v for k, v in parse_qs(qs, keep_blank_values=True).items()}

        req = _Req(scope)
        key, _ = extract_api_key(req)  # type: ignore[arg-type]

        async def send_wrapper(message):
            if message["type"] == "http.response.body" and not message.get("more_body", False):
                if key:
                    # Fire-and-forget
                    try:
                        asyncio.create_task(touch_api_key_usage(key))
                    except Exception:
                        pass
            await send(message)

        await self.app(scope, receive, send_wrapper)

