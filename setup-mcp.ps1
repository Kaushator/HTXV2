#!/usr/bin/env pwsh

# Скрипт для установки и настройки MCP сервера для интеграции с GitHub Copilot

Write-Host "🚀 Настройка MCP сервера для HTXV2..." -ForegroundColor Green

# Проверка наличия Node.js
try {
    $nodeVersion = node -v
    Write-Host "✓ Node.js установлен: $nodeVersion" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Node.js не установлен. Пожалуйста, установите Node.js перед запуском скрипта" -ForegroundColor Red
    exit 1
}

# Проверка наличия npm
try {
    $npmVersion = npm -v
    Write-Host "✓ npm установлен: $npmVersion" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ npm не установлен. Пожалуйста, установите npm перед запуском скрипта" -ForegroundColor Red
    exit 1
}

# Создание .mcp директории если ещё не создана
if (!(Test-Path ".mcp")) {
    Write-Host "Создание директории .mcp..." -ForegroundColor Yellow
    New-Item -Path ".mcp" -ItemType Directory | Out-Null
}

# Установка необходимых зависимостей
Write-Host "📦 Установка зависимостей MCP сервера..." -ForegroundColor Yellow
npm install

# Проверка успешности установки
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при установке зависимостей" -ForegroundColor Red
    exit 1
}

# Сборка проекта
Write-Host "🔧 Сборка MCP сервера..." -ForegroundColor Yellow
npm run build

# Проверка успешности сборки
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при сборке проекта" -ForegroundColor Red
    exit 1
}

Write-Host "✅ MCP сервер успешно настроен!" -ForegroundColor Green
Write-Host "Для запуска сервера выполните:" -ForegroundColor Cyan
Write-Host "  npm start" -ForegroundColor White
Write-Host "Для запуска в режиме разработки:" -ForegroundColor Cyan
Write-Host "  npm run dev" -ForegroundColor White

# Проверка наличия конфигурации VS Code
if (!(Test-Path ".vscode")) {
    Write-Host "Создание директории .vscode..." -ForegroundColor Yellow
    New-Item -Path ".vscode" -ItemType Directory | Out-Null
}

# Проверка настроек VS Code для MCP
$settingsPath = ".vscode/settings.json"
if (!(Test-Path $settingsPath)) {
    Write-Host "Создание файла настроек VS Code..." -ForegroundColor Yellow
    @"
{
    "github.copilot.advanced": {
        "mcp.process": {
            "path": "node",
            "args": ["start.js"]
        }
    }
}
"@ | Out-File -FilePath $settingsPath -Encoding utf8
    Write-Host "✓ Настройки VS Code для MCP созданы" -ForegroundColor Cyan
}
else {
    Write-Host "Файл настроек VS Code уже существует. Проверьте, что он содержит настройки для MCP." -ForegroundColor Yellow
}

Write-Host "🎉 Настройка завершена!" -ForegroundColor Green
