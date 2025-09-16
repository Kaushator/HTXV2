# Скрипт для обновления зависимостей и устранения уязвимостей в контейнерах
# Автор: GitHub Copilot
# Дата: 16.09.2025

param(
    [switch]$BackendOnly,     # Обновить только зависимости backend
    [switch]$FrontendOnly,    # Обновить только зависимости frontend
    [switch]$Force,           # Принудительное обновление без запроса подтверждения
    [switch]$ScanOnly         # Только сканирование без обновления
)

# Определяем цвета для вывода
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

# Выводим баннер
Write-Host "$BLUE"
Write-Host "  _   _           _       _            ____                          _ _         "
Write-Host " | | | |_ __   __| | __ _| |_ ___     |  _ \  ___ _ __   ___ _ __   | (_) ___ ___ "
Write-Host " | | | | '_ \ / _` |/ _` | __/ _ \    | | | |/ _ \ '_ \ / _ \ '_ \  | | |/ __/ __|"
Write-Host " | |_| | |_) | (_| | (_| | ||  __/    | |_| |  __/ |_) |  __/ | | | | | | (__\__ \"
Write-Host "  \___/| .__/ \__,_|\__,_|\__\___|    |____/ \___| .__/ \___|_| |_| |_|_|\___|___/"
Write-Host "       |_|                                       |_|                               "
Write-Host "$RESET"
Write-Host "${YELLOW}Инструмент для обновления зависимостей и устранения уязвимостей в Docker-контейнерах${RESET}"
Write-Host ""

# Проверка необходимых инструментов
$tools = @{
    "docker" = "Docker"
    "docker compose" = "Docker Compose"
}

$missingTools = @()
foreach ($tool in $tools.Keys) {
    try {
        $null = Invoke-Expression "$tool --version"
        Write-Host "${GREEN}✓ $($tools[$tool]) установлен${RESET}"
    }
    catch {
        Write-Host "${RED}✗ $($tools[$tool]) не найден${RESET}"
        $missingTools += $tools[$tool]
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "${RED}Ошибка: Необходимо установить следующие инструменты: $($missingTools -join ', ')${RESET}"
    exit 1
}

# Функция для обновления зависимостей backend
function Update-BackendDependencies {
    Write-Host "${BLUE}=== Обновление зависимостей Backend ===${RESET}"

    # Проверяем наличие requirements.txt
    if (-not (Test-Path "backend/requirements.txt")) {
        Write-Host "${RED}✗ Файл backend/requirements.txt не найден${RESET}"
        return $false
    }

    # Сканируем текущие зависимости на уязвимости
    Write-Host "${YELLOW}Сканирование текущих зависимостей на уязвимости...${RESET}"
    docker build -t htxbackend:scan -f backend/Dockerfile ./backend
    docker scout cves htxbackend:scan

    if ($ScanOnly) {
        Write-Host "${YELLOW}Режим только сканирования. Обновление не выполняется.${RESET}"
        return $true
    }

    # Запрашиваем подтверждение перед обновлением
    if (-not $Force) {
        $confirmation = Read-Host "${YELLOW}Хотите обновить зависимости backend? [y/N]${RESET}"
        if ($confirmation -ne "y") {
            Write-Host "${YELLOW}Обновление backend отменено.${RESET}"
            return $false
        }
    }

    # Создаем копию requirements.txt
    Copy-Item "backend/requirements.txt" "backend/requirements.txt.bak"

    # Обновляем уязвимые пакеты
    $requirements = Get-Content "backend/requirements.txt"
    $updated = @()

    foreach ($line in $requirements) {
        if ($line -match "^(python-jose|starlette|python-multipart|setuptools|ecdsa|fastapi|black)(==|>=)") {
            $packageName = $Matches[1]
            Write-Host "${YELLOW}Обновление пакета $packageName...${RESET}"
            switch ($packageName) {
                "python-jose" { $updated += "python-jose==3.4.0" }
                "starlette" { $updated += "starlette==0.40.0" }
                "python-multipart" { $updated += "python-multipart==0.0.18" }
                "setuptools" { $updated += "setuptools==78.1.1" }
                "ecdsa" { $updated += "ecdsa==0.19.1" } # Нет исправленной версии, оставляем
                "fastapi" { $updated += "fastapi==0.109.1" }
                "black" { $updated += "black==24.3.0" }
                default { $updated += $line }
            }
        } else {
            $updated += $line
        }
    }

    # Записываем обновленные зависимости
    $updated | Set-Content "backend/requirements.txt"

    # Проверяем различия
    $diff = Compare-Object -ReferenceObject $requirements -DifferenceObject $updated

    if ($diff) {
        Write-Host "${GREEN}Следующие зависимости были обновлены:${RESET}"
        foreach ($item in $diff) {
            if ($item.SideIndicator -eq "=>") {
                Write-Host "${GREEN}+ $($item.InputObject)${RESET}"
            } else {
                Write-Host "${RED}- $($item.InputObject)${RESET}"
            }
        }

        # Пересобираем образ и проверяем уязвимости
        Write-Host "${YELLOW}Пересборка образа с обновленными зависимостями...${RESET}"
        docker build -t htxbackend:updated -f backend/Dockerfile ./backend

        Write-Host "${YELLOW}Повторное сканирование уязвимостей...${RESET}"
        docker scout cves htxbackend:updated

        return $true
    } else {
        Write-Host "${YELLOW}Не найдено зависимостей для обновления.${RESET}"
        return $false
    }
}

# Функция для обновления зависимостей frontend
function Update-FrontendDependencies {
    Write-Host "${BLUE}=== Обновление зависимостей Frontend ===${RESET}"

    # Проверяем наличие package.json
    if (-not (Test-Path "frontend/package.json")) {
        Write-Host "${RED}✗ Файл frontend/package.json не найден${RESET}"
        return $false
    }

    # Сканируем текущие зависимости на уязвимости
    Write-Host "${YELLOW}Сканирование текущих зависимостей на уязвимости...${RESET}"
    docker build -t htxfrontend:scan -f frontend/Dockerfile ./frontend
    docker scout cves htxfrontend:scan

    if ($ScanOnly) {
        Write-Host "${YELLOW}Режим только сканирования. Обновление не выполняется.${RESET}"
        return $true
    }

    # Запрашиваем подтверждение перед обновлением
    if (-not $Force) {
        $confirmation = Read-Host "${YELLOW}Хотите обновить зависимости frontend? [y/N]${RESET}"
        if ($confirmation -ne "y") {
            Write-Host "${YELLOW}Обновление frontend отменено.${RESET}"
            return $false
        }
    }

    # Создаем временную директорию для обновления зависимостей
    $tmpDir = Join-Path $env:TEMP "htx-frontend-update"
    if (Test-Path $tmpDir) {
        Remove-Item -Recurse -Force $tmpDir
    }
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    # Копируем package.json в временную директорию
    Copy-Item "frontend/package.json" "$tmpDir/package.json"
    if (Test-Path "frontend/package-lock.json") {
        Copy-Item "frontend/package-lock.json" "$tmpDir/package-lock.json"
    }

    # Запускаем npm audit fix в временной директории
    Push-Location $tmpDir
    try {
        Write-Host "${YELLOW}Проверка и исправление уязвимостей npm...${RESET}"
        npm audit fix --force

        # Проверяем различия и выводим изменения
        $originalPackageJson = Get-Content "../frontend/package.json"
        $updatedPackageJson = Get-Content "package.json"

        $diff = Compare-Object -ReferenceObject $originalPackageJson -DifferenceObject $updatedPackageJson

        if ($diff) {
            Write-Host "${GREEN}Следующие изменения были внесены в package.json:${RESET}"
            foreach ($item in $diff) {
                if ($item.SideIndicator -eq "=>") {
                    Write-Host "${GREEN}+ $($item.InputObject)${RESET}"
                } else {
                    Write-Host "${RED}- $($item.InputObject)${RESET}"
                }
            }
        }

        # Копируем обновленные файлы обратно
        Copy-Item "package.json" "../frontend/package.json" -Force
        if (Test-Path "package-lock.json") {
            Copy-Item "package-lock.json" "../frontend/package-lock.json" -Force
        }

        Write-Host "${GREEN}Зависимости frontend обновлены.${RESET}"

        # Пересобираем образ и проверяем уязвимости
        Write-Host "${YELLOW}Пересборка образа с обновленными зависимостями...${RESET}"
        docker build -t htxfrontend:updated -f ../frontend/Dockerfile ../frontend

        Write-Host "${YELLOW}Повторное сканирование уязвимостей...${RESET}"
        docker scout cves htxfrontend:updated

        return $true
    }
    catch {
        Write-Host "${RED}Ошибка при обновлении зависимостей frontend: $_${RESET}"
        return $false
    }
    finally {
        Pop-Location
        Remove-Item -Recurse -Force $tmpDir
    }
}

# Основной блок выполнения
$backendUpdated = $false
$frontendUpdated = $false

if ($BackendOnly -or (-not $BackendOnly -and -not $FrontendOnly)) {
    $backendUpdated = Update-BackendDependencies
}

if ($FrontendOnly -or (-not $BackendOnly -and -not $FrontendOnly)) {
    $frontendUpdated = Update-FrontendDependencies
}

# Вывод итогов
Write-Host ""
Write-Host "${BLUE}=== Итоги обновления ===${RESET}"
if ($backendUpdated) {
    Write-Host "${GREEN}✓ Backend: Зависимости проверены/обновлены${RESET}"
} else {
    Write-Host "${YELLOW}⚠ Backend: Обновление не выполнено${RESET}"
}

if ($frontendUpdated) {
    Write-Host "${GREEN}✓ Frontend: Зависимости проверены/обновлены${RESET}"
} else {
    Write-Host "${YELLOW}⚠ Frontend: Обновление не выполнено${RESET}"
}

Write-Host ""
if ($backendUpdated -or $frontendUpdated) {
    Write-Host "${YELLOW}Для применения изменений необходимо пересобрать и перезапустить контейнеры:${RESET}"
    Write-Host "docker compose down"
    Write-Host "docker compose up -d --build"
}

# Рекомендации по дальнейшим действиям
Write-Host ""
Write-Host "${BLUE}Рекомендации:${RESET}"
Write-Host "1. Проверьте совместимость обновленных пакетов перед деплоем"
Write-Host "2. Запустите автоматические тесты для подтверждения работоспособности"
Write-Host "3. Обновляйте зависимости регулярно для поддержания безопасности"
