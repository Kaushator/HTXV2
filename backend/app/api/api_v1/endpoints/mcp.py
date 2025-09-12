from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import json
from datetime import datetime, timezone

from app.core.security import get_current_active_user
from app.db.session import get_db
from app.models.user import User
from app.services.mcp_service import MCPService
from app.schemas.mcp import (
    SystemHealth, TaskInfo, TaskRequest, TaskResponse,
    WebSocketMessage, MarketDataUpdate, TradingSignalUpdate, PortfolioUpdate
)

router = APIRouter()


async def get_mcp_service(db: AsyncSession = Depends(get_db)) -> MCPService:
    """Dependency to get MCP service instance"""
    service = MCPService(db)
    await service.initialize()
    return service


@router.get("/health", response_model=SystemHealth)
async def get_system_health(
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Get system health status for all dependencies"""
    return await mcp_service.check_system_health()


@router.get("/status", response_model=SystemHealth)
async def get_status(
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service),
):
    """Alias for health endpoint for compatibility with tests/tools."""
    return await mcp_service.check_system_health()


@router.get("/tools")
async def get_tools():
    """List supported MCP tools/operations for clients and tests."""
    return {
        "websocket": {"endpoint": "/api/v1/mcp/ws", "auth": "JWT bearer in first message"},
        "endpoints": [
            {"method": "GET", "path": "/api/v1/mcp/health"},
            {"method": "GET", "path": "/api/v1/mcp/status"},
            {"method": "GET", "path": "/api/v1/mcp/tasks"},
            {"method": "GET", "path": "/api/v1/mcp/tasks/{task_id}"},
            {"method": "POST", "path": "/api/v1/mcp/tasks"},
            {"method": "POST", "path": "/api/v1/mcp/broadcast/market-data"},
            {"method": "POST", "path": "/api/v1/mcp/broadcast/trading-signal"},
            {"method": "POST", "path": "/api/v1/mcp/broadcast/portfolio-update"},
        ],
        "messages": ["ping", "get_health", "get_tasks"],
    }


@router.get("/tasks", response_model=List[TaskInfo])
async def get_active_tasks(
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Get list of active background tasks"""
    return await mcp_service.get_active_tasks()


@router.get("/tasks/{task_id}", response_model=TaskInfo)
async def get_task_status(
    task_id: str,
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Get status of a specific task"""
    task_info = await mcp_service.get_task_status(task_id)
    if not task_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    return task_info


@router.post("/tasks", response_model=TaskResponse)
async def schedule_task(
    task_request: TaskRequest,
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Schedule a new background task"""
    try:
        task_id = await mcp_service.schedule_task(
            task_name=task_request.task_name,
            parameters=task_request.parameters
        )
        
        return TaskResponse(
            task_id=task_id,
            status="pending",
            message=f"Task '{task_request.task_name}' scheduled successfully"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to schedule task: {str(e)}"
        )


@router.post("/broadcast/market-data")
async def broadcast_market_data(
    market_data: MarketDataUpdate,
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Broadcast market data update to all connected clients"""
    # Only allow superusers to broadcast data
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only superusers can broadcast market data"
        )
    
    await mcp_service.broadcast_market_data(market_data)
    return {"message": "Market data broadcasted successfully"}


@router.post("/broadcast/trading-signal")
async def broadcast_trading_signal(
    signal: TradingSignalUpdate,
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Broadcast trading signal to all connected clients"""
    # Only allow superusers to broadcast signals
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only superusers can broadcast trading signals"
        )
    
    await mcp_service.broadcast_trading_signal(signal)
    return {"message": "Trading signal broadcasted successfully"}


@router.post("/broadcast/portfolio-update")
async def broadcast_portfolio_update(
    portfolio: PortfolioUpdate,
    current_user: User = Depends(get_current_active_user),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """Broadcast portfolio update to specific user"""
    # Users can only broadcast their own portfolio updates, superusers can broadcast any
    if not current_user.is_superuser and portfolio.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only broadcast your own portfolio updates"
        )
    
    await mcp_service.broadcast_portfolio_update(portfolio)
    return {"message": "Portfolio update broadcasted successfully"}


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    db: AsyncSession = Depends(get_db)
):
    """WebSocket endpoint for real-time communication"""
    await websocket.accept()
    
    # Get MCP service
    mcp_service = MCPService(db)
    await mcp_service.initialize()
    
    # Authenticate WebSocket connection
    user = None
    try:
        # Wait for authentication message
        auth_message = await websocket.receive_text()
        auth_data = json.loads(auth_message)
        
        if auth_data.get("type") != "auth":
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "First message must be authentication"
            }))
            await websocket.close()
            return
        
        token = auth_data.get("token")
        if not token:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "Authentication token required"
            }))
            await websocket.close()
            return
        
        # Verify token and get user (simplified for this implementation)
        from app.core.security import verify_token
        from app.services.user_service import UserService
        
        payload = verify_token(token)
        if not payload:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "Invalid authentication token"
            }))
            await websocket.close()
            return
        
        user_id = payload.get("sub")
        if not user_id:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "Invalid token payload"
            }))
            await websocket.close()
            return
        
        user_service = UserService(db)
        user = await user_service.get_user(int(user_id))
        
        if not user or not user.is_active:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "User not found or inactive"
            }))
            await websocket.close()
            return
        
        # Send authentication success
        await websocket.send_text(json.dumps({
            "type": "auth_success",
            "message": "Authentication successful",
            "user_id": user.id
        }))
        
    except Exception as e:
        await websocket.send_text(json.dumps({
            "type": "error",
            "message": f"Authentication failed: {str(e)}"
        }))
        await websocket.close()
        return
    
    # Add connection to MCP service
    await mcp_service.add_websocket_connection(websocket)
    
    try:
        # Send initial system health
        health = await mcp_service.check_system_health()
        await websocket.send_text(json.dumps({
            "type": "system_health",
            "data": health.model_dump(),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }))
        
        # Keep connection alive and handle messages
        while True:
            try:
                message = await websocket.receive_text()
                data = json.loads(message)
                
                # Handle different message types
                message_type = data.get("type")
                
                if message_type == "ping":
                    await websocket.send_text(json.dumps({
                        "type": "pong",
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }))
                elif message_type == "get_health":
                    health = await mcp_service.check_system_health()
                    await websocket.send_text(json.dumps({
                        "type": "system_health",
                        "data": health.model_dump(),
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }))
                elif message_type == "get_tasks":
                    tasks = await mcp_service.get_active_tasks()
                    await websocket.send_text(json.dumps({
                        "type": "tasks",
                        "data": [task.model_dump() for task in tasks],
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }))
                else:
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": f"Unknown message type: {message_type}"
                    }))
                    
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON message"
                }))
                
    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": f"WebSocket error: {str(e)}"
            }))
        except:
            pass
    finally:
        # Remove connection from MCP service
        await mcp_service.remove_websocket_connection(websocket)
