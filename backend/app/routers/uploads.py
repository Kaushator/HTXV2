import secrets
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ..config import settings
from ..services.uploads import generate_gcs_signed_put_url
from ..services import uploads as uploads_service
from ..services import uploads_meta as uploads_meta

router = APIRouter(prefix="/api/data", tags=["uploads"])


class SignedUrlRequest(BaseModel):
    filename: str = Field(..., description="Имя файла с расширением: .csv или .xlsx")
    content_type: str = Field(..., description="MIME тип: text/csv или application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    size_bytes: Optional[int] = Field(None, ge=0, description="Ожидаемый размер файла в байтах")


class SignedUrlResponse(BaseModel):
    status: str
    method: str
    upload_url: str
    headers: dict
    expires_at: str
    object_key: str
    max_size_bytes: int


@router.post("/upload/request-signed-url", response_model=SignedUrlResponse)
async def request_signed_url(payload: SignedUrlRequest):
    """Request signed URL for CSV/XLSX uploads (stub → GCS).

    Выполняет валидации: расширение файла, content-type, ограничение размера.
    Возвращает заглушку signed URL (домен .invalid), которую позже заменим на GCS.
    """
    name = payload.filename.strip()
    if "." not in name:
        raise HTTPException(status_code=400, detail="Filename must contain an extension")
    ext = name.rsplit(".", 1)[-1].lower()
    if ext not in settings.uploads_allowed_ext:
        raise HTTPException(status_code=400, detail=f"Unsupported file extension: .{ext}")

    ct = payload.content_type.strip().lower()
    if ct not in settings.uploads_allowed_ct:
        raise HTTPException(status_code=400, detail=f"Unsupported content type: {payload.content_type}")

    max_bytes = settings.uploads_max_size_mb * 1024 * 1024
    if payload.size_bytes is not None and payload.size_bytes > max_bytes:
        raise HTTPException(status_code=400, detail=f"File too large: {payload.size_bytes} > {max_bytes} bytes")

    # Object key (stable layout)
    key = f"uploads/{uuid.uuid4().hex}/{name}"
    expires_at_dt = datetime.utcnow() + timedelta(seconds=settings.uploads_url_ttl_sec)
    expires_at = expires_at_dt.isoformat(timespec="seconds") + "Z"

    # If GCS bucket configured, try real signed URL generation
    upload_url: Optional[str] = None
    if settings.uploads_gcs_bucket:
        upload_url = generate_gcs_signed_put_url(
            bucket_name=settings.uploads_gcs_bucket,
            object_key=key,
            content_type=ct,
            expires_seconds=settings.uploads_url_ttl_sec,
        )

    # Fallback to stub if GCS not configured or failed
    if not upload_url:
        token = secrets.token_urlsafe(24)
        upload_url = (
            f"https://upload.invalid/v1/put/{key}?token={token}&expires={int(expires_at_dt.timestamp())}"
        )

    headers = {"Content-Type": payload.content_type}
    return SignedUrlResponse(
        status="ok",
        method="PUT",
        upload_url=upload_url,
        headers=headers,
        expires_at=expires_at,
        object_key=key,
        max_size_bytes=max_bytes,
    )


class UploadCompleteRequest(BaseModel):
    object_key: str = Field(..., description="Ключ объекта в хранилище (например, uploads/<uuid>/file.csv)")
    size_bytes: Optional[int] = Field(None, ge=0)
    content_type: Optional[str] = None


class UploadCompleteResponse(BaseModel):
    status: str
    object_key: str
    verified: bool
    size_bytes: Optional[int] = None
    content_type: Optional[str] = None
    persisted: bool = False


@router.post("/upload/complete", response_model=UploadCompleteResponse)
async def upload_complete(payload: UploadCompleteRequest):
    """Confirm upload completion and optionally verify object in GCS, persisting metadata if DB configured.

    - Если настроен `UPLOADS_GCS_BUCKET`, попытаемся верифицировать существование объекта и сверить размер/Content-Type.
    - Если доступна БД (`DATABASE_URL`), сохраним запись в таблицу `uploads` (best-effort, ошибки сохранения игнорируются в ответе).
    """
    key = payload.object_key.strip()
    if not key:
        raise HTTPException(status_code=400, detail="object_key is required")

    verified = False
    actual_size: Optional[int] = None
    actual_ct: Optional[str] = None

    if settings.uploads_gcs_bucket:
        try:
            res = await uploads_meta.verify_gcs_object(
                bucket=settings.uploads_gcs_bucket,
                object_key=key,
                expected_size=payload.size_bytes,
                expected_ct=payload.content_type,
            )
            verified = res.ok
            actual_size = res.size
            actual_ct = res.content_type
        except Exception:
            verified = False

    persisted = False
    try:
        persisted = await uploads_service.persist_upload_record(
            object_key=key,
            size_bytes=payload.size_bytes if payload.size_bytes is not None else actual_size,
            content_type=payload.content_type or actual_ct,
            verified=verified,
            storage="gcs" if settings.uploads_gcs_bucket else "stub",
        )
    except Exception:
        persisted = False

    return UploadCompleteResponse(
        status="ok",
        object_key=key,
        verified=verified,
        size_bytes=actual_size or payload.size_bytes,
        content_type=actual_ct or payload.content_type,
        persisted=persisted,
    )
