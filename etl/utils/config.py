from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """ETL pipeline settings"""
    
    # Database
    database_url: str = "postgresql+asyncpg://htxv2_user:password@localhost:5432/htxv2"
    
    # Redis
    redis_url: str = "redis://localhost:6379/1"
    
    # Google Cloud
    google_cloud_project: str
    gcs_bucket_raw: str
    gcs_bucket_processed: str
    bigquery_dataset: str = "htxv2_main"
    
    # API Keys
    htx_api_key: Optional[str] = None
    htx_secret_key: Optional[str] = None
    coingecko_api_key: Optional[str] = None
    cryptopanic_api_key: Optional[str] = None
    
    # Pipeline settings
    batch_size: int = 1000
    max_retries: int = 3
    rate_limit_rps: float = 10.0
    
    # Monitoring
    enable_metrics: bool = True
    metrics_port: int = 8001
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


_settings = None


def get_settings() -> Settings:
    """Get settings singleton"""
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings