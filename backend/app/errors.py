import logging
from datetime import datetime
from typing import Any, Dict

from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from .logging_setup import request_id_var

logger = logging.getLogger("htx.api")


def _now_iso() -> str:
    return datetime.utcnow().isoformat(timespec="milliseconds") + "Z"


def _error_payload(code: str, message: str, status: int, request: Request, details: Dict[str, Any] | None = None) -> Dict[str, Any]:
    rid = request_id_var.get()
    return {
        "status": "error",
        "timestamp": _now_iso(),
        "request_id": rid,
        "path": request.url.path,
        "error": {
            "code": code,
            "message": message,
            **({"details": details} if details else {}),
        },
        "http_status": status,
    }


async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    payload = _error_payload(
        code=f"http_{exc.status_code}",
        message=exc.detail if isinstance(exc.detail, str) else "HTTP error",
        status=exc.status_code,
        request=request,
    )
    logger.info("http_exception", extra={"event": "error", "status_code": exc.status_code})
    return JSONResponse(status_code=exc.status_code, content=payload)


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    details = {"errors": exc.errors()}
    payload = _error_payload(
        code="validation_error",
        message="Request validation failed",
        status=422,
        request=request,
        details=details,
    )
    logger.info("validation_error", extra={"event": "error", "status_code": 422})
    return JSONResponse(status_code=422, content=payload)


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    payload = _error_payload(
        code="internal_error",
        message="Internal server error",
        status=500,
        request=request,
    )
    logger.exception("unhandled_exception")
    return JSONResponse(status_code=500, content=payload)


def register_exception_handlers(app) -> None:
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)

