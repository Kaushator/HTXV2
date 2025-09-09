from __future__ import annotations

import uuid
from datetime import timedelta, datetime
from typing import Optional

try:
    from google.cloud import storage  # type: ignore
except Exception:  # pragma: no cover - library may be absent in some envs
    storage = None  # type: ignore

from ..config import settings
import asyncpg


def generate_gcs_signed_put_url(
    bucket_name: str,
    object_key: str,
    content_type: str,
    expires_seconds: int,
) -> Optional[str]:
    """Generate a GCS V4 Signed URL for PUT uploads.

    Returns None if google-cloud-storage is unavailable or generation fails.
    """
    if storage is None:
        return None

    try:
        client = storage.Client()  # Uses ADC / env credentials
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(object_key)

        url = blob.generate_signed_url(
            version="v4",
            expiration=timedelta(seconds=expires_seconds),
            method="PUT",
            content_type=content_type,
        )
        return url
    except Exception:
        return None


async def persist_upload_record(
    object_key: str,
    size_bytes: Optional[int],
    content_type: Optional[str],
    verified: bool,
    storage: str,
) -> bool:
    """Persist upload metadata if DATABASE_URL configured. Returns True if saved.

    Best-effort: on any error returns False without raising.
    """
    if not settings.database_url:
        return False
    try:
        conn = await asyncpg.connect(settings.database_url)
        try:
            rec_id = str(uuid.uuid4())
            verified_at = datetime.utcnow() if verified else None
            await conn.execute(
                """
                INSERT INTO uploads (id, object_key, content_type, size_bytes, verified, storage, verified_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                """,
                rec_id,
                object_key,
                content_type,
                size_bytes,
                verified,
                storage,
                verified_at,
            )
            return True
        finally:
            await conn.close()
    except Exception:
        return False
