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
    htx_ticker_ttl_max: int = int(os.getenv("HTX_TICKER_TTL_MAX", "60"))
    htx_allowed_quotes_raw: str = os.getenv("HTX_ALLOWED_QUOTES", "usdt,usdc,usd")
    # Rate limiting
    htx_rate_limit_max: int = int(os.getenv("HTX_RATE_LIMIT_MAX", "60"))
    htx_rate_limit_window: int = int(os.getenv("HTX_RATE_LIMIT_WINDOW", "60"))  # seconds

    # Uploads (CSV/XLSX signed URL stub)
    uploads_max_size_mb: int = int(os.getenv("UPLOADS_MAX_SIZE_MB", "10"))
    uploads_allowed_ext_raw: str = os.getenv("UPLOADS_ALLOWED_EXT", "csv,xlsx")
    uploads_allowed_ct_raw: str = os.getenv(
        "UPLOADS_ALLOWED_CT",
        "text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
    uploads_url_ttl_sec: int = int(os.getenv("UPLOADS_URL_TTL_SEC", "600"))

    @property
    def htx_allowed_quotes(self) -> list[str]:
        return [q.strip().lower() for q in self.htx_allowed_quotes_raw.split(",") if q.strip()]

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

    @property
    def uploads_allowed_ext(self) -> list[str]:
        return [e.strip().lower() for e in self.uploads_allowed_ext_raw.split(",") if e.strip()]

    @property
    def uploads_allowed_ct(self) -> list[str]:
        return [c.strip().lower() for c in self.uploads_allowed_ct_raw.split(",") if c.strip()]


settings = Settings()
