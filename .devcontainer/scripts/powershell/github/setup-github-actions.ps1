<#
.SYNOPSIS
    Настраивает GitHub Actions для репозитория проекта.

.DESCRIPTION
    Скрипт создает необходимые файлы конфигурации для GitHub Actions,
    включая рабочие процессы для автоматического тестирования, линтинга,
    форматирования кода и проверки безопасности. Также настраивает
    Dependabot и шаблоны для PR и Issues.

.EXAMPLE
    .\setup-github-actions.ps1

.NOTES
    Автор: GitHub Copilot
    Дата: 2023-07-25
    Требования: Git, PowerShell 5.0+
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

# Проверка установки Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "Git не установлен. Пожалуйста, установите Git и повторите попытку."
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

Write-Info "Настройка GitHub Actions в директории $projectRoot"

# Создание директории для GitHub workflows
New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null

# Создание рабочего процесса для оптимизации кода и проверки ошибок
Write-Info "Создание рабочего процесса оптимизации кода..."
@'
name: Code Quality & Optimization

on:
  push:
    branches: [ main, master, dev ]
  pull_request:
    branches: [ main, master, dev ]
  workflow_dispatch:  # Разрешить запуск вручную

jobs:
  optimize-backend:
    name: Backend Optimization
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r backend/requirements.txt
          pip install ruff black isort mypy

      - name: Run code optimization
        run: |
          # Format code with black
          black backend --exclude=venv

          # Sort imports
          isort backend --profile black

          # Fix auto-fixable issues with ruff
          ruff check backend --fix

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "🤖 Auto-optimize backend code"
          file_pattern: backend/**/*.py

  optimize-frontend:
    name: Frontend Optimization
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: 'frontend/package-lock.json'

      - name: Install dependencies
        run: |
          cd frontend
          npm ci

      - name: Run code optimization
        run: |
          cd frontend
          # Fix ESLint issues automatically where possible
          npm run lint -- --fix

          # Format code with Prettier
          npm run format

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "🤖 Auto-optimize frontend code"
          file_pattern: frontend/**/*.{js,jsx,ts,tsx,json,css,scss}

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
'@ | Out-File -FilePath ".github\workflows\code-quality.yml" -Encoding utf8

# Создание конфигурации для Dependabot
Write-Info "Создание конфигурации Dependabot..."
New-Item -ItemType Directory -Path ".github" -Force | Out-Null
@'
version: 2
updates:
  # Backend Python dependencies
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "python"
    commit-message:
      prefix: "📦"

  # Frontend NPM dependencies
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "javascript"
    commit-message:
      prefix: "📦"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
      - "github_actions"
    commit-message:
      prefix: "👷"
'@ | Out-File -FilePath ".github\dependabot.yml" -Encoding utf8

# Создание шаблона PR
Write-Info "Создание шаблона PR..."
New-Item -ItemType Directory -Path ".github\PULL_REQUEST_TEMPLATE" -Force | Out-Null
@'
## Описание
<!--- Опишите ваши изменения подробно -->

## Связанный Issue
<!--- Если исправляется баг, должен быть issue с описанием и шагами воспроизведения -->
<!--- Пожалуйста, укажите ссылку на issue здесь: -->

## Мотивация и Контекст
<!--- Почему эти изменения необходимы? Какую проблему они решают? -->

## Как это было протестировано?
<!--- Пожалуйста, опишите подробно, как вы тестировали свои изменения. -->
<!--- Включите детали вашей тестовой среды и тесты, которые вы запускали, -->
<!--- чтобы увидеть, как ваши изменения влияют на другие области кода и т. д. -->

## Скриншоты (если применимо):

## Типы изменений
<!--- Какие типы изменений вносит ваш код? Отметьте все подходящие варианты: -->
- [ ] Исправление бага (изменение, которое исправляет проблему)
- [ ] Новая функциональность (изменение, которое добавляет новую функцию)
- [ ] Критическое изменение (исправление или функция, которая приведет к изменению существующей функциональности)
- [ ] Обновление документации
- [ ] Улучшение производительности

## Чек-лист:
<!--- Просмотрите все следующие пункты и отметьте все подходящие. -->
<!--- Если вы не уверены в чем-то, не стесняйтесь спрашивать. Мы здесь, чтобы помочь! -->
- [ ] Мой код соответствует стилю этого проекта.
- [ ] Мое изменение требует изменения документации.
- [ ] Я обновил документацию соответствующим образом.
- [ ] Я добавил тесты для покрытия моих изменений.
- [ ] Все новые и существующие тесты пройдены успешно.
'@ | Out-File -FilePath ".github\PULL_REQUEST_TEMPLATE\default.md" -Encoding utf8

# Создание шаблонов Issue
Write-Info "Создание шаблонов Issue..."
New-Item -ItemType Directory -Path ".github\ISSUE_TEMPLATE" -Force | Out-Null
@'
---
name: Отчёт об ошибке
about: Создайте отчет, чтобы помочь нам улучшить проект
title: '[БАГ] '
labels: bug
assignees: ''
---

**Опишите ошибку**
Четкое и краткое описание того, что представляет собой ошибка.

**Шаги для воспроизведения**
Шаги для воспроизведения проблемы:
1. Перейдите к '...'
2. Нажмите на '....'
3. Прокрутите вниз до '....'
4. Увидите ошибку

**Ожидаемое поведение**
Четкое и краткое описание того, что вы ожидали.

**Скриншоты**
Если применимо, добавьте скриншоты, чтобы помочь объяснить вашу проблему.

**Окружение (пожалуйста, заполните следующую информацию):**
 - ОС: [например, Windows, macOS, Linux]
 - Браузер [например, Chrome, Safari]
 - Версия [например, 22]

**Дополнительный контекст**
Добавьте любой другой контекст о проблеме здесь.
'@ | Out-File -FilePath ".github\ISSUE_TEMPLATE\bug_report.md" -Encoding utf8

@'
---
name: Запрос функциональности
about: Предложите идею для этого проекта
title: '[ФУНКЦИОНАЛЬНОСТЬ] '
labels: enhancement
assignees: ''
---

**Связан ли ваш запрос функциональности с проблемой? Пожалуйста, опишите.**
Четкое и краткое описание проблемы. Например: Я всегда разочарован, когда [...]

**Опишите решение, которое вы хотели бы**
Четкое и краткое описание того, что вы хотите, чтобы произошло.

**Опишите альтернативы, которые вы рассматривали**
Четкое и краткое описание любых альтернативных решений или функций, которые вы рассматривали.

**Дополнительный контекст**
Добавьте любой другой контекст или скриншоты о запросе функциональности здесь.
'@ | Out-File -FilePath ".github\ISSUE_TEMPLATE\feature_request.md" -Encoding utf8

# Создание файла CODEOWNERS
Write-Info "Создание файла CODEOWNERS..."
@'
# Эти владельцы будут владельцами по умолчанию для всего в репозитории.
* @project-admin

# Код бэкенда
/backend/ @backend-team

# Код фронтенда
/frontend/ @frontend-team

# Инфраструктура и DevOps
/infra/ @devops-team
docker-compose.yml @devops-team
Dockerfile* @devops-team

# Документация
/docs/ @docs-team
*.md @docs-team
'@ | Out-File -FilePath ".github\CODEOWNERS" -Encoding utf8

# Добавление файлов в индекс Git
Write-Info "Добавление файлов в индекс Git..."
git add .github

# Коммит изменений, если они есть
try {
    git diff-index --quiet HEAD
    $changesExist = $LASTEXITCODE -ne 0

    if ($changesExist) {
        Write-Info "Создание коммита с изменениями..."
        git commit -m "Добавлены GitHub Actions рабочие процессы и шаблоны"
        Write-Success "Изменения закоммичены."
    } else {
        Write-Info "Нет изменений для коммита."
    }
}
catch {
    Write-Warning "Не удалось создать коммит: $_"
}

Write-Success "Настройка GitHub Actions завершена!"
Write-Info "Чтобы отправить эти изменения на GitHub, выполните: git push"
