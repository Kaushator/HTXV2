<#
.SYNOPSIS
    Оптимизирует код в проекте HTXV2 с использованием лучших практик.

.DESCRIPTION
    Этот скрипт запускает различные инструменты для форматирования, проверки и оптимизации
    кода как в бэкенде (Python), так и во фронтенде (JavaScript/TypeScript).

.PARAMETER Target
    Указывает, какую часть проекта оптимизировать: "Backend", "Frontend" или "All".

.EXAMPLE
    .\optimize-code.ps1 -Target Backend

.NOTES
    Автор: GitHub Copilot
    Дата: 2023-07-25
    Требования:
    - Для бэкенда: black, isort, ruff, pylint
    - Для фронтенда: eslint, prettier
#>

param(
    [ValidateSet("Backend", "Frontend", "All")]
    [string]$Target = "All"
)

# Настройка поведения при ошибке
$ErrorActionPreference = 'Continue'  # Продолжить выполнение даже при ошибках в инструментах оптимизации

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
}

Write-Info "Начало оптимизации кода для $Target..."

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

# Функция для оптимизации бэкенд-кода
function Optimize-Backend {
    Write-Info "Оптимизация бэкенд-кода..."

    # Проверка наличия необходимых инструментов
    $backendTools = @("black", "isort", "ruff", "pylint")
    $missingTools = @()

    foreach ($tool in $backendTools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missingTools += $tool
        }
    }

    if ($missingTools.Count -gt 0) {
        Write-Warning "Некоторые Python-инструменты отсутствуют: $($missingTools -join ', ')"
        $installTools = Read-Host "Хотите установить их сейчас? (y/n)"
        if ($installTools -eq 'y' -or $installTools -eq 'Y') {
            pip install --upgrade black isort ruff pylint
        }
        else {
            Write-Warning "Пропуск инструментов, которые не установлены."
        }
    }

    # Black форматирование
    if (Get-Command black -ErrorAction SilentlyContinue) {
        Write-Info "Запуск форматирования Black..."
        try {
            & black ./backend --exclude=venv
        }
        catch {
            Write-ErrorMsg "Ошибка при запуске Black: $_"
        }
    }

    # isort для сортировки импортов
    if (Get-Command isort -ErrorAction SilentlyContinue) {
        Write-Info "Запуск isort для организации импортов..."
        try {
            & isort ./backend --profile black
        }
        catch {
            Write-ErrorMsg "Ошибка при запуске isort: $_"
        }
    }

    # Ruff для быстрой проверки и автофиксации
    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        Write-Info "Запуск Ruff для быстрых исправлений..."
        try {
            & ruff check ./backend --fix
        }
        catch {
            Write-ErrorMsg "Ошибка при запуске ruff: $_"
        }
    }

    # Pylint для более глубокого анализа качества кода
    if (Get-Command pylint -ErrorAction SilentlyContinue) {
        Write-Info "Запуск Pylint для анализа качества кода..."
        try {
            & pylint --recursive=y ./backend
        }
        catch {
            Write-ErrorMsg "Ошибка при запуске pylint: $_"
        }
    }

    Write-Success "Оптимизация бэкенда завершена!"
}

# Функция для оптимизации фронтенд-кода
function Optimize-Frontend {
    Write-Info "Оптимизация фронтенд-кода..."

    # Проверка существования директории frontend
    if (-not (Test-Path "./frontend")) {
        Write-Warning "Директория frontend не найдена. Пропуск оптимизации фронтенда."
        return
    }

    # Проверка существования package.json
    if (-not (Test-Path "./frontend/package.json")) {
        Write-Warning "Файл frontend/package.json не найден. Пропуск оптимизации фронтенда."
        return
    }

    # Проверка наличия необходимых инструментов через npm
    Push-Location ./frontend

    $packageJson = Get-Content -Raw -Path package.json | ConvertFrom-Json

    # Линтинг и исправление с помощью ESLint
    if ($packageJson.devDependencies.eslint -or $packageJson.dependencies.eslint) {
        Write-Info "Запуск ESLint для исправления проблем..."
        if ($packageJson.scripts.lint) {
            try {
                npm run lint -- --fix
            }
            catch {
                Write-ErrorMsg "Ошибка при запуске ESLint: $_"
            }
        }
        else {
            try {
                npx eslint . --ext .js,.jsx,.ts,.tsx --fix
            }
            catch {
                Write-ErrorMsg "Ошибка при запуске ESLint через npx: $_"
            }
        }
    }
    else {
        Write-Warning "ESLint не найден в package.json. Пропуск линтинга."
    }

    # Форматирование с помощью Prettier
    if ($packageJson.devDependencies.prettier -or $packageJson.dependencies.prettier) {
        Write-Info "Запуск Prettier для форматирования кода..."
        if ($packageJson.scripts.format) {
            try {
                npm run format
            }
            catch {
                Write-ErrorMsg "Ошибка при запуске Prettier: $_"
            }
        }
        else {
            try {
                npx prettier --write "**/*.{js,jsx,ts,tsx,json,css,scss,md}"
            }
            catch {
                Write-ErrorMsg "Ошибка при запуске Prettier через npx: $_"
            }
        }
    }
    else {
        Write-Warning "Prettier не найден в package.json. Пропуск форматирования."
    }

    Pop-Location
    Write-Success "Оптимизация фронтенда завершена!"
}

# Выполнение оптимизации в зависимости от цели
if ($Target -eq "Backend" -or $Target -eq "All") {
    if (Test-Path "./backend") {
        Optimize-Backend
    }
    else {
        Write-Warning "Директория backend не найдена. Пропуск оптимизации бэкенда."
    }
}

if ($Target -eq "Frontend" -or $Target -eq "All") {
    if (Test-Path "./frontend") {
        Optimize-Frontend
    }
    else {
        Write-Warning "Директория frontend не найдена. Пропуск оптимизации фронтенда."
    }
}

Write-Success "Оптимизация кода успешно завершена!"
