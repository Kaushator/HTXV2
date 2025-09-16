# Скрипт инициализации для dev-контейнера HTXV2 (PowerShell версия)

# Параметры
param (
    [switch]$Force = $false
)

# Функции для цветного вывода
function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$Status,
        [string]$Color
    )

    $statusText = "[$Status]"
    if ($Color -eq "Green") {
        Write-Host $statusText -ForegroundColor Green -NoNewline
    } elseif ($Color -eq "Red") {
        Write-Host $statusText -ForegroundColor Red -NoNewline
    } elseif ($Color -eq "Cyan") {
        Write-Host $statusText -ForegroundColor Cyan -NoNewline
    } elseif ($Color -eq "Yellow") {
        Write-Host $statusText -ForegroundColor Yellow -NoNewline
    }

    Write-Host " $Message"
}

# Информационное сообщение
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    ИНИЦИАЛИЗАЦИЯ DEV-КОНТЕЙНЕРА HTXV2" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Начало инициализации: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# 1. Проверка наличия Docker
Write-Host "Проверка наличия Docker..."
$dockerCommand = if ($IsWindows) { "docker.exe" } else { "docker" }

try {
    $dockerVersion = & $dockerCommand --version
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput -Message "Docker установлен: $dockerVersion" -Status "УСПЕХ" -Color "Green"
    } else {
        Write-ColorOutput -Message "Docker не найден или не работает корректно" -Status "ОШИБКА" -Color "Red"
        exit 1
    }
} catch {
    Write-ColorOutput -Message "Ошибка при проверке Docker: $_" -Status "ОШИБКА" -Color "Red"
    exit 1
}

# 2. Проверка наличия Docker Compose
Write-Host "`nПроверка наличия Docker Compose..."
try {
    $composeVersion = & $dockerCommand compose version
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput -Message "Docker Compose установлен: $composeVersion" -Status "УСПЕХ" -Color "Green"
    } else {
        Write-ColorOutput -Message "Docker Compose не найден или не работает корректно" -Status "ОШИБКА" -Color "Red"
        exit 1
    }
} catch {
    Write-ColorOutput -Message "Ошибка при проверке Docker Compose: $_" -Status "ОШИБКА" -Color "Red"
    exit 1
}

# 3. Проверка статуса контейнеров
Write-Host "`nПроверка статуса контейнеров..."
try {
    $containersRunning = & $dockerCommand ps --format "{{.Names}}" | Select-String "htxenterface_v2"

    if ($containersRunning) {
        Write-ColorOutput -Message "Контейнеры HTXV2 запущены" -Status "ИНФО" -Color "Cyan"
    } else {
        Write-Host "Контейнеры не запущены. Запускаем docker-compose..." -ForegroundColor Yellow

        # Переходим в корневую директорию проекта
        Set-Location -Path "e:\HTXV2"

        # Запускаем docker-compose
        & $dockerCommand compose up -d

        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput -Message "Контейнеры успешно запущены" -Status "УСПЕХ" -Color "Green"
        } else {
            Write-ColorOutput -Message "Ошибка при запуске контейнеров" -Status "ОШИБКА" -Color "Red"
        }
    }
} catch {
    Write-ColorOutput -Message "Ошибка при проверке статуса контейнеров: $_" -Status "ОШИБКА" -Color "Red"
}

# 4. Проверка и создание базы данных htx в PostgreSQL
Write-Host "`nПроверка и создание базы данных htx..."

# Даем немного времени на запуск PostgreSQL
Start-Sleep -Seconds 5

try {
    # Проверяем существование базы данных
    $checkDbCmd = "$dockerCommand exec htxenterface_v2-postgres-1 psql -U htx -d htxdb -c `"SELECT 1 FROM pg_database WHERE datname = 'htx'`""
    $dbExists = Invoke-Expression $checkDbCmd

    if ($dbExists -match "1 row") {
        Write-ColorOutput -Message "База данных htx уже существует" -Status "ИНФО" -Color "Cyan"
    } else {
        # База данных не существует, создаем ее
        $createDbCmd = "$dockerCommand exec htxenterface_v2-postgres-1 psql -U htx -d htxdb -c `"CREATE DATABASE htx;`""
        Invoke-Expression $createDbCmd

        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput -Message "База данных htx успешно создана" -Status "УСПЕХ" -Color "Green"
        } else {
            Write-ColorOutput -Message "Ошибка при создании базы данных htx" -Status "ОШИБКА" -Color "Red"
        }
    }
} catch {
    Write-ColorOutput -Message "Ошибка при работе с PostgreSQL: $_" -Status "ОШИБКА" -Color "Red"
}

# 5. Тестирование контейнеров
Write-Host "`nТестирование контейнеров..."
try {
    # Проверяем доступность frontend
    $frontendUrl = "http://localhost:3000"
    Write-Host "Проверка доступности Frontend ($frontendUrl)..." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri $frontendUrl -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host " доступен!" -ForegroundColor Green
        } else {
            Write-Host " ошибка: $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host " недоступен!" -ForegroundColor Red
    }

    # Проверяем доступность backend
    $backendUrl = "http://localhost:8000"
    Write-Host "Проверка доступности Backend ($backendUrl)..." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri $backendUrl -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host " доступен!" -ForegroundColor Green
        } else {
            Write-Host " ошибка: $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host " недоступен!" -ForegroundColor Red
    }
} catch {
    Write-ColorOutput -Message "Ошибка при тестировании контейнеров: $_" -Status "ОШИБКА" -Color "Red"
}

# 6. Вывод итогового результата
Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "    РЕЗУЛЬТАТЫ ИНИЦИАЛИЗАЦИИ" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-ColorOutput -Message "Инициализация dev-контейнера завершена" -Status "УСПЕХ" -Color "Green"
Write-Host "`nИнициализация завершена: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "===============================================" -ForegroundColor Cyan
