from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from ..config import settings
from ..services import api_keys as svc


router = APIRouter(prefix="/api/keys", tags=["api-keys"], include_in_schema=True)


class CreateKeyRequest(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    rate_limit_per_minute: int = Field(60, ge=1)
    rate_limit_window_sec: int = Field(60, ge=1)


class KeyMetaResponse(BaseModel):
    id: str
    key_prefix: str
    name: str
    description: Optional[str] = None
    rate_limit_per_minute: int
    rate_limit_window_sec: int
    is_active: bool
    revoked_at: Optional[str] = None
    revocation_reason: Optional[str] = None


class CreateKeyResponse(BaseModel):
    meta: KeyMetaResponse
    key: str  # plaintext, show-once


@router.post("/", response_model=CreateKeyResponse)
async def create_key(payload: CreateKeyRequest):
    if not settings.database_url:
        # No DB configured — keep API discoverable but signal not implemented in this env
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")

    meta, plaintext = await svc.create_api_key(
        name=payload.name,
        description=payload.description,
        rate_limit_per_minute=payload.rate_limit_per_minute,
        rate_limit_window_sec=payload.rate_limit_window_sec,
    )
    return CreateKeyResponse(
        meta=KeyMetaResponse(**meta.__dict__),
        key=plaintext,
    )


@router.get("/", response_model=list[KeyMetaResponse])
async def list_keys(
    active: Optional[bool] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    rows = await svc.list_api_keys_paged(active=active, limit=limit, offset=offset)
    return [KeyMetaResponse(**r.__dict__) for r in rows]


class ToggleResponse(BaseModel):
    ok: bool


@router.post("/{key_id}/disable", response_model=ToggleResponse)
async def disable_key(key_id: str):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    ok = await svc.set_api_key_active(key_id, False)
    if not ok:
        raise HTTPException(status_code=404, detail="Key not found")
    return ToggleResponse(ok=True)


@router.post("/{key_id}/enable", response_model=ToggleResponse)
async def enable_key(key_id: str):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    ok = await svc.set_api_key_active(key_id, True)
    if not ok:
        raise HTTPException(status_code=404, detail="Key not found")
    return ToggleResponse(ok=True)


class RotateResponse(BaseModel):
    meta: KeyMetaResponse
    key: str


@router.post("/{key_id}/rotate", response_model=RotateResponse)
async def rotate_key(key_id: str):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    res = await svc.rotate_api_key(key_id)
    if not res:
        raise HTTPException(status_code=404, detail="Key not found")
    meta, plaintext = res
    return RotateResponse(meta=KeyMetaResponse(**meta.__dict__), key=plaintext)


class RevokeRequest(BaseModel):
    reason: Optional[str] = Field(None, max_length=500)


@router.post("/{key_id}/revoke", response_model=ToggleResponse)
async def revoke_key(key_id: str, payload: RevokeRequest):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    ok = await svc.revoke_api_key(key_id, payload.reason)
    if not ok:
        raise HTTPException(status_code=404, detail="Key not found")
    return ToggleResponse(ok=True)


class UpdateLimitsRequest(BaseModel):
    rate_limit_per_minute: Optional[int] = Field(None, ge=1)
    rate_limit_window_sec: Optional[int] = Field(None, ge=1)


@router.patch("/{key_id}", response_model=ToggleResponse)
async def update_limits(key_id: str, payload: UpdateLimitsRequest):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    ok = await svc.update_rate_limits(key_id, payload.rate_limit_per_minute, payload.rate_limit_window_sec)
    if not ok:
        raise HTTPException(status_code=404, detail="Key not found")
    return ToggleResponse(ok=True)


@router.delete("/{key_id}", response_model=ToggleResponse)
async def delete_key(key_id: str, hard: bool = False, reason: Optional[str] = None):
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    ok = await svc.delete_api_key(key_id, hard=hard, reason=reason)
    if not ok:
        raise HTTPException(status_code=404, detail="Key not found")
    return ToggleResponse(ok=True)
