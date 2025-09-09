from __future__ import annotations

from datetime import timedelta
from typing import Optional

try:
    from google.cloud import storage  # type: ignore
except Exception:  # pragma: no cover - library may be absent in some envs
    storage = None  # type: ignore


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

