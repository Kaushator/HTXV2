#!/usr/bin/env pwsh
# Скрипт для обновления зависимостей и устранения уязвимостей
# HTXV2 - Безопасность зависимостей

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

# Функция обновления Node.js зависимостей
function Update-NodeDependencies {
    param (
        [string]$path,
        [string]$packageName = ""
    )

    if (-not (Test-Path -Path $path)) {
        Write-Status "Путь $path не существует" "ОШИБКА" $errorColor
        return $false
    }

    Push-Location $path

    try {
        # Проверка наличия package.json
        if (-not (Test-Path -Path "package.json")) {
            Write-Status "Файл package.json не найден в $path" "ОШИБКА" $errorColor
            return $false
        }

        Write-Host "`nАнализ уязвимостей в $packageName..." -ForegroundColor $infoColor

        # Аудит зависимостей для выявления уязвимостей
        npm audit --json | Out-File -FilePath "npm-audit-report.json"
        npm audit

        Write-Host "`nОбновление зависимостей в $packageName..." -ForegroundColor $infoColor

        # Обновление зависимостей с учетом уязвимостей
        npm audit fix --force

        # Обновление основных зависимостей
        npm update --save

        # Обновление зависимостей для разработки
        npm update --save-dev

        # Повторный аудит для проверки исправлений
        Write-Host "`nПроверка результатов обновления в $packageName..." -ForegroundColor $infoColor
        npm audit

        Write-Status "✓ Зависимости обновлены для $packageName" "УСПЕХ" $successColor
        return $true
    }
    catch {
        Write-Status "Ошибка при обновлении Node.js зависимостей: $_" "ОШИБКА" $errorColor
        return $false
    }
    finally {
        Pop-Location
    }
}

# Функция обновления Python зависимостей
function Update-PythonDependencies {
    param (
        [string]$path,
        [string]$serviceName = ""
    )

    if (-not (Test-Path -Path $path)) {
        Write-Status "Путь $path не существует" "ОШИБКА" $errorColor
        return $false
    }

    Push-Location $path

    try {
        # Проверка наличия файла с зависимостями
        $reqFile = "requirements.txt"
        if (-not (Test-Path -Path $reqFile)) {
            Write-Status "Файл $reqFile не найден в $path" "ОШИБКА" $errorColor
            return $false
        }

        Write-Host "`nАнализ Python зависимостей в $serviceName..." -ForegroundColor $infoColor

        # Создание виртуального окружения для безопасного обновления
        python -m venv .venv_update

        # Активация виртуального окружения
        if ($IsWindows) {
            .\.venv_update\Scripts\Activate.ps1
        }
        else {
            . ./.venv_update/bin/activate
        }

        # Установка pip-audit для проверки уязвимостей
        pip install pip-audit safety pip-review

        # Проверка уязвимостей в текущих зависимостях
        Write-Host "`nПроверка уязвимостей в $serviceName..." -ForegroundColor $infoColor
        pip-audit -r $reqFile
        safety check -r $reqFile

        # Создание резервной копии
        Copy-Item -Path $reqFile -Destination "${reqFile}.bak"

        # Создание обновленного файла зависимостей
        Write-Host "`nОбновление зависимостей в $serviceName..." -ForegroundColor $infoColor
        pip-review --auto --verbose | Tee-Object -FilePath "pip-update-log.txt"

        # Сохранение обновленных зависимостей
        pip freeze > "requirements-updated.txt"

        # Проверка обновленных зависимостей
        Write-Host "`nПроверка обновленных зависимостей в $serviceName..." -ForegroundColor $infoColor
        pip-audit -r "requirements-updated.txt"

        # Применение обновлений
        Copy-Item -Path "requirements-updated.txt" -Destination $reqFile

        Write-Status "✓ Python зависимости обновлены для $serviceName" "УСПЕХ" $successColor

        # Деактивация и очистка виртуального окружения
        deactivate

        return $true
    }
    catch {
        Write-Status "Ошибка при обновлении Python зависимостей: $_" "ОШИБКА" $errorColor
        return $false
    }
    finally {
        # Очистка виртуального окружения
        if (Test-Path -Path ".venv_update") {
            Remove-Item -Path ".venv_update" -Recurse -Force
        }

        Pop-Location
    }
}

# Функция обновления Docker образов
function Update-DockerImages {
    Write-Host "`nОбновление Docker образов..." -ForegroundColor $infoColor

    try {
        # Получение списка используемых образов
        $images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -notlike "<none>:<none>" }

        if (-not $images) {
            Write-Status "Не найдены Docker образы" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            return $false
        }

        foreach ($image in $images) {
            Write-Host "Обновление образа $image..." -ForegroundColor $infoColor

            try {
                docker pull $image
                Write-Status "✓ Образ $image успешно обновлен" "УСПЕХ" $successColor
            }
            catch {
                Write-Status "Не удалось обновить образ $image - $_" "ОШИБКА" $errorColor
            }
        }

        return $true
    }
    catch {
        Write-Status "Ошибка при обновлении Docker образов: $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Функция сканирования безопасности Docker образов
function Test-DockerSecurity {
    Write-Host "`nСканирование безопасности Docker образов..." -ForegroundColor $infoColor

    try {
        # Получение списка используемых образов
        $images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -notlike "<none>:<none>" }

        if (-not $images) {
            Write-Status "Не найдены Docker образы для сканирования" "ПРЕДУПРЕЖДЕНИЕ" $warningColor
            return $false
        }

        foreach ($image in $images) {
            Write-Host "Сканирование образа $image..." -ForegroundColor $infoColor

            try {
                # Сканирование образа с помощью trivy
                $dockerSockPath = "/var/run/docker.sock"
                $cachePath = "/root/.cache/"
                docker run --rm -v "${dockerSockPath}:${dockerSockPath}" -v "${PWD}:${cachePath}" aquasec/trivy image $image
            }
            catch {
                Write-Status "Не удалось выполнить сканирование образа $image - $_" "ОШИБКА" $errorColor
            }
        }

        return $true
    }
    catch {
        Write-Status "Ошибка при сканировании безопасности Docker образов: $_" "ОШИБКА" $errorColor
        return $false
    }
}

# Обновление зависимостей проекта
function Update-ProjectDependencies {
    $results = @{}

    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "    ОБНОВЛЕНИЕ ЗАВИСИМОСТЕЙ ПРОЕКТА HTXV2" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
    Write-Host "Запуск обновления: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor $infoColor

    # Обновление корневого проекта (Node.js)
    $rootResult = Update-NodeDependencies -path "." -packageName "Основной проект"
    $results["Основной проект"] = $rootResult

    # Обновление Frontend (Node.js)
    $frontendResult = Update-NodeDependencies -path "./frontend" -packageName "Frontend"
    $results["Frontend"] = $frontendResult

    # Обновление Backend (Python)
    $backendResult = Update-PythonDependencies -path "./backend" -serviceName "Backend"
    $results["Backend"] = $backendResult

    # Обновление FinGPT (Python)
    $fingptResult = Update-PythonDependencies -path "./fingpt" -serviceName "FinGPT"
    $results["FinGPT"] = $fingptResult

    # Обновление Docker образов
    $dockerResult = Update-DockerImages
    $results["Docker образы"] = $dockerResult

    # Сканирование безопасности Docker образов
    $scanResult = Test-DockerSecurity
    $results["Сканирование Docker"] = $scanResult

    # Вывод итогового результата
    Write-Host "`n=====================================================" -ForegroundColor $infoColor
    Write-Host "    РЕЗУЛЬТАТЫ ОБНОВЛЕНИЯ ЗАВИСИМОСТЕЙ" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor

    $allSuccess = $true

    foreach ($key in $results.Keys) {
        $value = $results[$key]

        if ($value) {
            Write-Status "✓ $key - Зависимости успешно обновлены" "УСПЕХ" $successColor
        }
        else {
            Write-Status "✗ $key - Не удалось полностью обновить зависимости" "ОШИБКА" $errorColor
            $allSuccess = $false
        }
    }

    if ($allSuccess) {
        Write-Status "`n✓ Все зависимости успешно обновлены!" "УСПЕХ" $successColor
    }
    else {
        Write-Status "`n⚠ Некоторые зависимости не удалось обновить. См. детали выше." "ПРЕДУПРЕЖДЕНИЕ" $warningColor
    }

    Write-Host "`nОбновление завершено: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $infoColor
    Write-Host "=====================================================" -ForegroundColor $infoColor
}

# Запуск функции обновления зависимостей
Update-ProjectDependencies
