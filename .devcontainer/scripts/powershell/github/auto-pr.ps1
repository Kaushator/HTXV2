<#
.SYNOPSIS
    Автоматически создаёт PR для изменений кода с AI-генерированным описанием.

.DESCRIPTION
    Скрипт создаёт Pull Request для текущей ветки с автоматически
    сгенерированным описанием, которое включает список изменённых файлов и
    коммитов. Можно указать название PR или использовать последний коммит.

.PARAMETER Title
    Название для Pull Request. Если не указано, будет использовано сообщение последнего коммита.

.PARAMETER Branch
    Ветка для PR. Если не указана, используется текущая ветка.

.EXAMPLE
    .\auto-pr.ps1 -Title "Добавлена поддержка аутентификации через JWT"

.EXAMPLE
    .\auto-pr.ps1 -Branch feature/new-login-ui

.NOTES
    Автор: GitHub Copilot
    Дата: 2023-07-25
    Требования:
    - Git CLI
    - GitHub CLI (gh) с аутентификацией
#>

param(
    [string]$Title = "",
    [string]$Branch = ""
)

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

# Проверка установки Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "Git не установлен. Пожалуйста, установите Git и повторите попытку."
}

# Проверка установки GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "GitHub CLI (gh) не установлен. Пожалуйста, установите его."
    Write-Info "Посетите https://cli.github.com/ для инструкций по установке."
}

# Проверка аутентификации с GitHub CLI
try {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not authenticated"
    }
}
catch {
    Write-ErrorMsg "Не аутентифицирован с GitHub CLI. Пожалуйста, запустите 'gh auth login' сначала."
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

# Получение текущей ветки, если не указана
if ([string]::IsNullOrEmpty($Branch)) {
    $Branch = git branch --show-current
}

Write-Info "Работа с веткой: $Branch"

# Проверка наличия незакоммиченных изменений
$hasChanges = $false
try {
    git diff --quiet
    git diff --staged --quiet
}
catch {
    $hasChanges = $true
}

if ($hasChanges) {
    Write-Warning "У вас есть незакоммиченные изменения."
    $commitNow = Read-Host "Хотите закоммитить их сейчас? (y/n)"
    if ($commitNow -eq 'y' -or $commitNow -eq 'Y') {
        # Запрос сообщения коммита, если не предоставлено
        if ([string]::IsNullOrEmpty($Title)) {
            $commitMessage = Read-Host "Введите сообщение коммита"
        }
        else {
            $commitMessage = $Title
        }

        git add .
        git commit -m "$commitMessage"
        Write-Success "Изменения закоммичены."
    }
    else {
        Write-ErrorMsg "Пожалуйста, закоммитьте ваши изменения перед созданием PR."
    }
}

# Отправка изменений в удаленный репозиторий
Write-Info "Отправка изменений в удаленный репозиторий..."
try {
    git push -u origin "$Branch"
}
catch {
    Write-ErrorMsg "Не удалось отправить в удаленный репозиторий: $_"
}

# Генерация AI-резюме изменений
Write-Info "Генерация AI-резюме изменений..."

# Получение ветки по умолчанию
$defaultBranch = git remote show origin | Select-String "HEAD branch" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

# Получение измененных файлов
$changedFiles = git diff --name-only origin/"$defaultBranch"..."$Branch"

# Генерация описания PR
$prDescription = "## AI-Сгенерированное резюме`n`nЭтот PR включает изменения в следующих файлах:`n`n"

foreach ($file in $changedFiles) {
    $prDescription += "- ``$file```n"
}

$prDescription += "`n`n## Резюме коммитов`n`n"

# Получение сообщений коммитов с момента ответвления от ветки по умолчанию
$commitMessages = git log origin/"$defaultBranch"..."$Branch" --pretty=format:"- %s"
$prDescription += "$commitMessages`n`n"

$prDescription += "`n`n## Инструкции по тестированию`n`nПожалуйста, проверьте изменения путем:`n`n1. Загрузки этой ветки`n2. Тестирования функциональности, связанной с изменениями`n3. Проверки качества кода`n`n"

# Создание PR
if ([string]::IsNullOrEmpty($Title)) {
    # Использование последнего сообщения коммита как заголовка PR
    $Title = git log -1 --pretty=%B | Select-Object -First 1
}

Write-Info "Создание PR с заголовком: $Title"
try {
    $prUrl = gh pr create --title "$Title" --body "$prDescription" --base "$defaultBranch" --head "$Branch"

    Write-Success "PR успешно создан!"
    Write-Info "URL PR: $prUrl"

    # Открытие PR в браузере
    gh pr view --web
}
catch {
    Write-ErrorMsg "Не удалось создать PR: $_"
}
