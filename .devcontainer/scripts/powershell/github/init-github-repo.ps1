<#
.SYNOPSIS
    Инициализирует Git репозиторий и отправляет его на GitHub.

.DESCRIPTION
    Этот скрипт выполняет инициализацию Git репозитория, добавляет все файлы,
    создает первый коммит и отправляет его на GitHub. Скрипт позволяет
    указать имя репозитория на GitHub и его описание.

.PARAMETER RepoName
    Имя репозитория на GitHub. По умолчанию используется имя текущей директории.

.PARAMETER Description
    Описание репозитория. По умолчанию "HTXV2 project repository".

.PARAMETER BranchName
    Имя основной ветки. По умолчанию "main".

.PARAMETER CreatePrivateRepo
    Создать приватный репозиторий. По умолчанию False (публичный).

.EXAMPLE
    .\init-github-repo.ps1 -RepoName "my-awesome-project" -Description "Мой крутой проект на React и FastAPI" -CreatePrivateRepo $true
#>

param(
    [string]$RepoName = "",
    [string]$Description = "HTXV2 project repository",
    [string]$BranchName = "main",
    [bool]$CreatePrivateRepo = $false
)

function Test-CommandExists {
    param($Command)
    $exists = $false
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            $exists = $true
        }
    }
    catch {}
    return $exists
}

function Test-GitHubCliExists {
    $ghExists = Test-CommandExists "gh"
    if (-not $ghExists) {
        Write-Host "GitHub CLI не установлен. Установите его с помощью:" -ForegroundColor Red
        Write-Host "  winget install --id GitHub.cli" -ForegroundColor Yellow
        Write-Host "или посетите https://cli.github.com/ для инструкций по установке." -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Test-GitConfigured {
    $userEmail = git config --global --get user.email
    $userName = git config --global --get user.name

    if ([string]::IsNullOrEmpty($userEmail) -or [string]::IsNullOrEmpty($userName)) {
        Write-Host "Git не полностью настроен. Пожалуйста, установите имя пользователя и email:" -ForegroundColor Red

        if ([string]::IsNullOrEmpty($userName)) {
            $newUserName = Read-Host "Введите ваше имя для Git"
            git config --global user.name "$newUserName"
        }

        if ([string]::IsNullOrEmpty($userEmail)) {
            $newUserEmail = Read-Host "Введите ваш email для Git"
            git config --global user.email "$newUserEmail"
        }

        Write-Host "Git настроен!" -ForegroundColor Green
    }
    return $true
}

function Test-GitHubAuthenticated {
    $status = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Вы не авторизованы в GitHub CLI. Пожалуйста, авторизуйтесь:" -ForegroundColor Red
        gh auth login
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Не удалось авторизоваться в GitHub. Выход." -ForegroundColor Red
            return $false
        }
    }
    return $true
}

function Initialize-GitRepo {
    param(
        [string]$RepoName,
        [string]$Description,
        [string]$BranchName,
        [bool]$CreatePrivateRepo
    )

    # Проверка существования .git
    if (Test-Path ".git") {
        Write-Host "Git репозиторий уже инициализирован в этой директории." -ForegroundColor Yellow
        $reinitialize = Read-Host "Хотите переинициализировать его? (y/N)"
        if ($reinitialize -ne "y" -and $reinitialize -ne "Y") {
            return
        }
        Remove-Item -Path ".git" -Recurse -Force
    }

    # Инициализация Git
    Write-Host "Инициализация Git репозитория..." -ForegroundColor Cyan
    git init
    git branch -m $BranchName

    # Добавление .gitignore, если его нет
    if (-not (Test-Path ".gitignore")) {
        Write-Host "Создаем .gitignore файл..." -ForegroundColor Cyan
        @"
# Общие
.DS_Store
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Зависимости
/node_modules
/.pnp
.pnp.js

# Тесты
/coverage
.pytest_cache/
__pycache__/
*.py[cod]
*$py.class
htmlcov/
.coverage
.coverage.*

# Билды
/build
/dist
/.next/
/out/

# Кэш
.vercel
.eslintcache
.vscode/.ropeproject/
.idea/
.mypy_cache/
.ruff_cache/

# Логи
npm-debug.log*
yarn-debug.log*
yarn-error.log*
logs
*.log
"@ | Out-File -FilePath ".gitignore" -Encoding utf8
    }

    # Добавление всех файлов и первый коммит
    Write-Host "Добавление файлов и создание первого коммита..." -ForegroundColor Cyan
    git add .
    git commit -m "Initial commit"

    # Если имя репозитория не указано, используем имя текущей директории
    if ([string]::IsNullOrEmpty($RepoName)) {
        $currentDir = (Get-Item -Path ".\").Name
        $RepoName = $currentDir
    }

    # Создание репозитория на GitHub
    Write-Host "Создание репозитория $RepoName на GitHub..." -ForegroundColor Cyan

    $privateFlag = if ($CreatePrivateRepo) { "--private" } else { "--public" }

    gh repo create $RepoName --description "$Description" $privateFlag --source=. --remote=origin --push

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Репозиторий успешно создан и код отправлен на GitHub!" -ForegroundColor Green

        # Получаем URL репозитория
        $repoUrl = gh repo view --json url --jq .url
        Write-Host "URL репозитория: $repoUrl" -ForegroundColor Cyan
    }
    else {
        Write-Host "Произошла ошибка при создании репозитория на GitHub." -ForegroundColor Red
    }
}

# Основная логика скрипта
Write-Host "=== Инициализация и отправка на GitHub ===" -ForegroundColor Magenta

# Проверка требований
if (-not (Test-CommandExists "git")) {
    Write-Host "Git не установлен. Установите его и повторите попытку." -ForegroundColor Red
    exit 1
}

if (-not (Test-GitHubCliExists)) {
    exit 1
}

if (-not (Test-GitConfigured)) {
    exit 1
}

if (-not (Test-GitHubAuthenticated)) {
    exit 1
}

# Инициализация и отправка на GitHub
Initialize-GitRepo -RepoName $RepoName -Description $Description -BranchName $BranchName -CreatePrivateRepo $CreatePrivateRepo

Write-Host "Готово!" -ForegroundColor Green
