# Скрипт для сканирования и анализа Docker контейнеров на безопасность
# Автор: GitHub Copilot
# Дата: 16.09.2025

param(
    [Parameter(Mandatory=$false)]
    [string]$ImageName,     # Имя образа для сканирования

    [Parameter(Mandatory=$false)]
    [string]$ReportFile,    # Файл для сохранения отчета

    [switch]$ScanAll,       # Сканировать все образы проекта
    [switch]$JsonFormat,    # Вывод в формате JSON
    [switch]$IncludeBase    # Включить базовые образы в сканирование
)

# Определяем цвета для вывода
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$BLUE = "`e[34m"
$MAGENTA = "`e[35m"
$RESET = "`e[0m"

# Выводим баннер
Write-Host "$MAGENTA"
Write-Host "  _____             _              _____                 _   "
Write-Host " |  __ \           | |            / ____|               | |  "
Write-Host " | |  | | ___   ___| | _____ _ __| (___   ___ ___  _   _| |_ "
Write-Host " | |  | |/ _ \ / __| |/ / _ \ '__|\___ \ / __/ _ \| | | | __|"
Write-Host " | |__| | (_) | (__|   <  __/ |   ____) | (_| (_) | |_| | |_ "
Write-Host " |_____/ \___/ \___|_|\_\___|_|  |_____/ \___\___/ \__,_|\__|"
Write-Host "$RESET"
Write-Host "${YELLOW}Инструмент для сканирования безопасности Docker-контейнеров${RESET}"
Write-Host ""

# Проверка Docker и Docker Scout
try {
    $dockerVersion = docker --version
    Write-Host "${GREEN}✓ Docker установлен: $dockerVersion${RESET}"

    $scoutVersion = docker scout --version 2>$null
    if ($scoutVersion) {
        Write-Host "${GREEN}✓ Docker Scout установлен: $scoutVersion${RESET}"
    } else {
        Write-Host "${YELLOW}⚠ Docker Scout не найден. Попытка использования встроенного в Docker CLI...${RESET}"
    }
} catch {
    Write-Host "${RED}✗ Docker не установлен или не запущен${RESET}"
    exit 1
}

# Функция для получения списка всех образов проекта
function Get-ProjectImages {
    try {
        $composeFile = if (Test-Path "docker-compose.yml") { "docker-compose.yml" } elseif (Test-Path "docker-compose.yml.optimized") { "docker-compose.yml.optimized" } else { $null }

        if (-not $composeFile) {
            Write-Host "${RED}✗ Файл docker-compose.yml не найден${RESET}"
            return @()
        }

        $images = @()

        # Запускаем compose config для получения образов
        $configOutput = docker compose -f $composeFile config --images 2>$null

        if ($configOutput) {
            $images = $configOutput -split "`n" | Where-Object { $_ -match '\S' }
        } else {
            # Альтернативный метод: чтение файла compose
            $composeContent = Get-Content $composeFile -Raw
            $services = Select-String -InputObject $composeContent -Pattern 'image:\s*([^\s]+)' -AllMatches

            foreach ($match in $services.Matches) {
                $images += $match.Groups[1].Value
            }
        }

        # Добавляем образы из Dockerfile, если они не были найдены через compose
        $dockerfiles = Get-ChildItem -Recurse -Filter Dockerfile* | Where-Object { $_.Name -ne "Dockerfile.optimized" -or $IncludeBase }

        foreach ($file in $dockerfiles) {
            $dirName = Split-Path -Leaf (Split-Path -Parent $file.FullName)
            $tagName = "htx$($dirName):local"

            if (-not ($images -contains $tagName)) {
                $images += $tagName
            }
        }

        return $images
    } catch {
        Write-Host "${RED}Ошибка при получении списка образов: $_${RESET}"
        return @()
    }
}

# Функция для сканирования образа
function Invoke-ImageScan {
    param(
        [string]$Image,
        [bool]$JsonOutput = $false
    )

    Write-Host "${BLUE}=== Сканирование образа: $Image ===${RESET}"

    try {
        # Проверяем, существует ли образ
        $imageExists = docker image inspect $Image 2>$null

        if (-not $imageExists) {
            Write-Host "${YELLOW}⚠ Образ $Image не найден. Пробуем собрать его...${RESET}"

            # Определяем директорию и пытаемся собрать образ
            $serviceName = $Image -replace "^htx", "" -replace ":.*$", ""

            if (Test-Path "$serviceName/Dockerfile") {
                docker build -t $Image -f "$serviceName/Dockerfile" "./$serviceName" 2>$null
            } elseif (Test-Path "Dockerfile.$serviceName") {
                docker build -t $Image -f "Dockerfile.$serviceName" . 2>$null
            } else {
                Write-Host "${RED}✗ Не удалось найти Dockerfile для $Image${RESET}"
                return $null
            }
        }

        # Сканируем образ с помощью Docker Scout
        $outputFormat = if ($JsonOutput) { "--format json" } else { "" }

        $scanResult = Invoke-Expression "docker scout cves $Image $outputFormat"

        if ($JsonOutput) {
            return $scanResult
        } else {
            Write-Host $scanResult

            # Получаем рекомендации
            Write-Host "${BLUE}=== Рекомендации по улучшению для $Image ===${RESET}"
            $recommendations = docker scout recommendations $Image 2>$null
            Write-Host $recommendations

            # Анализируем результаты
            $vulnerabilities = [regex]::Matches($scanResult, '(\d+)\s+(CRITICAL|HIGH|MEDIUM|LOW|UNKNOWN)').Groups | Where-Object { $_.Success -and $_.Name -eq 1 } | ForEach-Object { $_.Value }

            if ($vulnerabilities) {
                $total = ($vulnerabilities | Measure-Object -Sum).Sum
                $critical = ($vulnerabilities[0..4] | Where-Object { $_ -ne "" } | Measure-Object -Sum).Sum
                $high = ($vulnerabilities[5..9] | Where-Object { $_ -ne "" } | Measure-Object -Sum).Sum

                return @{
                    ImageName = $Image
                    Total = $total
                    Critical = $critical
                    High = $high
                    HasVulnerabilities = $true
                }
            } else {
                return @{
                    ImageName = $Image
                    Total = 0
                    Critical = 0
                    High = 0
                    HasVulnerabilities = $false
                }
            }
        }
    } catch {
        Write-Host "${RED}Ошибка при сканировании ${Image}: $_${RESET}"
        return $null
    }
}

# Основной блок выполнения
$results = @()

if ($ScanAll) {
    Write-Host "${BLUE}=== Сканирование всех образов проекта ===${RESET}"
    $images = Get-ProjectImages

    if ($images.Count -eq 0) {
        Write-Host "${RED}Не найдено образов для сканирования${RESET}"
        exit 1
    }

    Write-Host "${YELLOW}Найдены следующие образы:${RESET}"
    foreach ($image in $images) {
        Write-Host " - $image"
    }
    Write-Host ""

    foreach ($image in $images) {
        $result = Invoke-ImageScan -Image $image -JsonOutput $JsonFormat
        $results += $result
    }
} elseif ($ImageName) {
    $result = Invoke-ImageScan -Image $ImageName -JsonOutput $JsonFormat
    $results += $result
} else {
    Write-Host "${YELLOW}Не указан образ для сканирования. Используйте -ImageName или -ScanAll${RESET}"
    exit 1
}

# Формируем отчет
if (-not $JsonFormat -and $results.Count -gt 0) {
    Write-Host ""
    Write-Host "${BLUE}=== Сводный отчет ===${RESET}"

    $totalVulnerabilities = 0
    $totalCritical = 0
    $totalHigh = 0
    $imagesWithVulnerabilities = 0

    foreach ($result in $results) {
        if ($result -and $result.HasVulnerabilities) {
            $severity = if ($result.Critical -gt 0) {
                "${RED}КРИТИЧЕСКИЙ${RESET}"
            } elseif ($result.High -gt 0) {
                "${YELLOW}ВЫСОКИЙ${RESET}"
            } else {
                "${GREEN}СРЕДНИЙ/НИЗКИЙ${RESET}"
            }

            Write-Host "Образ: $($result.ImageName)"
            Write-Host " - Уровень риска: $severity"
            Write-Host " - Всего уязвимостей: $($result.Total)"
            Write-Host " - Критических: $($result.Critical)"
            Write-Host " - Высоких: $($result.High)"
            Write-Host ""

            $totalVulnerabilities += $result.Total
            $totalCritical += $result.Critical
            $totalHigh += $result.High
            $imagesWithVulnerabilities++
        }
    }

    Write-Host "${BLUE}Итого:${RESET}"
    Write-Host " - Образов с уязвимостями: $imagesWithVulnerabilities из $($results.Count)"
    Write-Host " - Всего уязвимостей: $totalVulnerabilities"
    Write-Host " - Критических уязвимостей: $totalCritical"
    Write-Host " - Высоких уязвимостей: $totalHigh"

    # Рекомендации
    Write-Host ""
    Write-Host "${BLUE}=== Рекомендации по обеспечению безопасности ===${RESET}"
    Write-Host "1. Запустите скрипт обновления зависимостей:"
    Write-Host "   ${YELLOW}./scripts/docker/update-dependencies.ps1${RESET}"
    Write-Host "2. Используйте оптимизированные Dockerfile:"
    Write-Host "   ${YELLOW}./scripts/docker/deploy-containers.ps1 -UseOptimized${RESET}"
    Write-Host "3. Регулярно обновляйте базовые образы и зависимости"
    Write-Host "4. Настройте непрерывное сканирование в CI/CD"

    # Сохранение отчета в файл, если указан
    if ($ReportFile) {
        $reportContent = @"
# Отчет по безопасности Docker-контейнеров
Дата: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Сводная информация
- Образов с уязвимостями: $imagesWithVulnerabilities из $($results.Count)
- Всего уязвимостей: $totalVulnerabilities
- Критических уязвимостей: $totalCritical
- Высоких уязвимостей: $totalHigh

## Детальная информация по образам
"@

        foreach ($result in $results) {
            if ($result -and $result.HasVulnerabilities) {
                $severity = if ($result.Critical -gt 0) {
                    "КРИТИЧЕСКИЙ"
                } elseif ($result.High -gt 0) {
                    "ВЫСОКИЙ"
                } else {
                    "СРЕДНИЙ/НИЗКИЙ"
                }

                $reportContent += @"

### Образ: $($result.ImageName)
- Уровень риска: $severity
- Всего уязвимостей: $($result.Total)
- Критических: $($result.Critical)
- Высоких: $($result.High)
"@
            }
        }

        $reportContent += @"

## Рекомендации по обеспечению безопасности
1. Запустите скрипт обновления зависимостей: `./scripts/docker/update-dependencies.ps1`
2. Используйте оптимизированные Dockerfile: `./scripts/docker/deploy-containers.ps1 -UseOptimized`
3. Регулярно обновляйте базовые образы и зависимости
4. Настройте непрерывное сканирование в CI/CD
"@

        $reportContent | Out-File -FilePath $ReportFile -Encoding utf8
        Write-Host "${GREEN}✓ Отчет сохранен в файл: $ReportFile${RESET}"
    }
} elseif ($JsonFormat -and $results.Count -gt 0) {
    # Вывод в формате JSON
    $results | ConvertTo-Json -Depth 5

    # Сохранение отчета в файл, если указан
    if ($ReportFile) {
        $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ReportFile -Encoding utf8
        Write-Host "${GREEN}✓ JSON отчет сохранен в файл: $ReportFile${RESET}"
    }
}
