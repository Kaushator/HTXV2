from __future__ import annotations

from typing import Optional, Tuple
from fastapi import Request


def extract_api_key(request: Request) -> Tuple[Optional[str], Optional[str]]:
    """Extract plaintext API key from query/header and return (key, prefix).

    - Query parameter: api_key
    - Header: X-API-Key
    Returns (None, None) if not present.
    """
    # Query first
    key = request.query_params.get("api_key")
    if not key:
        key = request.headers.get("X-API-Key")
    if not key:
        return None, None
    prefix = key.split(".", 1)[0] if "." in key else None
    return key, prefix

