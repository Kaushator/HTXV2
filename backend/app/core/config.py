from pydantic_settings import BaseSettings
from typing import List, Optional
from pydantic import AnyHttpUrl, field_validator
import os


class Settings(BaseSettings):
    """Application settings"""
    
    # Project
    PROJECT_NAME: str = "HTXV2"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"
    API_V1_STR: str = "/api/v1"
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "htxv2"
    POSTGRES_USER: str = "htxv2_user"
    POSTGRES_PASSWORD: str
    DATABASE_URL: Optional[str] = None
    
    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: Optional[str], info) -> str:
        if isinstance(v, str):
            return v
        values = info.data if hasattr(info, 'data') else {}
        return (
            f"postgresql+asyncpg://{values.get('POSTGRES_USER')}:"
            f"{values.get('POSTGRES_PASSWORD')}@{values.get('POSTGRES_HOST')}:"
            f"{values.get('POSTGRES_PORT')}/{values.get('POSTGRES_DB')}"
        )
    
    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    REDIS_URL: Optional[str] = None
    
    @field_validator("REDIS_URL", mode="before")
    @classmethod
    def assemble_redis_connection(cls, v: Optional[str], info) -> str:
        if isinstance(v, str):
            return v
        values = info.data if hasattr(info, 'data') else {}
        return (
            f"redis://{values.get('REDIS_HOST')}:"
            f"{values.get('REDIS_PORT')}/{values.get('REDIS_DB')}"
        )
    
    # CORS
    BACKEND_CORS_ORIGINS: List[AnyHttpUrl] = []
    ALLOWED_HOSTS: List[str] = ["*"]
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    # Google Cloud (Optional for dev environment)
    GOOGLE_CLOUD_PROJECT: Optional[str] = None
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None
    
    # External APIs (Optional for dev environment)
    HTX_API_KEY: Optional[str] = None
    HTX_SECRET_KEY: Optional[str] = None
    COINGECKO_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None
    
    # Celery
    CELERY_BROKER_URL: Optional[str] = None
    CELERY_RESULT_BACKEND: Optional[str] = None
    
    @field_validator("CELERY_BROKER_URL", mode="before")
    @classmethod
    def assemble_celery_broker(cls, v: Optional[str], info) -> str:
        if isinstance(v, str):
            return v
        values = info.data if hasattr(info, 'data') else {}
        return f"redis://{values.get('REDIS_HOST')}:{values.get('REDIS_PORT')}/1"

    @field_validator("CELERY_RESULT_BACKEND", mode="before")
    @classmethod
    def assemble_celery_backend(cls, v: Optional[str], info) -> str:
        if isinstance(v, str):
            return v
        values = info.data if hasattr(info, 'data') else {}
        return f"redis://{values.get('REDIS_HOST')}:{values.get('REDIS_PORT')}/1"
    
    # ML Configuration
    FINGPT_MODEL_PATH: str = "/app/models/fingpt"
    VERTEX_AI_REGION: str = "us-central1"
    LOCAL_LLM_ENABLED: bool = True
    
    # Storage
    GCS_RAW_BUCKET: Optional[str] = None
    GCS_PROCESSED_BUCKET: Optional[str] = None
    GCS_ML_MODELS_BUCKET: Optional[str] = None
    
    # BigQuery
    BIGQUERY_DATASET: str = "htxv2_main"
    
    # MCP Configuration
    MCP_TASK_CLEANUP_INTERVAL: int = 3600  # seconds
    MCP_HEALTH_CHECK_INTERVAL: int = 60    # seconds
    MCP_MAX_WEBSOCKET_CONNECTIONS: int = 1000
    MCP_WEBSOCKET_HEARTBEAT_INTERVAL: int = 30  # seconds
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()