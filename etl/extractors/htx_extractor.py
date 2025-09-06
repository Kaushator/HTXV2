import asyncio
import aiohttp
import json
from typing import Dict, List, Optional
from datetime import datetime
import structlog
from dataclasses import dataclass

from utils.config import get_settings
from utils.rate_limiter import RateLimiter

logger = structlog.get_logger(__name__)


@dataclass
class PriceData:
    """Price data structure"""
    symbol: str
    price: float
    volume_24h: float
    high_24h: float
    low_24h: float
    price_change_24h: float
    timestamp: datetime
    exchange: str = "htx"
    data_source: str = "htx_api"


class HTXExtractor:
    """HTX (Huobi) data extractor"""
    
    def __init__(self):
        self.settings = get_settings()
        self.base_url = "https://api.huobi.pro"
        self.rate_limiter = RateLimiter(requests_per_second=10)
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def get_all_symbols(self) -> List[str]:
        """Get all available trading symbols"""
        async with self.rate_limiter:
            url = f"{self.base_url}/v1/common/symbols"
            
            try:
                async with self.session.get(url) as response:
                    data = await response.json()
                    
                    if data.get("status") == "ok":
                        symbols = [item["symbol"] for item in data["data"] 
                                 if item["state"] == "online"]
                        logger.info(f"Retrieved {len(symbols)} symbols from HTX")
                        return symbols
                    else:
                        logger.error(f"HTX API error: {data}")
                        return []
                        
            except Exception as e:
                logger.error(f"Error fetching symbols: {e}")
                return []
    
    async def get_ticker_data(self, symbol: str) -> Optional[PriceData]:
        """Get ticker data for a specific symbol"""
        async with self.rate_limiter:
            url = f"{self.base_url}/market/detail/merged"
            params = {"symbol": symbol}
            
            try:
                async with self.session.get(url, params=params) as response:
                    data = await response.json()
                    
                    if data.get("status") == "ok" and "tick" in data:
                        tick = data["tick"]
                        
                        return PriceData(
                            symbol=symbol.upper(),
                            price=float(tick["close"]),
                            volume_24h=float(tick["vol"]),
                            high_24h=float(tick["high"]),
                            low_24h=float(tick["low"]),
                            price_change_24h=float(tick["close"]) - float(tick["open"]),
                            timestamp=datetime.now(),
                            exchange="htx",
                            data_source="htx_api"
                        )
                    else:
                        logger.warning(f"No data for symbol {symbol}: {data}")
                        return None
                        
            except Exception as e:
                logger.error(f"Error fetching ticker for {symbol}: {e}")
                return None
    
    async def get_batch_ticker_data(self, symbols: List[str]) -> List[PriceData]:
        """Get ticker data for multiple symbols"""
        logger.info(f"Fetching ticker data for {len(symbols)} symbols")
        
        tasks = [self.get_ticker_data(symbol) for symbol in symbols]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        price_data = []
        for result in results:
            if isinstance(result, PriceData):
                price_data.append(result)
            elif isinstance(result, Exception):
                logger.error(f"Exception in batch ticker fetch: {result}")
        
        logger.info(f"Successfully fetched {len(price_data)} ticker records")
        return price_data
    
    async def get_kline_data(self, symbol: str, period: str = "1day", size: int = 200) -> List[Dict]:
        """Get historical kline/candlestick data"""
        async with self.rate_limiter:
            url = f"{self.base_url}/market/history/kline"
            params = {
                "symbol": symbol,
                "period": period,
                "size": size
            }
            
            try:
                async with self.session.get(url, params=params) as response:
                    data = await response.json()
                    
                    if data.get("status") == "ok":
                        return data["data"]
                    else:
                        logger.warning(f"No kline data for {symbol}: {data}")
                        return []
                        
            except Exception as e:
                logger.error(f"Error fetching kline for {symbol}: {e}")
                return []
    
    async def extract_current_prices(self, target_symbols: Optional[List[str]] = None) -> List[PriceData]:
        """Extract current prices for all or specified symbols"""
        logger.info("Starting HTX price extraction")
        
        if target_symbols is None:
            symbols = await self.get_all_symbols()
            # Filter to major trading pairs for now
            target_symbols = [s for s in symbols if s.endswith("usdt")][:50]
        
        price_data = await self.get_batch_ticker_data(target_symbols)
        
        logger.info(f"HTX extraction completed: {len(price_data)} records")
        return price_data


async def main():
    """Test the HTX extractor"""
    async with HTXExtractor() as extractor:
        # Test with a few symbols
        test_symbols = ["btcusdt", "ethusdt", "adausdt"]
        data = await extractor.extract_current_prices(test_symbols)
        
        for item in data:
            print(f"{item.symbol}: ${item.price:,.2f}")


if __name__ == "__main__":
    asyncio.run(main())