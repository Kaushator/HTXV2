# Скрипт для запуска Docker-контейнеров проекта HTXEnterface_v2
# Автор: GitHub Copilot
# Дата: 16.09.2025

# Использование: ./start-containers.ps1 [опции]
# Опции:
#   -WithScout          Добавляет Docker Scout мониторинг
#   -EnvFile <путь>     Указать альтернативный файл окружения
#   -Ports <порты>      Указать альтернативные порты (формат: 8001:8000,3001:3000)
#   -WithMonitoring     Запустить мониторинг (Prometheus, Grafana)

param(
    [switch]$WithScout,
    [string]$EnvFile,
    [string]$Ports,
    [switch]$WithMonitoring
)

# Определяем цвета для вывода
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

# Выводим баннер
Write-Host "$BLUE"
Write-Host "   ___ _______  ______      _            __                 _   ___ "
Write-Host "  / _ \\_   _\\ \\/ /_  _/     | |_ __  ___ / _|___ _ _ _  __ _| |_/ __|"
Write-Host " | (_) || |  >  < | |   _   | ' \\ / -_)  _/ -_) '_| || (_-< | | (__ "
Write-Host "  \___/ |_| /_/\_\|_|  (_)  |_||_/___|_| \___|_|  \_, /__/_|_|\___|"
Write-Host "                                                  |__/             "
Write-Host "$RESET"
Write-Host "${YELLOW}Запуск Docker-контейнеров для HTXEnterface_v2${RESET}"
Write-Host ""

# Проверка, установлен ли Docker
try {
    $dockerVersion = docker --version
    Write-Host "${GREEN}✓ Docker установлен: ${dockerVersion}${RESET}"
} catch {
    Write-Host "${RED}✗ Docker не установлен или не добавлен в PATH${RESET}"
    exit 1
}

# Функция для проверки ошибок
function Check-Error {
    param (
        [int]$ExitCode,
        [string]$ErrorMessage
    )

    if ($ExitCode -ne 0) {
        Write-Host "${RED}✗ $ErrorMessage${RESET}"
        exit $ExitCode
    }
}

# Проверяем, свободны ли необходимые порты
$portsToCheck = @(8000, 3000, 6389, 5432)
foreach ($port in $portsToCheck) {
    $portInUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Host "${YELLOW}! Порт $port уже используется. Может возникнуть конфликт.${RESET}"
    }
}

# Определяем, какой compose-файл использовать
$composeFile = "docker-compose.yml.optimized"

# Переименовываем оптимизированные файлы, если это первый запуск
if (Test-Path "docker-compose.yml.optimized") {
    # Сделать резервную копию оригинального файла, если он существует и копия еще не создана
    if ((Test-Path "docker-compose.yml") -and (-not (Test-Path "docker-compose.yml.original"))) {
        Copy-Item "docker-compose.yml" "docker-compose.yml.original"
        Write-Host "${GREEN}✓ Создана резервная копия оригинального docker-compose.yml${RESET}"
    }

    # Переименовать оптимизированный файл в основной
    Copy-Item "docker-compose.yml.optimized" "docker-compose.yml"
    Write-Host "${GREEN}✓ Оптимизированный docker-compose.yml установлен как основной${RESET}"

    # Проверяем и копируем Dockerfile.optimized
    foreach ($dir in @("backend", "frontend", "fingpt")) {
        if (Test-Path "$dir/Dockerfile.optimized") {
            # Сделать резервную копию оригинального файла, если он существует и копия еще не создана
            if ((Test-Path "$dir/Dockerfile") -and (-not (Test-Path "$dir/Dockerfile.original"))) {
                Copy-Item "$dir/Dockerfile" "$dir/Dockerfile.original"
            }

            # Переименовать оптимизированный файл в основной
            Copy-Item "$dir/Dockerfile.optimized" "$dir/Dockerfile"
            Write-Host "${GREEN}✓ Оптимизированный $dir/Dockerfile установлен как основной${RESET}"
        }
    }
}

# Подготавливаем команду для запуска
$dockerCommand = "docker compose"

# Добавляем файл окружения, если указан
if ($EnvFile) {
    $dockerCommand += " --env-file $EnvFile"
}

# Строим и запускаем контейнеры
Write-Host "${YELLOW}Сборка и запуск контейнеров...${RESET}"

if ($WithMonitoring) {
    Write-Host "${BLUE}Включен режим с мониторингом (Prometheus, Grafana)${RESET}"
    $dockerCommand += " up -d postgres redis backend frontend fingpt prometheus grafana"
} else {
    $dockerCommand += " up -d postgres redis backend frontend fingpt"
}

# Запускаем контейнеры
Invoke-Expression $dockerCommand
Check-Error $LASTEXITCODE "Ошибка при запуске контейнеров"

# Добавляем мониторинг с Docker Scout
if ($WithScout) {
    Write-Host "${YELLOW}Настройка Docker Scout для мониторинга уязвимостей...${RESET}"
    Invoke-Expression "docker scout cves backend"
    Invoke-Expression "docker scout cves frontend"
    Invoke-Expression "docker scout cves fingpt"
    Write-Host "${GREEN}✓ Docker Scout настроен${RESET}"
}

# Проверяем, что все контейнеры запущены успешно
Write-Host "${YELLOW}Проверка статуса контейнеров...${RESET}"
$containersStatus = Invoke-Expression "docker compose ps"
Write-Host $containersStatus

# Выводим информацию о доступе к сервисам
Write-Host ""
Write-Host "${GREEN}=== Контейнеры успешно запущены ===${RESET}"
Write-Host "Сервисы доступны по следующим адресам:"
Write-Host "${BLUE}Backend API:${RESET} http://localhost:8000"
Write-Host "${BLUE}Frontend:${RESET} http://localhost:3000"
Write-Host "${BLUE}FinGPT:${RESET} http://localhost:8055"

if ($WithMonitoring) {
    Write-Host "${BLUE}Prometheus:${RESET} http://localhost:9090"
    Write-Host "${BLUE}Grafana:${RESET} http://localhost:3001 (admin/admin)"
}

Write-Host ""
Write-Host "${YELLOW}Для остановки контейнеров используйте: docker compose down${RESET}"
