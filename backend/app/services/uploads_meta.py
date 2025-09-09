from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

try:
    from google.cloud import storage  # type: ignore
except Exception:  # pragma: no cover
    storage = None  # type: ignore


@dataclass
class VerifyResult:
    ok: bool
    size: Optional[int]
    content_type: Optional[str]


async def verify_gcs_object(bucket: str, object_key: str, expected_size: Optional[int], expected_ct: Optional[str]) -> VerifyResult:
    """Verify object exists in GCS and optionally match size/content-type.

    Returns VerifyResult; does not raise if object missing (ok=False).
    """
    if storage is None:
        return VerifyResult(False, None, None)

    client = storage.Client()
    blob = client.bucket(bucket).blob(object_key)
    if not blob.exists():
        return VerifyResult(False, None, None)

    blob.reload()  # load metadata
    size = int(blob.size) if blob.size is not None else None
    ct = blob.content_type

    ok = True
    if expected_size is not None and size is not None and size != expected_size:
        ok = False
    if expected_ct and ct and expected_ct.lower() != ct.lower():
        ok = False

    return VerifyResult(ok, size, ct)

