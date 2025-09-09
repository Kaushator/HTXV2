import logging
import time
import uuid
from typing import Callable, Awaitable, Optional

from .logging_setup import request_id_var


class RequestContextMiddleware:
    """ASGI middleware that assigns a request_id, measures duration, and logs access in JSON.

    Emits a single INFO log line per completed request to logger 'htx.access'.
    Adds 'X-Request-ID' header to the response.
    """

    def __init__(self, app):
        self.app = app
        self.logger = logging.getLogger("htx.access")

    async def __call__(self, scope, receive, send):  # type: ignore[override]
        if scope.get("type") != "http":
            return await self.app(scope, receive, send)

        start = time.perf_counter()
        rid = uuid.uuid4().hex
        token = request_id_var.set(rid)

        method = scope.get("method")
        path = scope.get("path")
        query = scope.get("query_string", b"")
        try:
            query_str = query.decode("utf-8") if isinstance(query, (bytes, bytearray)) else str(query)
        except Exception:
            query_str = ""

        client_ip = None
        if scope.get("client"):
            client_ip = scope["client"][0]

        # Extract User-Agent
        user_agent: Optional[str] = None
        for k, v in scope.get("headers", []) or []:
            if k == b"user-agent":
                try:
                    user_agent = v.decode("utf-8", errors="ignore")
                except Exception:
                    user_agent = None
                break

        status_code_holder = {"value": 500}

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                status_code_holder["value"] = int(message.get("status", 200))
                # add X-Request-ID header
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", rid.encode("utf-8")))
                message["headers"] = headers

            # On final body chunk, log the access line
            if message["type"] == "http.response.body" and not message.get("more_body", False):
                dur_ms = int((time.perf_counter() - start) * 1000)
                self.logger.info(
                    "access",
                    extra={
                        "event": "access",
                        "request_id": rid,
                        "method": method,
                        "path": path,
                        "query": query_str or None,
                        "status_code": status_code_holder["value"],
                        "duration_ms": dur_ms,
                        "client_ip": client_ip,
                        "user_agent": user_agent,
                    },
                )

            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            # reset contextvar
            request_id_var.reset(token)

