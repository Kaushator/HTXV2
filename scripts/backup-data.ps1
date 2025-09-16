#!/usr/bin/env pwsh
# Скрипт для создания резервных копий данных HTXV2

# Настройки цветов для вывода
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow" # Используется для предупреждений

# Конфигурация
$backupDir = ".\backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$pgBackupFile = "$backupDir\pg_backup_$timestamp.sql"
$redisBackupFile = "$backupDir\redis_backup_$timestamp.rdb"
$configBackupFile = "$backupDir\config_backup_$timestamp.zip"

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

# Функция создания резервных копий
function Backup-Data {
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "    СОЗДАНИЕ РЕЗЕРВНЫХ КОПИЙ ДАННЫХ HTXV2" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "Начало резервного копирования: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor $infoColor

    # 1. Создание директории для резервных копий, если не существует
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory | Out-Null
        Write-Status "Создана директория для резервных копий: $backupDir" "ИНФО" $infoColor
    }

    # 2. Проверка, запущены ли контейнеры
    Write-Host "Проверка статуса контейнеров..." -ForegroundColor $infoColor
    $containersPg = docker ps --filter name=htxenterface_v2-postgres-1 --format "{{.Names}}"
    $containersRedis = docker ps --filter name=htxenterface_v2-redis-1 --format "{{.Names}}"

    if (-not $containersPg) {
        Write-Status "✗ Контейнер PostgreSQL не запущен" "ОШИБКА" $errorColor
        return $false
    }

    if (-not $containersRedis) {
        Write-Status "✗ Контейнер Redis не запущен" "ОШИБКА" $errorColor
        return $false
    }

    Write-Status "✓ Контейнеры PostgreSQL и Redis запущены" "УСПЕХ" $successColor

    # 3. Резервное копирование PostgreSQL
    Write-Host "`nСоздание резервной копии PostgreSQL..." -ForegroundColor $infoColor
    docker exec htxenterface_v2-postgres-1 pg_dumpall -U htx > $pgBackupFile
    if ($LASTEXITCODE -ne 0) {
        Write-Status "✗ Ошибка при создании резервной копии PostgreSQL" "ОШИБКА" $errorColor
    } else {
        Write-Status "✓ Резервная копия PostgreSQL создана: $pgBackupFile" "УСПЕХ" $successColor
        Write-Host "   Размер файла: $((Get-Item $pgBackupFile).Length / 1MB) МБ"
    }

    # 4. Резервное копирование Redis
    Write-Host "`nСоздание резервной копии Redis..." -ForegroundColor $infoColor
    docker exec htxenterface_v2-redis-1 redis-cli --rdb /data/dump.rdb
    docker cp htxenterface_v2-redis-1:/data/dump.rdb $redisBackupFile
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $redisBackupFile)) {
        Write-Status "✗ Ошибка при создании резервной копии Redis" "ОШИБКА" $errorColor
    } else {
        Write-Status "✓ Резервная копия Redis создана: $redisBackupFile" "УСПЕХ" $successColor
        Write-Host "   Размер файла: $((Get-Item $redisBackupFile).Length / 1MB) МБ"
    }

    # 5. Резервное копирование конфигурационных файлов
    Write-Host "`nСоздание резервной копии конфигурационных файлов..." -ForegroundColor $infoColor
    $configFiles = @(
        "docker-compose.yml",
        "backend/.env",
        "backend/app/core/config.py",
        "frontend/.env"
    )

    $tempConfigDir = "$backupDir\temp_config_$timestamp"
    New-Item -Path $tempConfigDir -ItemType Directory | Out-Null

    $allFilesExist = $true
    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            $destDir = Join-Path -Path $tempConfigDir -ChildPath (Split-Path -Parent $file)
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $file -Destination (Join-Path -Path $tempConfigDir -ChildPath $file) -Force
        } else {
            Write-Host "   Файл $file не найден" -ForegroundColor $warningColor
            $allFilesExist = $false
        }
    }

    # Архивация конфигурационных файлов
    Compress-Archive -Path "$tempConfigDir\*" -DestinationPath $configBackupFile -Force
    Remove-Item -Path $tempConfigDir -Recurse -Force

    if (-not (Test-Path $configBackupFile) -or $allFilesExist -eq $false) {
        Write-Status "⚠ Резервная копия конфигураций создана с предупреждениями: $configBackupFile" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
    } else {
        Write-Status "✓ Резервная копия конфигураций создана: $configBackupFile" "УСПЕХ" $successColor
        Write-Host "   Размер файла: $((Get-Item $configBackupFile).Length / 1KB) КБ"
    }

    # 6. Вывод итогового результата
    Write-Host "`n=====================================================" -ForegroundColor $infoColor
    Write-Host "    РЕЗУЛЬТАТЫ РЕЗЕРВНОГО КОПИРОВАНИЯ" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Status "✓ Резервное копирование завершено!" "УСПЕХ" $successColor
    Write-Host "Резервные копии сохранены в директории: $(Resolve-Path $backupDir)"
    Write-Host "`nРезервное копирование завершено: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor

    return $true
}

# Запуск резервного копирования
Backup-Data
