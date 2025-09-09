import secrets
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ..config import settings

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

    # Generate stub signed URL
    key = f"uploads/{uuid.uuid4().hex}/{name}"
    token = secrets.token_urlsafe(24)
    expires_at_dt = datetime.utcnow() + timedelta(seconds=settings.uploads_url_ttl_sec)
    expires_at = expires_at_dt.isoformat(timespec="seconds") + "Z"
    # Use .invalid TLD to ensure the URL is non-routable in production
    upload_url = f"https://upload.invalid/v1/put/{key}?token={token}&expires={int(expires_at_dt.timestamp())}"

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
