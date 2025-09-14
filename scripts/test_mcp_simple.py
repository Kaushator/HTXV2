#!/usr/bin/env python3
"""
Простой тестовый скрипт для проверки MCP WebSocket
"""

import asyncio
import json
import websockets

async def test_websocket():
    uri = "ws://localhost:8000/ws/mcp"
    
    print(f"Connecting to {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected successfully!")
            
            # Получение приветственного сообщения
            response = await websocket.recv()
            print(f"Received welcome message: {response}")
            
            # Отправка ping
            ping_message = {"type": "ping", "timestamp": 123456789}
            await websocket.send(json.dumps(ping_message))
            print(f"Sent ping message: {ping_message}")
            
            # Получение pong
            response = await websocket.recv()
            print(f"Received pong response: {response}")
            
            # Подписка на тестовый топик
            subscribe_message = {"type": "subscribe", "topics": ["market_data"]}
            await websocket.send(json.dumps(subscribe_message))
            print(f"Sent subscribe message: {subscribe_message}")
            
            # Получение подтверждения подписки
            response = await websocket.recv()
            print(f"Received subscription confirmation: {response}")
            
            # Запрос данных
            data_request = {"type": "fetch_data", "data_type": "market_data", "params": {}}
            await websocket.send(json.dumps(data_request))
            print(f"Sent data request: {data_request}")
            
            # Получение данных
            response = await websocket.recv()
            print(f"Received data response: {response}")
            
            print("Test completed successfully!")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_websocket())