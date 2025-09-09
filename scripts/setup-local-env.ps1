# PowerShell скрипт для быстрой настройки локальной среды разработки
# setup-local-env.ps1

param(
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Скрипт для настройки локальной среды разработки HTX Interface

Использование:
    .\scripts\setup-local-env.ps1

Что делает скрипт:
- Проверяет наличие необходимых утилит (terraform, gcloud)
- Создает .env файлы с переменными окружения
- Настраивает gcloud CLI
- Настраивает Docker для Artifact Registry
- Создает полезные функции для разработки

Требования:
- Terraform CLI
- Google Cloud SDK (gcloud)
- PowerShell 5.1 или выше
"@
    exit 0
}

# Функция для проверки команд
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "🚀 Настройка локальной среды разработки HTX Interface..." -ForegroundColor Green

# Проверяем наличие необходимых утилит
if (-not (Test-Command "terraform")) {
    Write-Host "❌ Terraform не установлен. Установите: https://terraform.io/downloads" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "gcloud")) {
    Write-Host "❌ gcloud CLI не установлен. Установите: https://cloud.google.com/sdk/docs/install" -ForegroundColor Red
    exit 1
}

# Определяем пути
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$TerraformDir = Join-Path $ProjectRoot "infra\terraform"

if (-not (Test-Path $TerraformDir)) {
    Write-Host "❌ Terraform директория не найдена: $TerraformDir" -ForegroundColor Red
    exit 1
}

Set-Location $TerraformDir
Write-Host "📁 Работаем в директории: $(Get-Location)" -ForegroundColor Blue

# Проверяем, что Terraform инициализирован
if (-not (Test-Path ".terraform")) {
    Write-Host "🔧 Инициализация Terraform..." -ForegroundColor Yellow
    terraform init
}

# Получаем outputs из Terraform
Write-Host "📊 Получение Terraform outputs..." -ForegroundColor Blue

try {
    terraform output | Out-Null
}
catch {
    Write-Host "❌ Terraform outputs недоступны. Убедитесь, что terraform apply был выполнен." -ForegroundColor Red
    Write-Host "💡 Выполните: cd $TerraformDir && terraform apply" -ForegroundColor Yellow
    exit 1
}

# Создаем .env файл в корне проекта
Write-Host "📝 Создание .env файла..." -ForegroundColor Blue
$envVars = terraform output -json local_env_vars | ConvertFrom-Json
$envContent = @()
$envVars.PSObject.Properties | ForEach-Object {
    $envContent += "$($_.Name)=$($_.Value)"
}
$envContent -join "`n" | Out-File -FilePath (Join-Path $ProjectRoot ".env") -Encoding UTF8

# Создаем .env файл для frontend
Write-Host "📝 Создание .env.local для frontend..." -ForegroundColor Blue
$frontendDir = Join-Path $ProjectRoot "frontend"
if (-not (Test-Path $frontendDir)) {
    New-Item -ItemType Directory -Path $frontendDir -Force | Out-Null
}

$backendUrl = terraform output -raw backend_url
$websocketUrl = terraform output -raw websocket_url
$fingptUrl = terraform output -raw fingpt_url

$frontendEnv = @"
NEXT_PUBLIC_BACKEND_URL=$backendUrl
NEXT_PUBLIC_WS_URL=$websocketUrl/ws
NEXT_PUBLIC_FINGPT_URL=$fingptUrl
"@

$frontendEnv | Out-File -FilePath (Join-Path $frontendDir ".env.local") -Encoding UTF8

# Настраиваем gcloud CLI
Write-Host "⚙️  Настройка gcloud CLI..." -ForegroundColor Blue
$projectInfo = terraform output -json project_info | ConvertFrom-Json
$projectId = $projectInfo.project_id
$region = $projectInfo.region
$zone = $projectInfo.zone

gcloud config set project $projectId
gcloud config set compute/region $region
gcloud config set compute/zone $zone

# Настраиваем Docker для Artifact Registry
Write-Host "🐳 Настройка Docker для Artifact Registry..." -ForegroundColor Blue
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# Создаем PowerShell модуль с полезными функциями
Write-Host "📋 Создание PowerShell модуля с полезными функциями..." -ForegroundColor Blue
$scriptsDir = Join-Path $ProjectRoot "scripts"
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

$devModule = @'
# HTX Interface Development Module
# Import: Import-Module .\scripts\HTXDev.psm1

function Get-ServiceUrls {
    <#
    .SYNOPSIS
    Получить URL всех сервисов
    #>
    Push-Location "infra\terraform"
    try {
        $backend = terraform output -raw backend_url
        $frontend = terraform output -raw frontend_url
        $fingpt = terraform output -raw fingpt_url
        $websocket = terraform output -raw websocket_url
        
        Write-Host "Backend:   $backend" -ForegroundColor Green
        Write-Host "Frontend:  $frontend" -ForegroundColor Green
        Write-Host "FinGPT:    $fingpt" -ForegroundColor Green
        Write-Host "WebSocket: $websocket/ws" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

function Test-ServiceHealth {
    <#
    .SYNOPSIS
    Проверить health endpoints всех сервисов
    #>
    Push-Location "infra\terraform"
    try {
        $backend = terraform output -raw backend_url
        $frontend = terraform output -raw frontend_url
        $fingpt = terraform output -raw fingpt_url
        
        Write-Host "🔍 Проверка health endpoints..." -ForegroundColor Blue
        
        try {
            $backendHealth = Invoke-RestMethod "$backend/health" -TimeoutSec 10
            Write-Host "Backend:  $($backendHealth.status)" -ForegroundColor Green
        }
        catch {
            Write-Host "Backend:  ERROR" -ForegroundColor Red
        }
        
        try {
            $frontendHealth = Invoke-RestMethod "$frontend/health" -TimeoutSec 10
            Write-Host "Frontend: $($frontendHealth.status)" -ForegroundColor Green
        }
        catch {
            Write-Host "Frontend: ERROR" -ForegroundColor Red
        }
        
        try {
            $fingptHealth = Invoke-RestMethod "$fingpt/health" -TimeoutSec 10
            Write-Host "FinGPT:   $($fingptHealth.status)" -ForegroundColor Green
        }
        catch {
            Write-Host "FinGPT:   ERROR" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Deploy-Service {
    <#
    .SYNOPSIS
    Быстрый деплой сервиса
    .PARAMETER Service
    Имя сервиса: backend, frontend, fingpt, или all
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("backend", "frontend", "fingpt", "all")]
        [string]$Service
    )
    
    Push-Location "infra\terraform"
    try {
        $deployCommands = terraform output -json deploy_commands | ConvertFrom-Json
        
        if ($Service -eq "all") {
            Write-Host "🚀 Деплой всех сервисов..." -ForegroundColor Blue
            Invoke-Expression $deployCommands.backend
            Invoke-Expression $deployCommands.frontend
            Invoke-Expression $deployCommands.fingpt
        }
        else {
            Write-Host "🚀 Деплой $Service..." -ForegroundColor Blue
            Invoke-Expression $deployCommands.$Service
        }
    }
    finally {
        Pop-Location
    }
}

function Get-ServiceLogs {
    <#
    .SYNOPSIS
    Получить логи сервиса
    .PARAMETER Service
    Имя сервиса: backend, frontend, fingpt
    .PARAMETER Limit
    Количество последних записей (по умолчанию 50)
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("backend", "frontend", "fingpt")]
        [string]$Service,
        [int]$Limit = 50
    )
    
    $filter = "resource.type=cloud_run_revision AND resource.labels.service_name=htx-interface-$Service"
    gcloud logs read $filter --limit $Limit
}

function Get-DockerImages {
    <#
    .SYNOPSIS
    Загрузить Docker образы для локальной разработки
    #>
    Push-Location "infra\terraform"
    try {
        Write-Host "🐳 Получение информации о Docker образах..." -ForegroundColor Blue
        $images = terraform output -json docker_images | ConvertFrom-Json
        
        Write-Host "Backend:  $($images.backend)" -ForegroundColor Green
        Write-Host "Frontend: $($images.frontend)" -ForegroundColor Green
        Write-Host "FinGPT:   $($images.fingpt)" -ForegroundColor Green
        
        $pull = Read-Host "Загрузить образы локально? (y/N)"
        if ($pull -eq "y" -or $pull -eq "Y") {
            Write-Host "🐳 Загрузка Docker образов..." -ForegroundColor Blue
            docker pull $images.backend
            docker pull $images.frontend
            docker pull $images.fingpt
            
            Write-Host "`n✅ Образы загружены. Для запуска используйте:" -ForegroundColor Green
            Write-Host "docker run -p 8000:8000 $($images.backend)" -ForegroundColor Yellow
            Write-Host "docker run -p 3000:3000 $($images.frontend)" -ForegroundColor Yellow
            Write-Host "docker run -p 8055:8055 $($images.fingpt)" -ForegroundColor Yellow
        }
    }
    finally {
        Pop-Location
    }
}

function Show-DevCommands {
    <#
    .SYNOPSIS
    Показать доступные команды для разработки
    #>
    Write-Host "`nДоступные команды HTX Interface:" -ForegroundColor Cyan
    Write-Host "  Get-ServiceUrls    - получить URL всех сервисов" -ForegroundColor White
    Write-Host "  Test-ServiceHealth - проверить health endpoints" -ForegroundColor White
    Write-Host "  Deploy-Service     - деплой сервиса (backend|frontend|fingpt|all)" -ForegroundColor White
    Write-Host "  Get-ServiceLogs    - получить логи сервиса" -ForegroundColor White
    Write-Host "  Get-DockerImages   - получить информацию о Docker образах" -ForegroundColor White
    Write-Host "  Show-DevCommands   - показать эту справку" -ForegroundColor White
    Write-Host "`nПример использования:" -ForegroundColor Cyan
    Write-Host "  Get-ServiceUrls" -ForegroundColor Yellow
    Write-Host "  Test-ServiceHealth" -ForegroundColor Yellow
    Write-Host "  Deploy-Service -Service backend" -ForegroundColor Yellow
    Write-Host "  Get-ServiceLogs -Service backend -Limit 100" -ForegroundColor Yellow
}

# Автоматически показать доступные команды при импорте модуля
Show-DevCommands

# Aliases для удобства
Set-Alias -Name "urls" -Value "Get-ServiceUrls"
Set-Alias -Name "health" -Value "Test-ServiceHealth"
Set-Alias -Name "deploy" -Value "Deploy-Service"
Set-Alias -Name "logs" -Value "Get-ServiceLogs"
Set-Alias -Name "images" -Value "Get-DockerImages"
Set-Alias -Name "help-dev" -Value "Show-DevCommands"

Export-ModuleMember -Function * -Alias *
'@

$devModule | Out-File -FilePath (Join-Path $scriptsDir "HTXDev.psm1") -Encoding UTF8

# Создаем батч файл для быстрого запуска
$batchContent = @"
@echo off
cd /d "%~dp0.."
powershell -ExecutionPolicy Bypass -Command "Import-Module .\scripts\HTXDev.psm1; Write-Host 'HTX Interface Dev Environment загружена!' -ForegroundColor Green"
pause
"@

$batchContent | Out-File -FilePath (Join-Path $ProjectRoot "dev-env.bat") -Encoding ASCII

Set-Location $ProjectRoot

Write-Host "`n✅ Локальная среда настроена!" -ForegroundColor Green
Write-Host "`n📋 Что было создано:" -ForegroundColor Cyan
Write-Host "  ✓ .env файл в корне проекта" -ForegroundColor White
Write-Host "  ✓ .env.local файл для frontend" -ForegroundColor White
Write-Host "  ✓ gcloud CLI настроен для проекта $projectId" -ForegroundColor White
Write-Host "  ✓ Docker настроен для Artifact Registry" -ForegroundColor White
Write-Host "  ✓ PowerShell модуль HTXDev.psm1 создан" -ForegroundColor White
Write-Host "  ✓ Батч файл dev-env.bat для быстрого запуска" -ForegroundColor White

Write-Host "`n🚀 Быстрый старт:" -ForegroundColor Cyan
Write-Host "  .\dev-env.bat                    # Загрузить dev environment (Windows)" -ForegroundColor Yellow
Write-Host "  Import-Module .\scripts\HTXDev.psm1  # Загрузить модуль вручную" -ForegroundColor Yellow
Write-Host "  Get-ServiceUrls                  # Получить URL сервисов" -ForegroundColor Yellow
Write-Host "  Test-ServiceHealth               # Проверить статус сервисов" -ForegroundColor Yellow

Write-Host "`n📖 Подробная документация: docs\terraform-outputs.md" -ForegroundColor Cyan
