<#
.SYNOPSIS
    Скрипт для запуска проекта HTXEnterface_v2 в Docker

.DESCRIPTION
    Скрипт проверяет наличие всех необходимых зависимостей и запускает проект
    в Docker контейнерах. Исправляет распространенные проблемы и включает
    логирование для отладки.

.EXAMPLE
    .\Start-HTXDockerProject.ps1
#>

# Параметры скрипта
param(
    [switch]$SkipTests = $false,
    [switch]$CleanDocker = $false,
    [switch]$BuildOnly = $false,
    [switch]$Verbose = $false
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
}

function Write-Section {
    param ([string]$Title)
    Write-ColorOutput "========== $Title ==========" "DarkCyan"
}

function Test-Docker {
    try {
        $null = docker info
        return $true
    }
    catch {
        return $false
    }
}

function Test-PortInUse {
    param (
        [int]$Port,
        [string]$Service
    )

    $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue |
                       Where-Object { $_.LocalPort -eq $Port }

    if ($tcpConnections) {
        Write-Warning ("Порт {0} ({1}) занят другим процессом" -f $Port, $Service)
        return $true
    }
    else {
        Write-Host ("✓ Порт {0} ({1}) свободен" -f $Port, $Service)
        return $false
    }
}

function Clear-DockerResources {
    Write-Section "Очистка Docker"
    docker system prune -f
    Write-Success "Docker успешно очищен"
}

function Test-Dependencies {
    Write-Section "Проверка зависимостей"

    # Проверка Docker
    if (-not (Test-Docker)) {
        Write-ErrorMsg "Docker не запущен или у вас нет прав для его использования."
        Write-Info "Пожалуйста, запустите Docker Desktop и попробуйте снова."
        exit 1
    }

    # Проверка файла docker-compose.yml
    if (-not (Test-Path "docker-compose.yml")) {
        Write-ErrorMsg "Файл docker-compose.yml не найден в текущей директории."
        exit 1
    }

    # Проверка docker-compose.override.yml
    if (-not (Test-Path "docker-compose.override.yml")) {
        Write-Warning "Файл docker-compose.override.yml не найден. Будут использованы порты по умолчанию."
    }

    # Проверка занятых портов
    $portsCheck = @(
        @{Port = 5433; Service = "PostgreSQL (переопределено)"},
        @{Port = 6379; Service = "Redis"},
        @{Port = 8000; Service = "Backend"},
        @{Port = 3000; Service = "Frontend"},
        @{Port = 8055; Service = "FinGPT"}
    )

    $hasPortConflict = $false
    foreach ($portCheck in $portsCheck) {
        if (Test-PortInUse -Port $portCheck.Port -Service $portCheck.Service) {
            $hasPortConflict = $true
        }
    }

    if ($hasPortConflict) {
        Write-Warning "Обнаружены конфликты портов. Используйте docker-compose.override.yml для изменения портов или остановите сервисы, использующие эти порты."
    }

    # Проверка наличия файлов Dockerfile
    $dockerfiles = @(
        @{Path = "backend/Dockerfile"; Service = "Backend"},
        @{Path = "frontend/Dockerfile"; Service = "Frontend"},
        @{Path = "fingpt/Dockerfile"; Service = "FinGPT"}
    )

    foreach ($dockerfile in $dockerfiles) {
        if (-not (Test-Path $dockerfile.Path)) {
            Write-ErrorMsg ("Файл Dockerfile для сервиса {0} не найден в {1}" -f $dockerfile.Service, $dockerfile.Path)
            exit 1
        }
    }

    Write-Success "Все необходимые зависимости найдены."
}

function Build-DockerImages {
    Write-Section "Сборка Docker образов"

    Write-Info "Начинаем сборку Docker образов..."
    try {
        docker compose build --parallel
        Write-Success "Все образы успешно собраны."
    }
    catch {
        Write-ErrorMsg ("Ошибка при сборке образов: {0}" -f $_)
        Write-Info "Попробуем собрать образы по отдельности..."

        try {
            Write-Info "Сборка образа backend..."
            docker build -t htx-backend:latest ./backend

            Write-Info "Сборка образа frontend..."
            docker build -t htx-frontend:latest ./frontend

            Write-Info "Сборка образа fingpt..."
            docker build -t htx-fingpt:latest ./fingpt

            Write-Success "Все образы успешно собраны по отдельности."
        }
        catch {
            Write-ErrorMsg ("Не удалось собрать образы: {0}" -f $_)
            exit 1
        }
    }
}

function Start-DockerContainers {
    Write-Section "Запуск контейнеров"

    Write-Info "Запуск контейнеров..."
    try {
        docker compose up -d
        Write-Success "Все контейнеры успешно запущены."
    }
    catch {
        Write-ErrorMsg ("Ошибка при запуске контейнеров: {0}" -f $_)
        exit 1
    }
}

function Get-ContainersStatus {
    Write-Section "Проверка статуса контейнеров"

    Write-Info "Проверка статуса контейнеров..."
    docker compose ps

    # Проверка работоспособности основных сервисов
    $services = @("postgres", "redis", "backend", "frontend", "fingpt")
    $allHealthy = $true

    foreach ($service in $services) {
        $containerStatus = docker compose ps $service --format json | ConvertFrom-Json

        if (-not $containerStatus -or $containerStatus.State -ne "running") {
            Write-Warning ("Сервис {0} не запущен или не в состоянии 'running'" -f $service)
            $allHealthy = $false
        }
    }

    if ($allHealthy) {
        Write-Success "Все сервисы успешно запущены и работают."
    }
    else {
        Write-Warning "Некоторые сервисы не запущены. Проверьте логи для получения дополнительной информации."
    }
}

function Show-ServiceInfo {
    Write-Section "Информация о доступных сервисах"

    Write-Host "PostgreSQL: localhost:5433 (htx:htxpass)"
    Write-Host "Redis: localhost:6379"
    Write-Host "Backend API: http://localhost:8000"
    Write-Host "Frontend: http://localhost:3000"
    Write-Host "FinGPT API: http://localhost:8055"
    Write-Host ""
    Write-Host "Для просмотра логов используйте команду: docker compose logs -f [имя_сервиса]"
    Write-Host "Для остановки контейнеров используйте команду: docker compose down"
}

# Основной блок скрипта
Write-Section "Запуск проекта HTXEnterface_v2"

# Очистка Docker если указан флаг
if ($CleanDocker) {
    Clear-DockerResources
}

# Проверка зависимостей
Test-Dependencies

# Сборка образов Docker
Build-DockerImages

# Если указан флаг BuildOnly, то завершаем работу скрипта
if ($BuildOnly) {
    Write-Info "Сборка образов завершена. Флаг -BuildOnly указан, завершение работы скрипта."
    exit 0
}

# Запуск контейнеров
Start-DockerContainers

# Проверка статуса контейнеров
Get-ContainersStatus

# Вывод информации о доступных сервисах
Show-ServiceInfo

Write-Success "Проект HTXEnterface_v2 успешно запущен!"
