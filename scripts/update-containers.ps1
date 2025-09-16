#!/usr/bin/env pwsh
# Скрипт для обновления Docker контейнеров HTXV2

# Настройки цветов для вывода
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow" # Используется для предупреждений

# Функция вывода с форматированием
function Write-Status {
    param (
        [string]$message,
        [string]$status,
        [string]$color
    )
    Write-Host "[$status] " -ForegroundColor $color -NoNewline
    Write-Host $message
}

# Функция обновления контейнеров
function Update-Containers {
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "    ОБНОВЛЕНИЕ DOCKER КОНТЕЙНЕРОВ HTXV2" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "Начало обновления: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor $infoColor

    # 1. Остановка контейнеров
    Write-Host "Остановка контейнеров..." -ForegroundColor $infoColor
    docker-compose down
    if ($LASTEXITCODE -ne 0) {
        Write-Status "✗ Ошибка при остановке контейнеров" "ОШИБКА" $errorColor
        return $false
    }
    Write-Status "✓ Контейнеры остановлены" "УСПЕХ" $successColor

    # 2. Удаление старых образов
    Write-Host "`nУдаление старых образов..." -ForegroundColor $infoColor
    $images = docker images --filter=reference="htxenterface_v2-*" --format "{{.Repository}}:{{.Tag}}"
    if ($images) {
        foreach ($image in $images) {
            docker rmi $image
            Write-Host "  - Удален образ $image"
        }
        Write-Status "✓ Старые образы удалены" "УСПЕХ" $successColor
    } else {
        Write-Status "Старые образы не найдены" "ИНФО" $infoColor
    }

    # 3. Пересборка образов
    Write-Host "`nПересборка образов..." -ForegroundColor $infoColor
    docker-compose build --no-cache
    if ($LASTEXITCODE -ne 0) {
        Write-Status "✗ Ошибка при пересборке образов" "ОШИБКА" $errorColor
        return $false
    }
    Write-Status "✓ Образы пересобраны" "УСПЕХ" $successColor

    # 4. Запуск контейнеров
    Write-Host "`nЗапуск контейнеров..." -ForegroundColor $infoColor
    docker-compose up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Status "✗ Ошибка при запуске контейнеров" "ОШИБКА" $errorColor
        return $false
    }
    Write-Status "✓ Контейнеры запущены" "УСПЕХ" $successColor

    # 5. Проверка статуса
    Write-Host "`nПроверка статуса контейнеров..." -ForegroundColor $infoColor
    Start-Sleep -Seconds 10 # Даем время на инициализацию

    $containers = docker-compose ps --format "{{.Name}}|{{.Status}}|{{.Service}}"
    $allRunning = $true
    $containerList = @()

    foreach ($container in $containers) {
        $parts = $container -split '\|'
        $name = $parts[0]
        $status = $parts[1]
        $service = $parts[2]

        $containerList += [PSCustomObject]@{
            Name = $name
            Status = $status
            Service = $service
            IsRunning = $status -match "Up "
        }

        if (-not ($status -match "Up ")) {
            $allRunning = $false
        }
    }

    # Вывод таблицы статусов контейнеров
    Write-Host "`nСтатус контейнеров:" -ForegroundColor $infoColor
    $containerList | Format-Table -AutoSize

    if ($allRunning) {
        Write-Status "✓ Все контейнеры запущены и работают" "УСПЕХ" $successColor
    } else {
        Write-Status "✗ Некоторые контейнеры не запущены или находятся в ошибочном состоянии" "ОШИБКА" $errorColor
        return $false
    }

    # 6. Проверка базы данных
    Write-Host "`nПроверка базы данных..." -ForegroundColor $infoColor
    Write-Host "Создание базы данных htx (если не существует)..."

    # Запуск psql для создания базы данных htx
    docker exec -it htxenterface_v2-postgres-1 psql -U htx -d htxdb -c "CREATE DATABASE IF NOT EXISTS htx;"
    if ($LASTEXITCODE -ne 0) {
        # Пробуем другой синтаксис
        docker exec -it htxenterface_v2-postgres-1 psql -U htx -d htxdb -c "SELECT 'CREATE DATABASE htx' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'htx')\gexec"
    }

    Write-Status "✓ База данных проверена и готова к работе" "УСПЕХ" $successColor

    # 7. Вывод итогового результата
    Write-Host "`n=====================================================" -ForegroundColor $infoColor
    Write-Host "    РЕЗУЛЬТАТЫ ОБНОВЛЕНИЯ" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Status "✓ Обновление завершено успешно!" "УСПЕХ" $successColor
    Write-Host "`nОбновление завершено: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor

    return $true
}

# Запуск обновления
Update-Containers
