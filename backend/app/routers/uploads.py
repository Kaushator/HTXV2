from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/data", tags=["uploads"])


@router.post("/upload/request-signed-url")
async def request_signed_url(filename: str, content_type: str = "application/octet-stream"):
    """Request signed URL for CSV/XLSX uploads (pending integration with GCS)."""
    return JSONResponse(
        status_code=501,
        content={
            "status": "not_implemented",
            "endpoint": "request-signed-url",
            "filename": filename,
            "content_type": content_type,
            "todo": "Generate signed URL via GCS (Cloud Storage)",
        },
    )

