import httpx
import asyncio
from typing import Dict, List, Optional
from datetime import datetime
import logging
from app.services.api_key_service import ApiKeyService
from app.core.exceptions import QuotaExceededException, APIKeyNotFoundException, ExternalAPIException
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

class CoinGeckoService:
    """Service for integrating with CoinGecko API"""
    
    def __init__(self, db: Session):
        self.db = db
        self.api_key_service = ApiKeyService(db)
        self.base_url = "https://api.coingecko.com/api/v3"
        self.pro_base_url = "https://pro-api.coingecko.com/api/v3"
    
    async def _get_api_key(self) -> Optional[str]:
        """Get an available CoinGecko API key"""
        api_key = await self.api_key_service.get_available_key("coingecko")
        if not api_key:
            raise APIKeyNotFoundException("coingecko")
        return api_key.api_key
    
    async def _make_request(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Make authenticated request to CoinGecko API"""
        try:
            api_key_obj = await self.api_key_service.get_available_key("coingecko")
            if not api_key_obj:
                raise APIKeyNotFoundException("coingecko")
            
            # Use pro API if we have a real API key, otherwise use free API
            if api_key_obj.api_key and api_key_obj.api_key != "demo-key":
                base_url = self.pro_base_url
                headers = {"x-cg-pro-api-key": api_key_obj.api_key}
            else:
                base_url = self.base_url
                headers = {}
            
            url = f"{base_url}{endpoint}"
            
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params, headers=headers, timeout=30.0)
                
                if response.status_code == 429:
                    raise QuotaExceededException("coingecko", api_key_obj.quota_limit)
                elif response.status_code != 200:
                    raise ExternalAPIException("coingecko", response.status_code, response.text)
                
                # Update quota usage
                await self.api_key_service.use_quota(api_key_obj, 1, 0.0)
                
                return response.json()
                
        except httpx.TimeoutException:
            raise ExternalAPIException("coingecko", 408, "Request timeout")
        except httpx.RequestError as e:
            raise ExternalAPIException("coingecko", 500, str(e))
    
    async def get_price(self, symbols: List[str], vs_currency: str = "usd") -> Dict[str, float]:
        """Get current prices for cryptocurrencies"""
        try:
            params = {
                "ids": ",".join(symbols),
                "vs_currencies": vs_currency,
                "include_24hr_change": "true"
            }
            
            data = await self._make_request("/simple/price", params)
            
            # Transform response to match our format
            result = {}
            for symbol in symbols:
                if symbol.lower() in data:
                    symbol_data = data[symbol.lower()]
                    result[symbol.upper()] = {
                        "price": symbol_data.get(vs_currency, 0),
                        "change_24h": symbol_data.get(f"{vs_currency}_24h_change", 0),
                        "timestamp": datetime.utcnow().isoformat(),
                        "source": "coingecko"
                    }
            
            return result
            
        except Exception as e:
            logger.error(f"Error getting prices from CoinGecko: {e}")
            raise
    
    async def get_market_data(self, symbol: str, vs_currency: str = "usd") -> Dict:
        """Get detailed market data for a cryptocurrency"""
        try:
            params = {
                "localization": "false",
                "tickers": "false",
                "market_data": "true",
                "community_data": "false",
                "developer_data": "false",
                "sparkline": "false"
            }
            
            data = await self._make_request(f"/coins/{symbol.lower()}", params)
            
            market_data = data.get("market_data", {})
            
            return {
                "symbol": symbol.upper(),
                "name": data.get("name"),
                "price": market_data.get("current_price", {}).get(vs_currency, 0),
                "market_cap": market_data.get("market_cap", {}).get(vs_currency, 0),
                "volume_24h": market_data.get("total_volume", {}).get(vs_currency, 0),
                "price_change_24h": market_data.get("price_change_percentage_24h", 0),
                "high_24h": market_data.get("high_24h", {}).get(vs_currency, 0),
                "low_24h": market_data.get("low_24h", {}).get(vs_currency, 0),
                "circulating_supply": market_data.get("circulating_supply", 0),
                "total_supply": market_data.get("total_supply", 0),
                "timestamp": datetime.utcnow().isoformat(),
                "source": "coingecko"
            }
            
        except Exception as e:
            logger.error(f"Error getting market data from CoinGecko for {symbol}: {e}")
            raise
    
    async def get_trending(self) -> List[Dict]:
        """Get trending cryptocurrencies"""
        try:
            data = await self._make_request("/search/trending")
            
            trending = []
            for coin in data.get("coins", []):
                coin_data = coin.get("item", {})
                trending.append({
                    "symbol": coin_data.get("symbol", "").upper(),
                    "name": coin_data.get("name"),
                    "market_cap_rank": coin_data.get("market_cap_rank"),
                    "score": coin_data.get("score", 0),
                    "timestamp": datetime.utcnow().isoformat(),
                    "source": "coingecko"
                })
            
            return trending
            
        except Exception as e:
            logger.error(f"Error getting trending data from CoinGecko: {e}")
            raise
    
    async def ping(self) -> bool:
        """Check if CoinGecko API is available"""
        try:
            await self._make_request("/ping")
            return True
        except Exception:
            return False