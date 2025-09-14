from fastapi import APIRouter
from app.api.api_v1.endpoints import auth, users, trading, portfolio, data, mcp, websocket, file_upload

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(trading.router, prefix="/trading", tags=["Trading"])
api_router.include_router(portfolio.router, prefix="/portfolio", tags=["Portfolio"])
api_router.include_router(data.router, prefix="/data", tags=["Data"])
api_router.include_router(mcp.router, prefix="/mcp", tags=["MCP"])
api_router.include_router(file_upload.router, prefix="/files", tags=["File Upload"])
api_router.include_router(websocket.router, tags=["WebSocket"])