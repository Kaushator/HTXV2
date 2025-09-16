#!/usr/bin/env pwsh
# Скрипт для автоматизированного тестирования Docker контейнеров
# HTXV2 - Тестирование Docker контейнеров

# Настройки цветов для вывода
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

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

# Функция проверки доступности HTTP сервиса
function Test-HttpService {
    param (
        [string]$serviceName,
        [string]$url,
        [int]$timeoutSeconds = 30,
        [string]$expectedStatus = "200"
    )

    Write-Host "Тестирование $serviceName..." -ForegroundColor $infoColor

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    while ($stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        try {
            $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
            $statusCode = $response.StatusCode

            if ($statusCode -eq $expectedStatus) {
                Write-Status "✓ $serviceName доступен по адресу $url. Код ответа: $statusCode" "УСПЕХ" $successColor
                return $true
            }

            Write-Status "Ожидание $serviceName... Получен код ответа: $statusCode (ожидался $expectedStatus)" "ОЖИДАНИЕ" $warningColor
        }
        catch {
            Write-Host "." -NoNewline
        }

        Start-Sleep -Seconds 2
    }

    Write-Status "✗ Не удалось подключиться к $serviceName по адресу $url в течение $timeoutSeconds секунд" "ОШИБКА" $errorColor
    return $false
}

# Функция проверки доступности порта
function Test-TcpConnection {
    param (
        [string]$serviceName,
        [string]$hostname,
        [int]$port,
        [int]$timeoutSeconds = 30
    )

    Write-Host "Тестирование TCP соединения с $serviceName ($hostname порт $port)..." -ForegroundColor $infoColor

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    while ($stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connectionTask = $tcpClient.ConnectAsync($hostname, $port)

            # Ждем подключения с таймаутом 5 секунд
            if ($connectionTask.Wait(5000)) {
                $tcpClient.Close()
                Write-Status "✓ $serviceName доступен по адресу $hostname порт $port" "УСПЕХ" $successColor
                return $true
            }

            Write-Host "." -NoNewline
        }
        catch {
            Write-Host "." -NoNewline
        }

        Start-Sleep -Seconds 2
    }

    Write-Status "✗ Не удалось подключиться к $serviceName по адресу $hostname порт $port в течение $timeoutSeconds секунд" "ОШИБКА" $errorColor
    return $false
}

# Функция проверки статуса контейнеров
function Test-ContainerStatus {
    Write-Host "`nПроверка статуса контейнеров..." -ForegroundColor $infoColor

    try {
        # Получаем только контейнеры из нашего проекта
        $containers = docker compose ps -a --format "{{.Name}}|{{.Status}}|{{.Image}}"

        if (-not $containers) {
            Write-Status "Не найдено активных контейнеров" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            return $false
        }

        $allRunning = $true
        $containerList = @()

        foreach ($container in $containers) {
            $parts = $container -split '\|'
            $name = $parts[0]
            $status = $parts[1]
            $image = $parts[2]

            $containerList += [PSCustomObject]@{
                Name = $name
                Status = $status
                Image = $image
                IsRunning = $status -match "Up "
            }

            if (-not ($status -match "Up ")) {
                $allRunning = $false
            }
        }

        # Вывод таблицы статусов контейнеров
        Write-Host "`nСтатус контейнеров:" -ForegroundColor $infoColor
        $containerList | Select-Object Name, Status, IsRunning | Format-Table -AutoSize

        if ($allRunning) {
            Write-Status "✓ Все контейнеры запущены и работают" "УСПЕХ" $successColor
        } else {
            Write-Status "✗ Некоторые контейнеры не запущены или находятся в ошибочном состоянии" "ОШИБКА" $errorColor
        }

        return $allRunning
    }
    catch {
        Write-Status "Ошибка при получении статуса контейнеров: $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Функция проверки логов контейнера на наличие ошибок
function Test-ContainerLogs {
    param (
        [string]$containerName,
        [int]$lastLines = 100
    )

    Write-Host "`nПроверка логов контейнера $containerName..." -ForegroundColor $infoColor

    try {
        $logs = docker logs --tail $lastLines $containerName 2>&1

        # Получаем timestamp для проверки только свежих ошибок (последние 2 минуты)
        $timeThreshold = (Get-Date).AddMinutes(-2).ToUniversalTime()
        $timeFormat = "yyyy-MM-dd HH:mm:ss"

        # Поиск ошибок в логах
        $errorPattern = "error|exception|fail|critical|fatal"
        $allErrorLogs = $logs | Select-String -Pattern $errorPattern -CaseSensitive:$false

        # Фильтруем только свежие ошибки
        $errorLogs = @()
        foreach ($log in $allErrorLogs) {
            # Пытаемся извлечь timestamp из строки лога
            if ($log -match '(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})') {
                $logTime = [DateTime]::ParseExact($matches[1], $timeFormat, [System.Globalization.CultureInfo]::InvariantCulture)
                if ($logTime -gt $timeThreshold) {
                    $errorLogs += $log
                }
            } else {
                # Если не можем извлечь время, считаем ошибку актуальной
                $errorLogs += $log
            }
        }

        if ($errorLogs) {
            Write-Status "⚠ В логах $containerName обнаружены потенциальные ошибки:" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            $errorLogs | ForEach-Object { Write-Host "   $_" -ForegroundColor $warningColor }
            return $false
        } else {
            Write-Status "✓ В последних $lastLines строках логов $containerName не обнаружено явных ошибок" "УСПЕХ" $successColor
            return $true
        }
    }
    catch {
        Write-Status "Ошибка при получении логов контейнера $containerName - $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Функция проверки использования ресурсов контейнерами
function Test-ContainerResources {
    Write-Host "`nПроверка использования ресурсов контейнерами..." -ForegroundColor $infoColor

    try {
        $stats = docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}|{{.BlockIO}}"

        if (-not $stats) {
            Write-Status "Не удалось получить статистику использования ресурсов" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            return $false
        }

        $resourceList = @()
        $highCpuUsage = $false
        $highMemUsage = $false

        foreach ($stat in $stats) {
            $parts = $stat -split '\|'
            $name = $parts[0]
            $cpuPerc = $parts[1]
            $memUsage = $parts[2]
            $netIO = $parts[3]
            $blockIO = $parts[4]

            # Извлечение числового значения CPU из строки (например, "10.5%" -> 10.5)
            $cpuValue = [double]($cpuPerc -replace '%', '')

            # Извлечение значений памяти из строки (например, "100MiB / 1GiB" -> 100, 1024)
            $memParts = $memUsage -split ' / '
            $memUsedStr = $memParts[0]
            # Не используем вторую часть для сравнения

            # Извлечение числовых значений
            $memUsedValue = [double]($memUsedStr -replace '[^0-9\.]', '')
            $memUsedUnit = $memUsedStr -replace '[0-9\.]', ''

            # Нормализация к MiB для сравнения
            if ($memUsedUnit -match "GiB") {
                $memUsedValue *= 1024
            }

            $isHighCpu = $cpuValue -gt 90
            $isHighMem = $memUsedValue -gt 1024  # Предупреждение, если использует более 1GiB

            if ($isHighCpu) { $highCpuUsage = $true }
            if ($isHighMem) { $highMemUsage = $true }

            $resourceList += [PSCustomObject]@{
                Name = $name
                CPU = $cpuPerc
                Memory = $memUsage
                Network = $netIO
                DiskIO = $blockIO
                HighCPU = $isHighCpu
                HighMem = $isHighMem
            }
        }

        # Вывод таблицы использования ресурсов
        Write-Host "`nИспользование ресурсов контейнерами:" -ForegroundColor $infoColor
        $resourceList | Format-Table -AutoSize

        # Предупреждения о высоком использовании ресурсов
        if ($highCpuUsage) {
            Write-Status "⚠ Обнаружено высокое использование CPU (>90%)" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
        }

        if ($highMemUsage) {
            Write-Status "⚠ Обнаружено высокое использование памяти (>1GiB)" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
        }

        if (-not ($highCpuUsage -or $highMemUsage)) {
            Write-Status "✓ Использование ресурсов в пределах нормы" "УСПЕХ" $successColor
        }

        return -not ($highCpuUsage -or $highMemUsage)
    }
    catch {
        Write-Status "Ошибка при получении статистики использования ресурсов: $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Функция проверки сетевых подключений контейнеров
function Test-ContainerNetworks {
    Write-Host "`nПроверка сетевых подключений контейнеров..." -ForegroundColor $infoColor

    try {
        $networks = docker network ls --format "{{.Name}}|{{.Driver}}"

        if (-not $networks) {
            Write-Status "Не найдены Docker сети" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            return $false
        }

        $networkList = @()

        foreach ($network in $networks) {
            $parts = $network -split '\|'
            $name = $parts[0]
            $driver = $parts[1]

            # Получение дополнительной информации о сети
            $networkInfo = docker network inspect $name | ConvertFrom-Json
            $containers = @()

            if ($networkInfo.Containers) {
                $containerCount = $networkInfo.Containers.PSObject.Properties.Count

                foreach ($container in $networkInfo.Containers.PSObject.Properties) {
                    $containers += $container.Value.Name
                }
            } else {
                $containerCount = 0
            }

            $networkList += [PSCustomObject]@{
                Name = $name
                Driver = $driver
                ContainerCount = $containerCount
                Containers = ($containers -join ", ")
            }
        }

        # Вывод информации о сетях
        Write-Host "`nСетевые подключения Docker:" -ForegroundColor $infoColor
        $networkList | Format-Table -AutoSize

        # Проверка наличия сети по умолчанию
        $hasDefaultNetwork = $networkList | Where-Object { $_.Name -eq "bridge" -or $_.Name -eq "host" }

        if ($hasDefaultNetwork) {
            Write-Status "✓ Найдены стандартные сети Docker" "УСПЕХ" $successColor
            return $true
        } else {
            Write-Status "⚠ Не найдены стандартные сети Docker (bridge, host)" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            return $false
        }
    }
    catch {
        Write-Status "Ошибка при проверке сетевых подключений: $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Функция для проверки docker-compose.yml
function Test-DockerComposeFile {
    param (
        [string]$filePath = "docker-compose.yml"
    )

    Write-Host "`nПроверка конфигурации Docker Compose..." -ForegroundColor $infoColor

    try {
        if (-not (Test-Path $filePath)) {
            Write-Status "Файл $filePath не найден" "ОШИБКА" $errorColor
            return $false
        }

        # Проверка синтаксиса docker-compose.yml
        $output = docker-compose -f $filePath config 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Status "Обнаружены ошибки в конфигурации Docker Compose:" "ОШИБКА" $errorColor
            Write-Host $output -ForegroundColor $errorColor
            return $false
        }

        Write-Status "✓ Конфигурация Docker Compose в файле $filePath корректна" "УСПЕХ" $successColor

        # Получение списка сервисов
        $services = docker-compose -f $filePath config --services

        Write-Host "`nСервисы, определенные в Docker Compose:" -ForegroundColor $infoColor
        $services | ForEach-Object { Write-Host "  • $_" }

        return $true
    }
    catch {
        Write-Status "Ошибка при проверке файла Docker Compose: $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Функция для запуска полного тестирования
function Start-ContainerTesting {
    $allTestsPassed = $true

    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "    ТЕСТИРОВАНИЕ DOCKER КОНТЕЙНЕРОВ HTXV2" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "Запуск тестирования: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor $infoColor

    # 1. Проверка статуса Docker
    try {
        $dockerVersion = docker --version
        Write-Status "✓ Docker установлен: $dockerVersion" "УСПЕХ" $successColor
    }
    catch {
        Write-Status "✗ Docker не установлен или не запущен" "ОШИБКА" $errorColor
        return
    }

    # 2. Проверка файла docker-compose.yml
    $composeTestResult = Test-DockerComposeFile
    if (-not $composeTestResult) { $allTestsPassed = $false }

    # 3. Проверка статуса контейнеров
    $containerStatusResult = Test-ContainerStatus
    if (-not $containerStatusResult) { $allTestsPassed = $false }

    # 4. Если контейнеры работают, проверяем сетевые сервисы
    if ($containerStatusResult) {
        $httpTestResults = @(
            (Test-HttpService -serviceName "Backend API" -url "http://localhost:8000/health" -timeoutSeconds 10),
            (Test-HttpService -serviceName "Frontend" -url "http://localhost:3000" -timeoutSeconds 10)
        )

        $tcpTestResults = @(
            (Test-TcpConnection -serviceName "Redis" -hostname "localhost" -port 6379 -timeoutSeconds 5)
        )

        if ($httpTestResults -contains $false -or $tcpTestResults -contains $false) {
            $allTestsPassed = $false
        }
    }

    # 5. Проверка сетевых подключений
    $networkTestResult = Test-ContainerNetworks
    if (-not $networkTestResult) { $allTestsPassed = $false }

    # 6. Проверка использования ресурсов
    $resourceTestResult = Test-ContainerResources
    if (-not $resourceTestResult) { $allTestsPassed = $false }

    # 7. Проверка логов ключевых контейнеров
    $logTestResults = @()
    $containers = docker ps --format "{{.Names}}"

    foreach ($container in $containers) {
        $logTestResults += (Test-ContainerLogs -containerName $container)
    }

    if ($logTestResults -contains $false) {
        $allTestsPassed = $false
    }

    # 8. Вывод итогового результата
    Write-Host "`n=====================================================" -ForegroundColor $infoColor
    Write-Host "    РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor

    if ($allTestsPassed) {
        Write-Status "✓ Все тесты пройдены успешно!" "УСПЕХ" $successColor
    } else {
        # Проверяем, есть ли только предупреждения, но нет критичных ошибок
        if ($containerStatusResult -and $httpTestResults -notcontains $false -and $tcpTestResults -notcontains $false) {
            Write-Status "✓ Основные тесты пройдены успешно, но есть предупреждения. См. детали выше." "УСПЕХ" $successColor
        } else {
            Write-Status "✗ Некоторые тесты не пройдены. См. детали выше." "ОШИБКА" $errorColor
        }
    }

    Write-Host "`nТестирование завершено: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
}

# Запуск полного тестирования
Start-ContainerTesting
