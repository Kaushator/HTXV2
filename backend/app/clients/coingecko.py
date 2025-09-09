from __future__ import annotations

import httpx
from typing import Any, Dict


BASE = "https://api.coingecko.com/api/v3"


async def get_coin(coin_id: str) -> Dict[str, Any]:
    """Fetch coin details from CoinGecko with minimal fields.

    Raises httpx.HTTPStatusError for non-2xx/3xx responses.
    """
    url = f"{BASE}/coins/{coin_id}?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false"
    async with httpx.AsyncClient(timeout=5.0) as client:
        r = await client.get(url)
        r.raise_for_status()
        data = r.json()
        # Select a compact subset
        market = data.get("market_data", {})
        current_price = (market.get("current_price") or {}).get("usd")
        return {
            "provider": "CoinGecko",
            "id": data.get("id"),
            "symbol": data.get("symbol"),
            "name": data.get("name"),
            "price_usd": current_price,
        }

