from fastapi import APIRouter
from app.api.api_v1.endpoints import auth, users, trading, portfolio, data, websocket

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(trading.router, prefix="/trading", tags=["Trading"])
api_router.include_router(portfolio.router, prefix="/portfolio", tags=["Portfolio"])
api_router.include_router(data.router, prefix="/data", tags=["Data"])
api_router.include_router(websocket.router, prefix="/ws", tags=["WebSocket"])