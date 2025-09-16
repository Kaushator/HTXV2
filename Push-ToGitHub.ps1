<#
.SYNOPSIS
    Скрипт для синхронизации изменений с GitHub репозиторием
    
.DESCRIPTION
    Скрипт выполняет все необходимые шаги для добавления, коммита и отправки изменений
    в GitHub репозиторий. Также включает проверку состояния репозитория и
    форматирование кода перед отправкой.
    
.PARAMETER Message
    Сообщение коммита. Если не указано, будет запрошено во время выполнения.

.PARAMETER Branch
    Ветка для отправки изменений. По умолчанию используется текущая ветка.

.PARAMETER SkipFormatting
    Пропустить шаг форматирования кода.

.PARAMETER Force
    Использовать флаг --force-with-lease при push.
    
.EXAMPLE
    .\Push-ToGitHub.ps1 -Message "Добавлен скрипт настройки Copilot"
    
.EXAMPLE
    .\Push-ToGitHub.ps1 -Branch "feature/copilot-integration"
#>

param (
    [string]$Message = "",
    [string]$Branch = "",
    [switch]$SkipFormatting = $false,
    [switch]$Force = $false
)

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
    exit 1
}

function Write-Section {
    param ([string]$Title)
    Write-ColorOutput "========== $Title ==========" "DarkCyan"
}

function Test-GitInstalled {
    try {
        git --version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-GitStatus {
    try {
        $status = git status -s
        return $status
    }
    catch {
        Write-ErrorMsg ("Не удалось получить статус Git: {0}" -f $_)
    }
}

function Get-CurrentBranch {
    try {
        $branch = git branch --show-current
        return $branch
    }
    catch {
        Write-ErrorMsg ("Не удалось получить текущую ветку Git: {0}" -f $_)
    }
}

function Invoke-CodeFormatting {
    Write-Section "Форматирование кода"
    
    # Форматирование Python кода
    if (Test-Path "backend") {
        Write-Info "Форматирование Python кода..."
        try {
            black backend --quiet
            isort backend --quiet
            Write-Success "Python код отформатирован"
        }
        catch {
            Write-Warning ("Ошибка при форматировании Python кода: {0}" -f $_)
            Write-Info "Форматирование Python кода будет пропущено. Установите black и isort для автоматического форматирования."
        }
    }
    
    # Форматирование JavaScript/TypeScript кода
    if ((Test-Path "frontend") -and (Test-Path "package.json")) {
        Write-Info "Форматирование JavaScript/TypeScript кода..."
        try {
            npm run format --if-present
            Write-Success "JavaScript/TypeScript код отформатирован"
        }
        catch {
            Write-Warning ("Ошибка при форматировании JavaScript/TypeScript кода: {0}" -f $_)
            Write-Info "Форматирование JavaScript/TypeScript кода будет пропущено. Убедитесь, что в package.json есть script 'format'."
        }
    }
}

function Add-ChangesToGit {
    param (
        [array]$Files = @()
    )
    
    Write-Section "Добавление изменений в Git"
    
    if ($Files.Count -eq 0) {
        Write-Info "Добавление всех изменений..."
        git add .
    }
    else {
        Write-Info ("Добавление {0} файлов..." -f $Files.Count)
        foreach ($file in $Files) {
            git add $file
        }
    }
    
    $status = Get-GitStatus
    if ([string]::IsNullOrEmpty($status)) {
        Write-Warning "Нет изменений для коммита."
        exit 0
    }
    else {
        Write-Info "Статус файлов для коммита:"
        $status | ForEach-Object { Write-Host "  $_" }
    }
}

function New-GitCommit {
    param (
        [string]$CommitMessage
    )
    
    Write-Section "Создание коммита"
    
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        $CommitMessage = Read-Host "Введите сообщение коммита"
    }
    
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        Write-ErrorMsg "Сообщение коммита не может быть пустым."
    }
    
    try {
        git commit -m $CommitMessage
        Write-Success "Коммит создан с сообщением: $CommitMessage"
    }
    catch {
        Write-ErrorMsg ("Ошибка при создании коммита: {0}" -f $_)
    }
}

function Push-GitChanges {
    param (
        [string]$BranchName,
        [bool]$UseForce
    )
    
    Write-Section "Отправка изменений в GitHub"
    
    if ([string]::IsNullOrEmpty($BranchName)) {
        $BranchName = Get-CurrentBranch
    }
    
    $pushCommand = "git push origin $BranchName"
    if ($UseForce) {
        $pushCommand = "git push origin $BranchName --force-with-lease"
    }
    
    try {
        Write-Info "Отправка изменений в ветку '$BranchName'..."
        Invoke-Expression $pushCommand
        Write-Success "Изменения успешно отправлены в GitHub!"
    }
    catch {
        Write-ErrorMsg ("Ошибка при отправке изменений в GitHub: {0}" -f $_)
    }
}

# Главная функция скрипта
function Sync-GitHubRepository {
    param (
        [string]$CommitMessage,
        [string]$BranchName,
        [bool]$SkipFormatCode,
        [bool]$ForceOption
    )
    
    # Проверка наличия Git
    if (-not (Test-GitInstalled)) {
        Write-ErrorMsg "Git не установлен. Пожалуйста, установите Git и повторите попытку."
    }
    
    # Проверка, находимся ли мы в Git-репозитории
    try {
        git rev-parse --is-inside-work-tree | Out-Null
    }
    catch {
        Write-ErrorMsg "Текущая директория не является Git-репозиторием."
    }
    
    # Получение текущей ветки, если не указана
    if ([string]::IsNullOrEmpty($BranchName)) {
        $BranchName = Get-CurrentBranch
        Write-Info "Используется текущая ветка: $BranchName"
    }
    
    # Форматирование кода (если не пропущено)
    if (-not $SkipFormatCode) {
        Invoke-CodeFormatting
    }
    else {
        Write-Info "Форматирование кода пропущено."
    }
    
    # Добавление изменений
    Add-ChangesToGit
    
    # Создание коммита
    New-GitCommit -CommitMessage $CommitMessage
    
    # Отправка изменений
    Push-GitChanges -BranchName $BranchName -UseForce $ForceOption
    
    Write-Section "Завершение"
    Write-Info "Ссылка на репозиторий: https://github.com/Kaushator/HTXV2"
    Write-Info "Текущая ветка: $BranchName"
}

# Запуск главной функции
Sync-GitHubRepository -CommitMessage $Message -BranchName $Branch -SkipFormatCode $SkipFormatting -ForceOption $Force