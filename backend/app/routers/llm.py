from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/llm", tags=["llm"])


@router.post("/predict/{symbol}")
async def llm_predict(symbol: str):
    """LLM prediction via FinGPT/OpenAI/Vertex (pending integration)."""
    return JSONResponse(
        status_code=501,
        content={
            "status": "not_implemented",
            "symbol": symbol,
            "todo": "Route to FinGPT (local) or other providers",
        },
    )

