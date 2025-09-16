<#
.SYNOPSIS
    Локально тестирует рабочие процессы GitHub Actions.

.DESCRIPTION
    Этот скрипт запускает локальное тестирование рабочих процессов GitHub Actions
    с помощью инструмента act. Позволяет выбрать конкретный workflow и событие
    для его запуска в локальной среде.

.EXAMPLE
    .\github-actions-test.ps1

.NOTES
    Автор: GitHub Copilot
    Дата: 2023-07-25
    Требования:
    - act (https://github.com/nektos/act)
    - Docker
    - Файлы рабочих процессов GitHub Actions в .github/workflows/
#>

# Настройка поведения при ошибке
$ErrorActionPreference = 'Stop'

# Цветные сообщения для вывода
function Write-ColorOutput {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$Color
    )

    $currentForeground = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $currentForeground
}

function Write-Info {
    param ([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param ([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param ([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-ErrorMsg {
    param ([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
    throw $Message
}

# Проверка установки act
if (-not (Get-Command act -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "'act' не установлен. Вам нужен этот инструмент для локального тестирования GitHub Actions."
    Write-Info "Инструкции по установке: https://github.com/nektos/act#installation"
    exit 1
}

# Проверка работы Docker
try {
    docker info | Out-Null
}
catch {
    Write-ErrorMsg "Docker не запущен. Пожалуйста, запустите Docker и попробуйте снова."
    exit 1
}

# Получение корневой директории проекта
try {
    $projectRoot = git rev-parse --show-toplevel 2>$null
    if (-not $projectRoot) {
        $projectRoot = Get-Location
    }
}
catch {
    $projectRoot = Get-Location
}

Set-Location $projectRoot

# Проверка существования директории workflows
if (-not (Test-Path ".github\workflows")) {
    Write-ErrorMsg "Рабочие процессы GitHub Actions не найдены в .github\workflows\"
    Write-Info "Сначала запустите setup-github-actions.ps1, чтобы создать рабочие процессы."
    exit 1
}

# Список доступных рабочих процессов
Write-Info "Доступные рабочие процессы GitHub Actions:"
$workflows = Get-ChildItem -Path ".github\workflows" -Filter *.yml | ForEach-Object { $_.BaseName }
$workflows | ForEach-Object { Write-Output "  - $_" }

# Запрос, какой рабочий процесс тестировать
Write-Output ""
$workflowName = Read-Host "Какой рабочий процесс вы хотите протестировать? (Введите имя файла без расширения)"

# Проверка существования рабочего процесса
if (-not (Test-Path ".github\workflows\$workflowName.yml") -and -not (Test-Path ".github\workflows\$workflowName.yaml")) {
    Write-ErrorMsg "Рабочий процесс '$workflowName' не найден."
    exit 1
}

# Получение расширения файла
$workflowExt = "yml"
if (Test-Path ".github\workflows\$workflowName.yaml") {
    $workflowExt = "yaml"
}

# Запрос события для запуска
Write-Output ""
$eventName = Read-Host "Какое событие вы хотите запустить? (push, pull_request, workflow_dispatch)"

# Запуск рабочего процесса
Write-Info "Тестирование рабочего процесса '$workflowName' с событием '$eventName'..."
act $eventName -W ".github\workflows\$workflowName.$workflowExt" -v

# Проверка результата
if ($LASTEXITCODE -eq 0) {
    Write-Success "Тестирование рабочего процесса завершено успешно!"
}
else {
    Write-ErrorMsg "Тестирование рабочего процесса завершилось с ошибками."
    Write-Info "Проверьте вывод выше для деталей."
}

exit 0
