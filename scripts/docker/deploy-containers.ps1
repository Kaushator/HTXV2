# Скрипт для развертывания и запуска оптимизированных контейнеров
# Автор: GitHub Copilot
# Дата: 16.09.2025

param(
    [switch]$UseOptimized,    # Использовать оптимизированные Dockerfile и конфигурации
    [switch]$Force,          # Принудительное развертывание без подтверждения
    [switch]$NoRebuild,      # Не пересобирать контейнеры (использовать существующие образы)
    [switch]$Prune           # Удалить неиспользуемые образы и контейнеры после запуска
)

# Определяем цвета для вывода
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$BLUE = "`e[34m"
$CYAN = "`e[36m"
$RESET = "`e[0m"

# Выводим баннер
Write-Host "$CYAN"
Write-Host "  _   _ _______  __     _____            _        _                      "
Write-Host " | | | |_   _\ \/ /    |  ___|__  _ __  | |_ __ _(_)_ __   ___ _ __     "
Write-Host " | |_| | | |  \  /     | |_ / _ \| '__| | __/ _` | | '_ \ / _ \ '__|    "
Write-Host " |  _  | | |  /  \     |  _| (_) | |    | || (_| | | | | |  __/ |       "
Write-Host " |_| |_| |_| /_/\_\    |_|  \___/|_|     \__\__,_|_|_| |_|\___|_|       "
Write-Host "$RESET"
Write-Host "${YELLOW}Развертывание и запуск оптимизированных Docker-контейнеров для HTXEnterface v2${RESET}"
Write-Host ""

# Проверка Docker
try {
    $dockerVersion = docker --version
    Write-Host "${GREEN}✓ Docker установлен: $dockerVersion${RESET}"
} catch {
    Write-Host "${RED}✗ Docker не установлен или не запущен${RESET}"
    exit 1
}

# Функция для проверки файлов
function Test-ConfigFiles {
    param(
        [bool]$UseOptimized
    )

    $composeFile = if ($UseOptimized) { "docker-compose.yml.optimized" } else { "docker-compose.yml" }
    $backendFile = if ($UseOptimized) { "backend/Dockerfile.optimized" } else { "backend/Dockerfile" }
    $frontendFile = if ($UseOptimized) { "frontend/Dockerfile.optimized" } else { "frontend/Dockerfile" }
    $fingptFile = if ($UseOptimized) { "fingpt/Dockerfile.optimized" } else { "fingpt/Dockerfile" }

    $missing = @()

    if (-not (Test-Path $composeFile)) { $missing += $composeFile }
    if (-not (Test-Path $backendFile)) { $missing += $backendFile }
    if (-not (Test-Path $frontendFile)) { $missing += $frontendFile }
    if (-not (Test-Path $fingptFile)) { $missing += $fingptFile }

    return $missing
}

# Проверяем наличие файлов конфигурации
$useOptimizedFlag = [bool]$UseOptimized
$missingFiles = Test-ConfigFiles -UseOptimized $useOptimizedFlag

if ($missingFiles.Count -gt 0) {
    Write-Host "${RED}✗ Следующие файлы не найдены:${RESET}"
    foreach ($file in $missingFiles) {
        Write-Host "${RED}  - $file${RESET}"
    }

    if ($UseOptimized) {
        Write-Host "${YELLOW}Оптимизированные конфигурации не найдены. Хотите использовать стандартные файлы? [y/N]${RESET}"
        $useStandard = if (-not $Force) { Read-Host } else { "y" }

        if ($useStandard -eq "y") {
            $UseOptimized = $false
            $missingFiles = Test-ConfigFiles -UseOptimized $false

            if ($missingFiles.Count -gt 0) {
                Write-Host "${RED}✗ Стандартные файлы также отсутствуют. Невозможно продолжить.${RESET}"
                exit 1
            }
        } else {
            Write-Host "${RED}Операция отменена.${RESET}"
            exit 1
        }
    } else {
        Write-Host "${RED}Невозможно продолжить без необходимых файлов конфигурации.${RESET}"
        exit 1
    }
}

# Определяем используемые файлы
$composeFile = if ($UseOptimized) { "docker-compose.yml.optimized" } else { "docker-compose.yml" }
Write-Host "${GREEN}✓ Используем файл Docker Compose: $composeFile${RESET}"

# Функция для остановки контейнеров
function Stop-Containers {
    Write-Host "${BLUE}=== Остановка запущенных контейнеров ===${RESET}"

    try {
        $output = docker compose -f $composeFile down 2>&1
        Write-Host $output
        return $true
    } catch {
        Write-Host "${RED}Ошибка при остановке контейнеров: $_${RESET}"
        return $false
    }
}

# Функция для построения и запуска контейнеров
function Start-Containers {
    param(
        [bool]$RebuildImages
    )

    Write-Host "${BLUE}=== Запуск контейнеров ===${RESET}"

    $buildFlag = if ($RebuildImages) { "--build" } else { "" }

    try {
        if ($UseOptimized) {
            # Для оптимизированных конфигураций используем временный файл
            Copy-Item $composeFile "docker-compose.yml.tmp"
            $output = docker compose -f "docker-compose.yml.tmp" up -d $buildFlag 2>&1
            Remove-Item "docker-compose.yml.tmp"
        } else {
            $output = docker compose -f $composeFile up -d $buildFlag 2>&1
        }

        Write-Host $output
        return $true
    } catch {
        Write-Host "${RED}Ошибка при запуске контейнеров: $_${RESET}"
        return $false
    }
}

# Функция для проверки статуса контейнеров
function Get-ContainerStatus {
    Write-Host "${BLUE}=== Проверка статуса контейнеров ===${RESET}"

    try {
        $containers = docker compose -f $composeFile ps --format json | ConvertFrom-Json

        if (-not $containers -or $containers.Count -eq 0) {
            Write-Host "${YELLOW}Не найдено запущенных контейнеров${RESET}"
            return $false
        }

        $allRunning = $true

        foreach ($container in $containers) {
            $name = $container.Service
            $status = $container.State

            if ($status -eq "running") {
                Write-Host "${GREEN}✓ ${name}: Запущен${RESET}"
            } else {
                Write-Host "${RED}✗ ${name}: ${status}${RESET}"
                $allRunning = $false
            }
        }

        return $allRunning
    } catch {
        Write-Host "${RED}Ошибка при проверке статуса контейнеров: $_${RESET}"
        return $false
    }
}

# Функция для очистки неиспользуемых образов и контейнеров
function Clear-DockerResources {
    Write-Host "${BLUE}=== Очистка неиспользуемых Docker ресурсов ===${RESET}"

    try {
        Write-Host "${YELLOW}Удаление остановленных контейнеров...${RESET}"
        docker container prune -f | Out-Null

        Write-Host "${YELLOW}Удаление неиспользуемых образов...${RESET}"
        docker image prune -f | Out-Null

        Write-Host "${YELLOW}Удаление неиспользуемых томов...${RESET}"
        docker volume prune -f | Out-Null

        Write-Host "${YELLOW}Удаление неиспользуемых сетей...${RESET}"
        docker network prune -f | Out-Null

        Write-Host "${GREEN}✓ Очистка завершена${RESET}"
        return $true
    } catch {
        Write-Host "${RED}Ошибка при очистке Docker ресурсов: $_${RESET}"
        return $false
    }
}

# Основной блок выполнения
$confirmation = if (-not $Force) {
    Write-Host "${YELLOW}Будут остановлены и перезапущены все контейнеры проекта HTXEnterface. Продолжить? [y/N]${RESET}"
    Read-Host
} else {
    "y"
}

if ($confirmation -ne "y") {
    Write-Host "${RED}Операция отменена.${RESET}"
    exit 0
}

# Остановка контейнеров
$stopped = Stop-Containers
if (-not $stopped) {
    Write-Host "${RED}Не удалось остановить контейнеры. Проверьте логи Docker.${RESET}"
    exit 1
}

# Запуск контейнеров
$rebuildFlag = -not $NoRebuild
$started = Start-Containers -RebuildImages $rebuildFlag

if (-not $started) {
    Write-Host "${RED}Не удалось запустить контейнеры. Проверьте логи Docker.${RESET}"
    exit 1
}

# Проверка статуса контейнеров
$status = Get-ContainerStatus

# Очистка при необходимости
if ($Prune) {
    Clear-DockerResources | Out-Null
}

# Вывод итогов
Write-Host ""
Write-Host "${BLUE}=== Итоги операции ===${RESET}"

if ($status) {
    Write-Host "${GREEN}✓ Все контейнеры успешно запущены${RESET}"

    # Вывод информации о доступе к сервисам
    Write-Host ""
    Write-Host "${BLUE}=== Доступ к сервисам ===${RESET}"
    Write-Host "${GREEN}• Backend API: http://localhost:8000${RESET}"
    Write-Host "${GREEN}• Frontend: http://localhost:3000${RESET}"
    Write-Host "${GREEN}• FinGPT: http://localhost:5000${RESET}"

    if ($UseOptimized) {
        Write-Host "${GREEN}• Prometheus: http://localhost:9090${RESET}"
        Write-Host "${GREEN}• Grafana: http://localhost:3001${RESET}"
    }

    Write-Host ""
    Write-Host "${YELLOW}Для мониторинга контейнеров выполните:${RESET}"
    Write-Host "${CYAN}./scripts/docker/monitor-containers.ps1${RESET}"

    exit 0
} else {
    Write-Host "${RED}✗ Не все контейнеры запущены успешно. Проверьте логи Docker для диагностики проблем.${RESET}"

    Write-Host ""
    Write-Host "${YELLOW}Для просмотра логов выполните:${RESET}"
    Write-Host "${CYAN}docker compose logs -f${RESET}"

    exit 1
}
