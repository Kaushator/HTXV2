from pydantic_settings import BaseSettings
from pydantic import AnyHttpUrl, field_validator
from typing import List, Optional
import os


class Settings(BaseSettings):
    app_name: str = "HTX Interface v2 API"
    version: str = os.getenv("API_VERSION", "0.1.0")

    # Backend integrations
    database_url: Optional[str] = os.getenv("DATABASE_URL")
    redis_url: Optional[str] = os.getenv("REDIS_URL")
    fingpt_base: Optional[str] = os.getenv("FINGPT_BASE", "http://localhost:8055")
    # HTX API
    htx_api_base: str = os.getenv("HTX_API_BASE", "https://api.huobi.pro")
    htx_ticker_ttl: int = int(os.getenv("HTX_TICKER_TTL", "5"))  # seconds

    # CORS
    cors_origins: List[AnyHttpUrl] = []

    @field_validator("cors_origins", mode="before")
    @classmethod
    def split_origins(cls, v):  # type: ignore[override]
        if not v:
            # sensible defaults for local dev
            return [
                "http://localhost:3000",
                "http://localhost:3001",
            ]
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v


settings = Settings()
