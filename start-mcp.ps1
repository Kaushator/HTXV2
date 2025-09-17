#!/usr/bin/env pwsh

# Скрипт для запуска MCP сервера для интеграции с GitHub Copilot

Write-Host "🚀 Запуск MCP сервера для HTXV2..." -ForegroundColor Green

# Проверяем, собран ли проект
if (!(Test-Path "dist")) {
    Write-Host "⚠️ Директория dist не найдена. Запуск сборки..." -ForegroundColor Yellow
    npm run build

    # Проверка успешности сборки
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Ошибка при сборке проекта" -ForegroundColor Red
        exit 1
    }
}

# Запуск MCP сервера
Write-Host "🚀 Запуск MCP сервера..." -ForegroundColor Cyan
node start.js
