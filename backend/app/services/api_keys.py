from __future__ import annotations

import asyncio
import hashlib
import secrets
import string
import uuid
from dataclasses import dataclass
from typing import Optional, Sequence

import asyncpg

from ..config import settings


@dataclass
class ApiKeyMeta:
    id: str
    key_prefix: str
    name: str
    description: Optional[str]
    rate_limit_per_minute: int
    rate_limit_window_sec: int
    is_active: bool


def _hash_key(plaintext: str) -> str:
    return hashlib.sha256(plaintext.encode("utf-8")).hexdigest()


def _generate_plaintext_key(prefix_len: int = 8, body_len: int = 40) -> str:
    alphabet = string.ascii_letters + string.digits
    prefix = ''.join(secrets.choice(alphabet) for _ in range(prefix_len))
    body = secrets.token_urlsafe(body_len)  # produces ~1.33*len chars, good entropy
    return f"{prefix}.{body}"


async def _connect() -> asyncpg.Connection:
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    return await asyncpg.connect(settings.database_url)


async def create_api_key(name: str, description: Optional[str] = None, rate_limit_per_minute: int = 60,
                         rate_limit_window_sec: int = 60) -> tuple[ApiKeyMeta, str]:
    """Create a new API key and return metadata and the plaintext key (show once)."""
    plaintext = _generate_plaintext_key()
    key_prefix = plaintext.split('.', 1)[0]
    key_hash = _hash_key(plaintext)
    key_id = str(uuid.uuid4())

    conn = await _connect()
    try:
        await conn.execute(
            """
            INSERT INTO api_keys (id, key_hash, key_prefix, name, description, rate_limit_per_minute, rate_limit_window_sec, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
            """,
            key_id, key_hash, key_prefix, name, description, rate_limit_per_minute, rate_limit_window_sec,
        )
    finally:
        await conn.close()

    meta = ApiKeyMeta(
        id=key_id,
        key_prefix=key_prefix,
        name=name,
        description=description,
        rate_limit_per_minute=rate_limit_per_minute,
        rate_limit_window_sec=rate_limit_window_sec,
        is_active=True,
    )
    return meta, plaintext


async def list_api_keys() -> Sequence[ApiKeyMeta]:
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    conn = await _connect()
    try:
        rows = await conn.fetch(
            """
            SELECT id, key_prefix, name, description, rate_limit_per_minute, rate_limit_window_sec, is_active
            FROM api_keys ORDER BY created_at DESC NULLS LAST
            """
        )
    finally:
        await conn.close()
    return [
        ApiKeyMeta(
            id=r["id"],
            key_prefix=r["key_prefix"],
            name=r["name"],
            description=r["description"],
            rate_limit_per_minute=r["rate_limit_per_minute"],
            rate_limit_window_sec=r["rate_limit_window_sec"],
            is_active=r["is_active"],
        ) for r in rows
    ]


async def get_quota_for_plaintext_key(plaintext_key: str) -> Optional[tuple[int, int]]:
    """Return (max_calls, window_sec) for provided plaintext api key, or None.

    Does not leak existence via timing: uses direct hash lookup.
    """
    if not settings.database_url:
        return None
    key_hash = _hash_key(plaintext_key)
    conn = await _connect()
    try:
        row = await conn.fetchrow(
            """
            SELECT rate_limit_per_minute, rate_limit_window_sec
            FROM api_keys
            WHERE key_hash = $1 AND is_active = TRUE
            """,
            key_hash,
        )
    finally:
        await conn.close()
    if not row:
        return None
    return int(row["rate_limit_per_minute"]), int(row["rate_limit_window_sec"])


async def touch_api_key_usage(plaintext_key: str) -> None:
    """Update last_used_at for the given plaintext key, if DB configured.

    Best-effort; swallows errors to avoid impacting request latency.
    """
    if not settings.database_url:
        return
    key_hash = _hash_key(plaintext_key)
    try:
        conn = await _connect()
        try:
            await conn.execute(
                "UPDATE api_keys SET last_used_at = NOW() WHERE key_hash = $1",
                key_hash,
            )
        finally:
            await conn.close()
    except Exception:
        return


async def set_api_key_active(key_id: str, active: bool) -> bool:
    """Enable/disable API key by id. Returns True if updated row exists."""
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    try:
        conn = await _connect()
        try:
            res = await conn.execute(
                "UPDATE api_keys SET is_active = $1 WHERE id = $2",
                active,
                key_id,
            )
            # asyncpg returns string like 'UPDATE 1'
            return res.endswith(" 1")
        finally:
            await conn.close()
    except Exception:
        return False
