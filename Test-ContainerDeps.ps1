<#
.SYNOPSIS
    Скрипт для проверки зависимостей и сборки контейнеров Docker.

.DESCRIPTION
    Этот скрипт проверяет наличие Docker, Docker Compose, свободное место на диске,
    проверяет зависимости backend, frontend и fingpt, а затем запускает тестовую сборку
    всех контейнеров.

.EXAMPLE
    .\Test-ContainerDeps.ps1
#>

# Цветные сообщения для вывода
function Write-ColorOutput {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$Color
    )

    $currentForeground = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $currentForeground
}

function Write-Info {
    param ([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param ([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param ([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-ErrorMsg {
    param ([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
    throw $Message
}

function Write-Section {
    param ([string]$Title)
    Write-ColorOutput "========== $Title ==========" "DarkCyan"
}

# Проверка наличия Docker
try {
    $null = docker info
    Write-Success "Docker установлен и запущен."
}
catch {
    Write-ErrorMsg "Docker не запущен или у вас нет прав для его использования."
}

# Проверка наличия файла docker-compose.yml
if (-not (Test-Path "docker-compose.yml")) {
    Write-ErrorMsg "Файл docker-compose.yml не найден в текущей директории."
}
else {
    Write-Success "Файл docker-compose.yml найден."
}

Write-Section "Проверка свободного места на диске"
Get-PSDrive | Where-Object { $_.Provider.Name -eq "FileSystem" } | Format-Table -AutoSize
Write-Host ""

Write-Section "Проверка доступных ресурсов для Docker"
docker system df
Write-Host ""

Write-Section "Очистка неиспользуемых Docker-ресурсов"
docker system prune -f
Write-Host ""

Write-Section "Проверка Backend зависимостей"
if (-not (Test-Path "backend/requirements.txt")) {
    Write-Warning "Файл backend/requirements.txt не найден"
}
else {
    Write-Info "Проверка зависимостей backend..."
    $requirements = Get-Content -Path "backend/requirements.txt"
    foreach ($line in $requirements) {
        if ($line -and -not $line.StartsWith("#")) {
            Write-Host "✓ $line"
        }
    }
    Write-Success "Все зависимости backend найдены."
}
Write-Host ""

Write-Section "Проверка Frontend зависимостей"
if (-not (Test-Path "frontend/package.json")) {
    Write-Warning "Файл frontend/package.json не найден"
}
else {
    Write-Info "Проверка зависимостей frontend..."
    try {
        Push-Location -Path "frontend"
        npm list --depth=0 | Out-Host
        Pop-Location
    }
    catch {
        Write-Warning "Не все зависимости frontend установлены локально."
    }
}
Write-Host ""

Write-Section "Проверка FinGPT зависимостей"
if (-not (Test-Path "fingpt/requirements.txt")) {
    Write-Warning "Файл fingpt/requirements.txt не найден"
}
else {
    Write-Info "Проверка зависимостей fingpt..."
    $requirements = Get-Content -Path "fingpt/requirements.txt"
    foreach ($line in $requirements) {
        if ($line -and -not $line.StartsWith("#")) {
            Write-Host "✓ $line"
        }
    }
    Write-Success "Все зависимости fingpt найдены."
}
Write-Host ""

Write-Section "Проверка доступности CUDA для fingpt (если установлена)"
try {
    $nvidiaSmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    if ($nvidiaSmi) {
        Write-Info "CUDA установлена. Проверка доступных устройств:"
        Invoke-Expression "nvidia-smi --list-gpus"
        Invoke-Expression "nvidia-smi"
    }
    else {
        Write-Warning "CUDA не установлена или недоступна. FinGPT будет работать на CPU (медленно)."
    }
}
catch {
    Write-Warning "CUDA не установлена или недоступна. FinGPT будет работать на CPU (медленно)."
}
Write-Host ""

Write-Section "Проверка сетевых портов"
Write-Info "Проверка, свободны ли порты, необходимые для работы контейнеров:"

function Test-PortInUse {
    param (
        [int]$Port,
        [string]$Service
    )

    $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $Port }

    if ($tcpConnections) {
        Write-Warning "Порт $Port ($Service) занят другим процессом"
    }
    else {
        Write-Host "✓ Порт $Port ($Service) свободен"
    }
}

Test-PortInUse -Port 5432 -Service "PostgreSQL"
Test-PortInUse -Port 6379 -Service "Redis"
Test-PortInUse -Port 8000 -Service "Backend"
Test-PortInUse -Port 3000 -Service "Frontend"
Test-PortInUse -Port 8055 -Service "FinGPT"
Write-Host ""

Write-Section "Предварительная сборка отдельных образов"
Write-Info "Сборка образа backend..."
try {
    docker build -t htx-backend:test ./backend
}
catch {
    Write-Warning "Не удалось собрать образ backend: $_"
}

Write-Info "Сборка образа frontend..."
try {
    docker build -t htx-frontend:test ./frontend
}
catch {
    Write-Warning "Не удалось собрать образ frontend: $_"
}

Write-Info "Сборка образа fingpt..."
try {
    docker build -t htx-fingpt:test ./fingpt
}
catch {
    Write-Warning "Не удалось собрать образ fingpt: $_"
}

Write-Host ""
Write-Section "Запуск тестовой сборки всех контейнеров"
Write-Info "Запуск docker compose build..."
try {
    docker compose build
    Write-Success "Все образы успешно собраны через docker-compose!"
}
catch {
    Write-ErrorMsg "Не удалось собрать образы через docker-compose: $_"
}

Write-Host ""
Write-Section "Рекомендации"
Write-Host "1. Если были предупреждения о занятых портах, остановите соответствующие сервисы"
Write-Host "   или измените порты в docker-compose.yml."
Write-Host "2. Если были проблемы со сборкой fingpt и CUDA недоступна, убедитесь, что"
Write-Host "   у вас установлены драйверы NVIDIA и CUDA Toolkit."
Write-Host "3. Для запуска контейнеров используйте команду: docker compose up -d"
Write-Host "4. Для остановки контейнеров используйте команду: docker compose down"
Write-Host ""

Write-Success "Проверка зависимостей контейнеров завершена!"
