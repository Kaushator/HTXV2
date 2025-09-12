from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


logger = logging.getLogger("htxv2.errors")


def _base_error_payload(
    request: Request,
    error: str,
    message: str,
    details: Dict[str, Any] | None = None,
):
    request_id = request.headers.get("X-Request-ID", "")
    return {
        "error": error,
        "message": message,
        "details": details or {},
        "request_id": request_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def register_exception_handlers(app: FastAPI) -> None:
    """Register global exception handlers with a consistent JSON shape."""

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        payload = _base_error_payload(
            request,
            error="validation_error",
            message="Request validation failed",
            details={"errors": exc.errors()},
        )
        return JSONResponse(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, content=payload)

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        # Preserve dict detail if provided (e.g., rate limiter includes retry_after_seconds)
        if isinstance(exc.detail, dict):
            details = exc.detail
            message = details.get("message", exc.detail.get("error", "HTTP error"))
        else:
            details = {}
            message = str(exc.detail) if exc.detail else "HTTP error"

        payload = _base_error_payload(
            request,
            error="http_error",
            message=message,
            details=details,
        )
        return JSONResponse(status_code=exc.status_code, content=payload, headers=exc.headers or None)

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.exception("unhandled_exception", extra={"path": request.url.path})
        payload = _base_error_payload(
            request,
            error="internal_error",
            message="Internal server error",
        )
        return JSONResponse(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, content=payload)

