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
    revoked_at: Optional[str] = None
    revocation_reason: Optional[str] = None


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


async def list_api_keys_paged(active: Optional[bool], limit: int, offset: int) -> Sequence[ApiKeyMeta]:
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    conn = await _connect()
    try:
        if active is None:
            rows = await conn.fetch(
                """
                SELECT id, key_prefix, name, description, rate_limit_per_minute, rate_limit_window_sec, is_active, revoked_at, revocation_reason
                FROM api_keys
                ORDER BY created_at DESC NULLS LAST
                LIMIT $1 OFFSET $2
                """,
                limit,
                offset,
            )
        else:
            rows = await conn.fetch(
                """
                SELECT id, key_prefix, name, description, rate_limit_per_minute, rate_limit_window_sec, is_active, revoked_at, revocation_reason
                FROM api_keys
                WHERE is_active = $1
                ORDER BY created_at DESC NULLS LAST
                LIMIT $2 OFFSET $3
                """,
                active,
                limit,
                offset,
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
            revoked_at=r.get("revoked_at"),
            revocation_reason=r.get("revocation_reason"),
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


async def rotate_api_key(key_id: str) -> Optional[tuple[ApiKeyMeta, str]]:
    """Rotate an API key: deactivate existing key and create a new one with same settings.

    Returns (meta, plaintext) for the new key, or None if key_id not found.
    """
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")

    conn = await _connect()
    try:
        row = await conn.fetchrow(
            """
            SELECT id, name, description, rate_limit_per_minute, rate_limit_window_sec, is_active
            FROM api_keys WHERE id = $1
            """,
            key_id,
        )
        if not row:
            await conn.close()
            return None

        # Deactivate old key
        await conn.execute("UPDATE api_keys SET is_active = FALSE WHERE id = $1", key_id)

        # Create new with same settings
        plaintext = _generate_plaintext_key()
        key_prefix = plaintext.split('.', 1)[0]
        key_hash = _hash_key(plaintext)
        new_id = str(uuid.uuid4())

        await conn.execute(
            """
            INSERT INTO api_keys (id, key_hash, key_prefix, name, description, rate_limit_per_minute, rate_limit_window_sec, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
            """,
            new_id,
            key_hash,
            key_prefix,
            row["name"],
            row["description"],
            row["rate_limit_per_minute"],
            row["rate_limit_window_sec"],
        )
    finally:
        await conn.close()

    meta = ApiKeyMeta(
        id=new_id,
        key_prefix=key_prefix,
        name=row["name"],
        description=row["description"],
        rate_limit_per_minute=row["rate_limit_per_minute"],
        rate_limit_window_sec=row["rate_limit_window_sec"],
        is_active=True,
    )
    return meta, plaintext


async def update_rate_limits(key_id: str, per_minute: Optional[int], window_sec: Optional[int]) -> bool:
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    if per_minute is None and window_sec is None:
        return True
    conn = await _connect()
    try:
        if per_minute is not None and window_sec is not None:
            res = await conn.execute(
                "UPDATE api_keys SET rate_limit_per_minute=$1, rate_limit_window_sec=$2 WHERE id=$3",
                per_minute,
                window_sec,
                key_id,
            )
        elif per_minute is not None:
            res = await conn.execute(
                "UPDATE api_keys SET rate_limit_per_minute=$1 WHERE id=$2",
                per_minute,
                key_id,
            )
        else:
            res = await conn.execute(
                "UPDATE api_keys SET rate_limit_window_sec=$1 WHERE id=$2",
                window_sec,
                key_id,
            )
        return res.endswith(" 1")
    finally:
        await conn.close()


async def delete_api_key(key_id: str, hard: bool = False, reason: Optional[str] = None) -> bool:
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    conn = await _connect()
    try:
        if hard:
            res = await conn.execute("DELETE FROM api_keys WHERE id=$1", key_id)
            return res.endswith(" 1")
        # soft delete (reuse revoke)
        res = await conn.execute(
            "UPDATE api_keys SET is_active=FALSE, revoked_at=NOW(), revocation_reason=$1 WHERE id=$2",
            reason,
            key_id,
        )
        return res.endswith(" 1")
    finally:
        await conn.close()


async def revoke_api_key(key_id: str, reason: Optional[str] = None) -> bool:
    """Revoke (disable) API key by id with a reason."""
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is not configured")
    try:
        conn = await _connect()
        try:
            res = await conn.execute(
                "UPDATE api_keys SET is_active = FALSE, revoked_at = NOW(), revocation_reason = $1 WHERE id = $2",
                reason,
                key_id,
            )
            return res.endswith(" 1")
        finally:
            await conn.close()
    except Exception:
        return False
