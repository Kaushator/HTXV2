from typing import Optional, Tuple


async def get_rate_limit_for_api_key(api_key: str) -> Optional[Tuple[int, int]]:
    """Return (max_calls, window_sec) for a given API key or None if not specified.

    Looks up by SHA-256 hash in the `api_keys` table when DATABASE_URL configured; otherwise returns None.
    """
    try:
        from .api_keys import get_quota_for_plaintext_key

        return await get_quota_for_plaintext_key(api_key)
    except Exception:
        # On any error (no DB, network, etc.) gracefully fall back to defaults
        return None
