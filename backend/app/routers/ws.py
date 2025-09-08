from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from typing import List
import asyncio

from ..clients import htx as htx_client

router = APIRouter()


@router.websocket("/ws/ticker")
async def ws_ticker(ws: WebSocket, symbols: str = Query("BTC"), interval_ms: int = Query(1000)):
    await ws.accept()
    try:
        sym_list: List[str] = [s.strip() for s in symbols.split(",") if s.strip()]
        interval_ms = max(200, min(interval_ms, 10000))
        while True:
            payload = {}
            for s in sym_list:
                try:
                    data = await htx_client.get_ticker(s)
                    payload[s.upper()] = data
                except Exception as e:
                    payload[s.upper()] = {"error": str(e)}
            await ws.send_json({"type": "ticker_batch", "data": payload})
            await asyncio.sleep(interval_ms / 1000.0)
    except WebSocketDisconnect:
        return

