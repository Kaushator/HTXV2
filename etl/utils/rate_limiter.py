import asyncio
from typing import AsyncIterator
import structlog

logger = structlog.get_logger(__name__)


class RateLimiter:
    """Async rate limiter to control API request frequency"""
    
    def __init__(self, requests_per_second: float):
        self.delay = 1.0 / requests_per_second
        self.last_request = 0.0
    
    async def __aenter__(self):
        current_time = asyncio.get_event_loop().time()
        time_since_last = current_time - self.last_request
        
        if time_since_last < self.delay:
            sleep_time = self.delay - time_since_last
            await asyncio.sleep(sleep_time)
        
        self.last_request = asyncio.get_event_loop().time()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass


def chunk_list(lst: list, chunk_size: int) -> AsyncIterator[list]:
    """Split a list into chunks of specified size"""
    for i in range(0, len(lst), chunk_size):
        yield lst[i:i + chunk_size]


async def retry_on_failure(func, max_retries: int = 3, delay: float = 1.0):
    """Retry a function on failure with exponential backoff"""
    for attempt in range(max_retries):
        try:
            return await func()
        except Exception as e:
            if attempt == max_retries - 1:
                logger.error(f"Function failed after {max_retries} attempts: {e}")
                raise
            
            wait_time = delay * (2 ** attempt)
            logger.warning(f"Attempt {attempt + 1} failed: {e}. Retrying in {wait_time}s")
            await asyncio.sleep(wait_time)