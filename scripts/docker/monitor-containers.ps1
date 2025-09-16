# Скрипт для мониторинга состояния контейнеров и их ресурсов
# Автор: GitHub Copilot
# Дата: 16.09.2025

param(
    [switch]$Watch,    # Непрерывный мониторинг
    [int]$Interval = 5 # Интервал обновления в секундах для режима Watch
)

# Определяем цвета для вывода
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

function Show-ContainerStats {
    Clear-Host
    Write-Host "${BLUE}=== Мониторинг Docker-контейнеров HTXEnterface_v2 ===${RESET}"
    Write-Host "${YELLOW}Дата и время: $(Get-Date)${RESET}"
    Write-Host ""

    # Получаем список запущенных контейнеров
    $containers = docker ps --filter "name=htx" --format "{{.Names}}"

    if (-not $containers) {
        Write-Host "${RED}Не обнаружено запущенных контейнеров с префиксом 'htx'${RESET}"
        return
    }

    # Выводим таблицу с заголовком
    Write-Host "${BLUE}КОНТЕЙНЕР             CPU    ПАМЯТЬ     СЕТЬ(IN/OUT)      СТАТУС${RESET}"
    Write-Host "${YELLOW}------------------------------------------------------------------${RESET}"

    # Получаем статистику для каждого контейнера
    foreach ($container in $containers) {
        # Получаем статистику без заголовка, один раз
        $statOutput = docker stats $container --no-stream --no-trunc --format "{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}|{{.Status}}"
        $stats = $statOutput.Split('|')

        if ($stats.Count -ge 4) {
            $cpuPerc = $stats[0].Trim()
            $memUsage = $stats[1].Trim()
            $netIO = $stats[2].Trim()
            $status = $stats[3].Trim()

            # Определяем цвет для статуса
            $statusColor = $GREEN
            if ($status -like "*Restarting*" -or $status -like "*Starting*") {
                $statusColor = $YELLOW
            }
            if ($status -like "*Exited*") {
                $statusColor = $RED
            }

            # Форматируем строку
            $containerName = $container.PadRight(20).Substring(0, 20)
            $cpuPerc = $cpuPerc.PadRight(7)
            $memUsage = $memUsage.PadRight(10)
            $netIO = $netIO.PadRight(18)

            # Выводим строку статистики
            Write-Host "${containerName} ${cpuPerc} ${memUsage} ${netIO} ${statusColor}${status}${RESET}"
        }
    }

    Write-Host ""
    Write-Host "${YELLOW}Проверка работоспособности сервисов:${RESET}"

    # Проверяем доступность основных сервисов через healthcheck
    $services = @(
        @{Name="Backend API"; Url="http://localhost:8000/health"},
        @{Name="Frontend"; Url="http://localhost:3000"},
        @{Name="FinGPT"; Url="http://localhost:8055/health"}
    )

    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.Url -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "${GREEN}✓ ${service.Name}: Доступен${RESET}"
            } else {
                Write-Host "${YELLOW}⚠ ${service.Name}: Ответ ${response.StatusCode}${RESET}"
            }
        } catch {
            Write-Host "${RED}✗ ${service.Name}: Недоступен${RESET}"
        }
    }

    # Предложения по оптимизации
    Write-Host ""
    $highCpuContainers = docker stats --no-stream --format "{{.Name}}:{{.CPUPerc}}" | Where-Object { $_ -match ":([0-9\.]+)%" -and [double]$Matches[1] -gt 50 }
    $highMemContainers = docker stats --no-stream --format "{{.Name}}:{{.MemPerc}}" | Where-Object { $_ -match ":([0-9\.]+)%" -and [double]$Matches[1] -gt 70 }

    if ($highCpuContainers -or $highMemContainers) {
        Write-Host "${YELLOW}Рекомендации:${RESET}"

        if ($highCpuContainers) {
            Write-Host "${YELLOW}⚠ Высокая загрузка CPU в контейнерах:${RESET} $($highCpuContainers -join ', ')"
        }

        if ($highMemContainers) {
            Write-Host "${YELLOW}⚠ Высокое использование памяти в контейнерах:${RESET} $($highMemContainers -join ', ')"
        }
    }
}

# Основной блок выполнения
if ($Watch) {
    try {
        while ($true) {
            Show-ContainerStats
            Write-Host ""
            Write-Host "${YELLOW}Режим мониторинга в реальном времени. Ctrl+C для выхода. Обновление каждые ${Interval}s${RESET}"
            Start-Sleep -Seconds $Interval
        }
    } catch {
        Write-Host "${RED}Мониторинг остановлен.${RESET}"
    }
} else {
    Show-ContainerStats
}
