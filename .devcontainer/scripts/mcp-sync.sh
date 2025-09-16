#!/bin/bash

# mcp-sync.sh - Скрипт для синхронизации контекста MCP между контейнерами

echo "Синхронизация MCP контекста между контейнерами..."

# Создаем директории, если они не существуют
mkdir -p /workspace/.mcp
mkdir -p /shared/mcp

# Синхронизация из основного рабочего пространства в общую директорию
rsync -avz --exclude='node_modules' --exclude='.git' /workspace/.mcp/ /shared/mcp/

# Обратная синхронизация для обновления изменений
rsync -avz /shared/mcp/ /workspace/.mcp/

echo "Синхронизация завершена."
