from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
import logging
import traceback
from typing import Union

logger = logging.getLogger(__name__)

# Error codes mapping
ERROR_CODES = {
    400: "BAD_REQUEST",
    401: "UNAUTHORIZED", 
    403: "FORBIDDEN",
    404: "NOT_FOUND",
    422: "VALIDATION_ERROR",
    429: "RATE_LIMIT_EXCEEDED",
    500: "INTERNAL_SERVER_ERROR",
    503: "SERVICE_UNAVAILABLE"
}

async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Global exception handler for the application"""
    
    # Log the exception
    logger.error(f"Unhandled exception: {exc}")
    logger.error(f"Request: {request.method} {request.url}")
    logger.error(f"Traceback: {traceback.format_exc()}")
    
    # Handle HTTPException
    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "error": {
                    "code": ERROR_CODES.get(exc.status_code, "UNKNOWN_ERROR"),
                    "message": exc.detail,
                    "status_code": exc.status_code
                },
                "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
                "path": str(request.url)
            }
        )
    
    # Handle validation errors
    if hasattr(exc, "errors"):  # Pydantic validation error
        return JSONResponse(
            status_code=422,
            content={
                "success": False,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Validation failed",
                    "details": exc.errors(),
                    "status_code": 422
                },
                "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
                "path": str(request.url)
            }
        )
    
    # Handle database errors
    if "sqlalchemy" in str(type(exc)).lower():
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "error": {
                    "code": "DATABASE_ERROR",
                    "message": "Database operation failed",
                    "status_code": 500
                },
                "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
                "path": str(request.url)
            }
        )
    
    # Handle API key quota exceeded
    if "quota" in str(exc).lower():
        return JSONResponse(
            status_code=429,
            content={
                "success": False,
                "error": {
                    "code": "QUOTA_EXCEEDED",
                    "message": "API quota exceeded. Please try again later.",
                    "status_code": 429
                },
                "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
                "path": str(request.url)
            }
        )
    
    # Generic server error
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected error occurred",
                "status_code": 500
            },
            "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
            "path": str(request.url)
        }
    )

# Custom exceptions
class QuotaExceededException(Exception):
    """Exception raised when API quota is exceeded"""
    def __init__(self, service: str, quota_limit: int):
        self.service = service
        self.quota_limit = quota_limit
        super().__init__(f"Quota exceeded for {service}. Limit: {quota_limit}")

class APIKeyNotFoundException(Exception):
    """Exception raised when no valid API key is found"""
    def __init__(self, service: str):
        self.service = service
        super().__init__(f"No valid API key found for service: {service}")

class ExternalAPIException(Exception):
    """Exception raised when external API calls fail"""
    def __init__(self, service: str, status_code: int, message: str):
        self.service = service
        self.status_code = status_code
        self.message = message
        super().__init__(f"External API error from {service}: {status_code} - {message}")