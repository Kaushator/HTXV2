#!/usr/bin/env python3
"""
Простой клиент для тестирования WebSocket соединения с MCP сервисом.
"""

import asyncio
import json
import sys
import time
import websockets
import signal

# Параметры подключения
WS_URL = "ws://localhost:8000/ws/mcp"  # URL для WebSocket подключения
PING_INTERVAL = 10  # Интервал отправки ping сообщений (в секундах)

# Флаг для корректного завершения
running = True

def handle_exit(signum, frame):
    """Обработчик сигналов для корректного завершения."""
    global running
    print("\nПолучен сигнал завершения, закрываем соединение...")
    running = False

async def send_ping(websocket):
    """Отправляет ping сообщения с заданным интервалом."""
    while running:
        ping_message = {
            "type": "ping",
            "timestamp": time.time()
        }
        await websocket.send(json.dumps(ping_message))
        print(f">> Отправлено: {ping_message}")
        await asyncio.sleep(PING_INTERVAL)

async def receive_messages(websocket):
    """Принимает сообщения от сервера."""
    while running:
        try:
            message = await websocket.recv()
            print(f"<< Получено: {message}")
        except websockets.exceptions.ConnectionClosed:
            print("Соединение закрыто сервером")
            break
        except Exception as e:
            print(f"Ошибка при получении сообщения: {e}")
            break

async def subscribe_to_topics(websocket, topics):
    """Подписывается на заданные топики."""
    if not topics:
        return
    
    # Формируем сообщение о подписке
    subscribe_message = {
        "type": "subscribe",
        "topics": topics
    }
    
    # Отправляем сообщение
    await websocket.send(json.dumps(subscribe_message))
    print(f">> Отправлено: {subscribe_message}")

async def main():
    """Основная функция клиента."""
    global running
    
    # Проверяем аргументы командной строки
    topics = []
    if len(sys.argv) > 1:
        topics = sys.argv[1].split(',')
        print(f"Будет выполнена подписка на топики: {topics}")
    
    # Устанавливаем обработчики сигналов
    signal.signal(signal.SIGINT, handle_exit)
    signal.signal(signal.SIGTERM, handle_exit)
    
    print(f"Подключение к {WS_URL}...")
    
    try:
        # Устанавливаем WebSocket соединение
        async with websockets.connect(WS_URL) as websocket:
            print("Соединение установлено!")
            
            # Подписываемся на топики, если указаны
            await subscribe_to_topics(websocket, topics)
            
            # Запускаем задачи отправки ping и приема сообщений
            ping_task = asyncio.create_task(send_ping(websocket))
            receive_task = asyncio.create_task(receive_messages(websocket))
            
            # Ждем завершения задач
            await asyncio.gather(ping_task, receive_task)
    
    except OSError:
        print("Ошибка: не удалось подключиться к серверу. Убедитесь, что сервер запущен.")
    except Exception as e:
        print(f"Неожиданная ошибка: {e}")
    finally:
        running = False
        print("Клиент завершил работу")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Прервано пользователем")