<#
.SYNOPSIS
    Скрипт для исправления проблемы с вложенными Git-репозиториями

.DESCRIPTION
    Скрипт удаляет вложенные Git-репозитории из индекса Git и добавляет их как подмодули
    или игнорирует их в зависимости от выбора пользователя.

.PARAMETER ConvertToSubmodules
    Преобразовать вложенные репозитории в подмодули Git

.PARAMETER IgnoreOnly
    Только добавить вложенные репозитории в .gitignore

.EXAMPLE
    .\Fix-GitRepositories.ps1 -ConvertToSubmodules

.EXAMPLE
    .\Fix-GitRepositories.ps1 -IgnoreOnly
#>

param (
    [switch]$ConvertToSubmodules = $false,
    [switch]$IgnoreOnly = $false
)

function Write-ColorOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
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

function Get-EmbeddedGitRepositories {
    $embeddedRepos = @()

    # Поиск всех .git директорий
    Get-ChildItem -Path . -Filter ".git" -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $repoPath = $_.Parent.FullName
        $relativePath = $repoPath.Replace((Get-Location).Path, "").TrimStart("\").TrimStart("/")

        # Проверка, что это не корневой репозиторий
        if ($relativePath -ne "") {
            $embeddedRepos += $relativePath
        }
    }

    return $embeddedRepos
}

function Remove-EmbeddedRepository {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    try {
        Write-Info "Удаление вложенного репозитория '$RepoPath' из индекса Git..."
        git rm --cached $RepoPath | Out-Null
        Write-Success "Репозиторий '$RepoPath' удален из индекса Git."
        return $true
    }
    catch {
        Write-Warning ("Ошибка при удалении репозитория '$RepoPath' из индекса Git: {0}" -f $_)
        return $false
    }
}

function Add-ToGitIgnore {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $gitIgnorePath = ".gitignore"

    # Проверка наличия .gitignore
    if (-not (Test-Path $gitIgnorePath)) {
        "" | Out-File -FilePath $gitIgnorePath -Encoding utf8
    }

    # Проверка, что путь еще не добавлен в .gitignore
    $gitIgnoreContent = Get-Content $gitIgnorePath
    if (-not ($gitIgnoreContent -contains $Path)) {
        Write-Info "Добавление '$Path' в .gitignore..."
        Add-Content -Path $gitIgnorePath -Value $Path -Encoding utf8
        Write-Success "Путь '$Path' добавлен в .gitignore."
        return $true
    }
    else {
        Write-Info "Путь '$Path' уже присутствует в .gitignore."
        return $false
    }
}

function Add-GitSubmodule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        Write-Info "Добавление подмодуля для '$Path'..."
        git submodule add $Url $Path | Out-Null
        Write-Success "Подмодуль для '$Path' успешно добавлен."
        return $true
    }
    catch {
        Write-Warning ("Ошибка при добавлении подмодуля для '$Path': {0}" -f $_)
        return $false
    }
}

function Get-RepositoryUrl {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    try {
        Push-Location $RepoPath
        $remoteUrl = git config --get remote.origin.url
        Pop-Location
        return $remoteUrl
    }
    catch {
        return $null
    }
}

# Главная функция скрипта
function Repair-GitRepositories {
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

    # Поиск вложенных Git-репозиториев
    Write-Section "Поиск вложенных Git-репозиториев"
    $embeddedRepos = Get-EmbeddedGitRepositories

    if ($embeddedRepos.Count -eq 0) {
        Write-Success "Вложенных Git-репозиториев не найдено."
        return
    }

    Write-Info "Найдены следующие вложенные Git-репозитории:"
    $embeddedRepos | ForEach-Object { Write-Host "  - $_" }

    # Обработка вложенных репозиториев
    Write-Section "Обработка вложенных репозиториев"

    foreach ($repo in $embeddedRepos) {
        if ($ConvertToSubmodules) {
            # Получение URL репозитория
            $repoUrl = Get-RepositoryUrl -RepoPath $repo

            if (-not [string]::IsNullOrEmpty($repoUrl)) {
                # Удаление из индекса
                if (Remove-EmbeddedRepository -RepoPath $repo) {
                    # Добавление как подмодуль
                    Add-GitSubmodule -Path $repo -Url $repoUrl
                }
            }
            else {
                Write-Warning "Не удалось получить URL для репозитория '$repo'. Он будет добавлен в .gitignore."
                Remove-EmbeddedRepository -RepoPath $repo
                Add-ToGitIgnore -Path $repo
            }
        }
        elseif ($IgnoreOnly -or (-not $ConvertToSubmodules)) {
            # Удаление из индекса и добавление в .gitignore
            if (Remove-EmbeddedRepository -RepoPath $repo) {
                Add-ToGitIgnore -Path $repo
            }
        }
    }

    Write-Section "Завершение"

    if ($ConvertToSubmodules) {
        Write-Info "Вложенные репозитории были преобразованы в подмодули Git."
        Write-Info "Выполните коммит для сохранения изменений: git commit -m 'Конвертированы вложенные репозитории в подмодули'"
    }
    else {
        Write-Info "Вложенные репозитории были добавлены в .gitignore."
        Write-Info "Выполните коммит для сохранения изменений: git commit -m 'Игнорирование вложенных Git-репозиториев'"
    }
}

# Запуск главной функции
Repair-GitRepositories
