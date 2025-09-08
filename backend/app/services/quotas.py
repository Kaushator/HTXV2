from typing import Optional, Tuple

# Placeholder for future DAO-based quotas per API key.
# In the future, read from DB (e.g., table api_keys with columns: key, max_calls, window_sec).


async def get_rate_limit_for_api_key(api_key: str) -> Optional[Tuple[int, int]]:
    """Return (max_calls, window_sec) for a given API key or None if not specified.

    TODO: implement DB query once auth/DAO is available. For now returns None.
    """
    return None

