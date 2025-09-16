<#
.SYNOPSIS
    Скрипт для управления Docker-контейнерами проекта HTXV2.

.DESCRIPTION
    Этот скрипт позволяет управлять Docker-контейнерами с помощью docker-compose.
    Доступны следующие операции: запуск, остановка, перезапуск, проверка статуса
    и просмотр логов.

.PARAMETER Action
    Действие, которое нужно выполнить:
    - Start: Запустить контейнеры
    - Stop: Остановить контейнеры
    - Restart: Перезапустить контейнеры
    - Status: Проверить статус контейнеров
    - Logs: Просмотреть логи контейнеров

.PARAMETER ServiceName
    Имя сервиса для просмотра логов (опционально, только с действием Logs).

.EXAMPLE
    .\docker-manager.ps1 -Action Start

.EXAMPLE
    .\docker-manager.ps1 -Action Logs -ServiceName backend
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Start", "Stop", "Restart", "Status", "Logs")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$ServiceName
)

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

# Проверка наличия Docker
function Test-Docker {
    try {
        $null = docker info
    }
    catch {
        Write-ErrorMsg "Docker не запущен или у вас нет прав для его использования."
    }
}

# Проверка наличия файла docker-compose.yml
function Test-ComposeFile {
    if (-not (Test-Path "docker-compose.yml")) {
        Write-ErrorMsg "Файл docker-compose.yml не найден в текущей директории."
    }
}

# Запуск контейнеров
function Start-DockerContainers {
    Write-Info "Запуск контейнеров Docker..."

    try {
        docker compose up -d --build
        Write-Success "Контейнеры успешно запущены."
    }
    catch {
        Write-ErrorMsg "Не удалось запустить контейнеры: $_"
    }
}

# Остановка контейнеров
function Stop-DockerContainers {
    Write-Info "Остановка контейнеров Docker..."

    try {
        docker compose down
        Write-Success "Контейнеры успешно остановлены."
    }
    catch {
        Write-ErrorMsg "Не удалось остановить контейнеры: $_"
    }
}

# Перезапуск контейнеров
function Restart-DockerContainers {
    Write-Info "Перезапуск контейнеров Docker..."

    Stop-DockerContainers
    Start-DockerContainers
}

# Проверка статуса контейнеров
function Get-DockerStatus {
    Write-Info "Проверка статуса контейнеров Docker..."

    try {
        docker compose ps
    }
    catch {
        Write-ErrorMsg "Не удалось получить статус контейнеров: $_"
    }
}

# Просмотр логов контейнеров
function Get-DockerLogs {
    param (
        [string]$ServiceName
    )

    Write-Info "Вывод логов контейнеров Docker..."

    try {
        if ([string]::IsNullOrEmpty($ServiceName)) {
            docker compose logs
        }
        else {
            docker compose logs $ServiceName
        }
    }
    catch {
        Write-ErrorMsg "Не удалось получить логи контейнеров: $_"
    }
}

# Основной код
try {
    Test-Docker
    Test-ComposeFile

    switch ($Action) {
        "Start" {
            Start-DockerContainers
        }
        "Stop" {
            Stop-DockerContainers
        }
        "Restart" {
            Restart-DockerContainers
        }
        "Status" {
            Get-DockerStatus
        }
        "Logs" {
            Get-DockerLogs -ServiceName $ServiceName
        }
    }
}
catch {
    Write-ErrorMsg "Ошибка: $_"
}
