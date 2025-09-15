from __future__ import annotations

import logging
from typing import Any, Dict, Optional

try:
    import httpx
except Exception:  # pragma: no cover
    httpx = None  # type: ignore

from app.core.config import settings


class FinGPTService:
    """Service wrapper for interacting with local ML model server (FinGPT).

    Provides minimal interface and graceful fallbacks when ML service is absent.
    """

    def __init__(self, base_url: Optional[str] = None) -> None:
        self.logger = logging.getLogger("htxv2.fingpt")
        self.base_url = base_url or settings.ML_SERVICE_URL or "http://localhost:8080"

    async def _client(self) -> Optional["httpx.AsyncClient"]:
        if httpx is None or not self.base_url:
            return None
        return httpx.AsyncClient(base_url=self.base_url, timeout=30.0)

    async def validate_model(self) -> Dict[str, Any]:
        """Return model/server health info if available, else fallback info."""
        client = await self._client()
        if not client:
            return {"status": "unavailable", "reason": "httpx or base_url missing"}
        async with client as c:
            try:
                r = await c.get("/health")
                return r.json()
            except Exception as e:  # pragma: no cover
                self.logger.warning("FinGPT health check failed: %s", e)
                return {"status": "unavailable", "error": str(e)}

    async def load_model(self) -> Dict[str, Any]:
        """Trigger model (re)load if supported by server."""
        client = await self._client()
        if not client:
            return {"status": "skipped"}
        async with client as c:
            try:
                r = await c.post("/models/reload")
                return r.json()
            except Exception as e:  # pragma: no cover
                self.logger.error("FinGPT reload failed: %s", e)
                return {"status": "error", "error": str(e)}

    async def generate_signal(self, prompt: str, **kwargs: Any) -> Dict[str, Any]:
        """Generate a trading signal from prompt/context using the model server."""
        client = await self._client()
        if not client:
            # Minimal offline fallback
            return {
                "content": "Signal unavailable (offline)",
                "confidence": 0.0,
                "model_used": "offline",
            }
        payload = {
            "prompt": prompt,
            **{k: v for k, v in kwargs.items() if v is not None},
        }
        async with client as c:
            r = await c.post("/generate", json=payload)
            r.raise_for_status()
            return r.json()

    async def get_sentiment(
        self, symbol: str, market_data: Dict[str, Any], context: Optional[str] = None
    ) -> Dict[str, Any]:
        """Ask the model server for a financial analysis for given symbol/market data."""
        client = await self._client()
        if not client:
            return {
                "content": "Analysis unavailable (offline)",
                "confidence": 0.0,
                "model_used": "offline",
            }
        payload = {"symbol": symbol, "market_data": market_data, "context": context}
        async with client as c:
            r = await c.post("/analyze/financial", json=payload)
            r.raise_for_status()
            return r.json()
