from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, HTTPException
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
async def list_keys():
    if not settings.database_url:
        raise HTTPException(status_code=501, detail="API keys require DATABASE_URL configuration")
    rows = await svc.list_api_keys()
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
