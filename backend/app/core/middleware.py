import logging
import time
import uuid
from typing import Callable

from fastapi import Request, Response


async def logging_middleware(request: Request, call_next: Callable) -> Response:
    """Structured logging middleware with correlation ID and timing."""
    logger = logging.getLogger("htxv2.request")
    start = time.time()
    # Correlation ID from headers or generate a new one
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

    try:
        response = await call_next(request)
    except Exception as exc:  # pragma: no cover - passthrough to default handlers
        duration_ms = (time.time() - start) * 1000
        logger.exception(
            "request_error",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "query": str(request.url.query),
                "duration_ms": round(duration_ms, 2),
            },
        )
        raise

    duration_ms = (time.time() - start) * 1000
    # Set correlation id on response
    response.headers["X-Request-ID"] = request_id

    logger.info(
        "request",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "query": str(request.url.query),
            "status_code": response.status_code,
            "duration_ms": round(duration_ms, 2),
        },
    )

    return response

