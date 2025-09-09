from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import logging
import time
import uuid

from app.core.config import settings
from app.core.security import get_current_user
from app.core.exceptions import global_exception_handler
from app.api.api_v1.api import api_router
from app.db.session import engine
from app.models import Base


# Configure structured logging
class StructuredFormatter(logging.Formatter):
    def format(self, record):
        import json
        import datetime
        
        log_data = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        # Add extra fields if present
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        if hasattr(record, 'endpoint'):
            log_data['endpoint'] = record.endpoint
        if hasattr(record, 'method'):
            log_data['method'] = record.method
        if hasattr(record, 'status_code'):
            log_data['status_code'] = record.status_code
        if hasattr(record, 'duration_ms'):
            log_data['duration_ms'] = record.duration_ms
            
        return json.dumps(log_data)

# Set up logging
handler = logging.StreamHandler()
handler.setFormatter(StructuredFormatter())
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper()),
    handlers=[handler]
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("Starting up HTXV2 backend...")
    
    # Create database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    logger.info("Database tables created successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down HTXV2 backend...")
    await engine.dispose()


# Create FastAPI application
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="HTXV2 Cryptocurrency Trading Platform API",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# Add global exception handler
app.add_exception_handler(Exception, global_exception_handler)

# Add request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Middleware to log all HTTP requests with structured logging"""
    # Generate unique request ID
    request_id = str(uuid.uuid4())
    
    # Add request ID to request state
    request.state.request_id = request_id
    
    start_time = time.time()
    
    # Log request
    logger.info(
        "HTTP request started",
        extra={
            "request_id": request_id,
            "method": request.method,
            "endpoint": str(request.url),
            "client_ip": request.client.host if request.client else None,
            "user_agent": request.headers.get("user-agent"),
        }
    )
    
    try:
        response = await call_next(request)
        
        # Calculate duration
        duration_ms = round((time.time() - start_time) * 1000, 2)
        
        # Log response
        logger.info(
            "HTTP request completed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "endpoint": str(request.url),
                "status_code": response.status_code,
                "duration_ms": duration_ms,
            }
        )
        
        # Add request ID to response headers
        response.headers["X-Request-ID"] = request_id
        
        return response
        
    except Exception as e:
        duration_ms = round((time.time() - start_time) * 1000, 2)
        
        logger.error(
            "HTTP request failed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "endpoint": str(request.url),
                "duration_ms": duration_ms,
                "error": str(e),
            }
        )
        raise

# Add CORS middleware
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Add trusted host middleware for production
if not settings.DEBUG:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.ALLOWED_HOSTS
    )


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "HTXV2 API",
        "version": "1.0.0",
        "status": "running",
        "environment": settings.ENVIRONMENT
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0"
    }


# Include API routes
app.include_router(api_router, prefix=settings.API_V1_STR)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )