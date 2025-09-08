from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/news", tags=["news"])


@router.get("/cryptopanic")
async def cryptopanic_news():
    """CryptoPanic news feed with ML filtering (pending integration)."""
    return JSONResponse(
        status_code=501,
        content={
            "status": "not_implemented",
            "provider": "CryptoPanic",
            "todo": "Fetch news and apply ML filters",
        },
    )

