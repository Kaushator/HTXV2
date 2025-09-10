# Управление Артефактами GitHub Actions

Руководство по работе с артефактами в CI/CD pipeline HTX Interface.

## Обзор Артефактов

Артефакты - это файлы, созданные во время выполнения workflow, которые сохраняются для последующего анализа. В нашем проекте мы создаем артефакты для:

- **Логов тестирования** - детальные логи pytest, Vitest, TypeScript
- **Логов линтеров** - результаты проверки кода
- **Отчетов о деплое** - информация о развернутых сервисах
- **Сводок ошибок** - агрегированная информация о проблемах

## Типы Артефактов

### 1. Backend Errors (`backend-errors`)

**Содержимое:**
```
backend-errors/
├── pytest.log          # Детальные логи pytest
├── lint.log            # Результаты ruff линтера
└── coverage.json       # Coverage отчет (если доступен)
```

**Когда создается:** После выполнения backend тестов (всегда, даже при ошибках)

**Пример содержимого pytest.log:**
```
============================= test session starts ==============================
platform linux -- Python 3.11.0, pytest-7.4.0, pluggy-1.0.0
rootdir: /home/runner/work/HTXEnterface_v2/HTXEnterface_v2/backend
plugins: anyio-3.7.1, asyncio-0.21.1
collected 15 items

tests/test_health.py::test_health_endpoint PASSED                        [  6%]
tests/test_market.py::test_get_markets PASSED                           [ 13%]
tests/test_market.py::test_get_market_symbols PASSED                    [ 20%]
...
```

### 2. Frontend Errors (`frontend-errors`)

**Содержимое:**
```
frontend-errors/
├── vitest.log          # Логи Vitest тестов
├── typecheck.log       # Результаты TypeScript проверки
├── lint.log            # ESLint результаты
└── build.log           # Логи сборки (если есть ошибки)
```

**Пример содержимого vitest.log:**
```
 RUN  v0.34.0 /home/runner/work/HTXEnterface_v2/HTXEnterface_v2/frontend

 ✓ src/hooks/useWebSocket.test.ts (8)
   ✓ should connect to WebSocket
   ✓ should handle reconnection
   ✓ should clean up on unmount
   ...

 ✓ src/components/TickerCard.test.tsx (2)
   ✓ should render ticker card
   ✓ should handle price changes

 Test Files  2 passed (2)
      Tests  10 passed (10)
```

### 3. Deployment Report (`deployment-report`)

**Содержимое:**
```
deployment-report/
└── deployment-report.md    # Markdown отчет с URLs и статусами
```

**Пример содержимого:**
```markdown
# Deployment Report

## Backend
Backend URL: https://htx-interface-backend-xxx.run.app
Status: ✅ Healthy

## Frontend  
Frontend URL: https://htx-interface-frontend-xxx.run.app
Status: ✅ Healthy

## FinGPT
FinGPT URL: https://htx-interface-fingpt-xxx.run.app
Status: ✅ Healthy

## Deployment Time
Started: 2024-01-15 10:30:00 UTC
Completed: 2024-01-15 10:35:30 UTC
Duration: 5 minutes 30 seconds
```

### 4. Error Summary (`error-summary`)

**Содержимое:**
```
error-summary/
└── error-summary.md        # Агрегированный отчет об ошибках
```

**Пример содержимого:**
```markdown
# CI/CD Execution Report

## Обзор выполнения CI/CD
Дата выполнения: Mon Jan 15 10:35:00 UTC 2024

## Ошибки и предупреждения Backend
### Логи тестов Backend
```
FAILED tests/test_market.py::test_invalid_market - AssertionError: Expected 404, got 500
```

### Предупреждения линтера Backend
```
backend/app/main.py:45:80: E501 line too long (85 > 79 characters)
backend/app/routers/market.py:12:1: F401 'unused_import' imported but unused
```

## Статус сервисов
- Backend: ✅ Deployed successfully
- Frontend: ⚠️  Deployed with warnings
- FinGPT: ❌ Deployment failed
```

## Скачивание и Анализ Артефактов

### Через GitHub Web Interface

1. **Перейдите к workflow run:**
   - Repository → Actions → выберите нужный workflow run

2. **Найдите секцию Artifacts:**
   - Прокрутите вниз до конца страницы
   - Увидите список доступных артефактов

3. **Скачайте артефакт:**
   - Кликните на имя артефакта для скачивания ZIP файла

### Через GitHub CLI

```bash
# Установка GitHub CLI (если не установлен)
# macOS: brew install gh
# Windows: winget install GitHub.cli
# Linux: https://github.com/cli/cli/releases

# Аутентификация
gh auth login

# Список последних workflow runs
gh run list --limit 10

# Просмотр деталей конкретного run
gh run view [RUN_ID]

# Скачивание всех артефактов
gh run download [RUN_ID]

# Скачивание конкретного артефакта
gh run download [RUN_ID] --name backend-errors

# Скачивание в конкретную директорию
gh run download [RUN_ID] --dir ./artifacts/
```

### Через REST API

```bash
# Получить список workflow runs
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/runs

# Получить артефакты для конкретного run
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/runs/RUN_ID/artifacts

# Скачать артефакт
curl -L -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/artifacts/ARTIFACT_ID/zip \
  -o artifact.zip
```

## Автоматизация Анализа Артефактов

### Скрипт для анализа тестов

```bash
#!/bin/bash
# analyze-artifacts.sh

RUN_ID=$1
if [ -z "$RUN_ID" ]; then
    echo "Usage: $0 <RUN_ID>"
    echo "Get RUN_ID from: gh run list"
    exit 1
fi

# Создаем временную директорию
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "📁 Downloading artifacts for run $RUN_ID..."
gh run download "$RUN_ID"

echo "🔍 Analyzing artifacts..."

# Анализ backend ошибок
if [ -d "backend-errors" ]; then
    echo "## Backend Analysis"
    echo "### Test Results:"
    if [ -f "backend-errors/pytest.log" ]; then
        grep -E "(FAILED|ERROR)" backend-errors/pytest.log || echo "No test failures found"
    fi
    
    echo "### Lint Issues:"
    if [ -f "backend-errors/lint.log" ]; then
        wc -l backend-errors/lint.log | awk '{print $1 " lint issues found"}'
    fi
fi

# Анализ frontend ошибок
if [ -d "frontend-errors" ]; then
    echo "## Frontend Analysis"
    echo "### Test Results:"
    if [ -f "frontend-errors/vitest.log" ]; then
        grep -E "(FAIL|✗)" frontend-errors/vitest.log || echo "No test failures found"
    fi
    
    echo "### TypeScript Issues:"
    if [ -f "frontend-errors/typecheck.log" ]; then
        grep -c "error TS" frontend-errors/typecheck.log | awk '{print $1 " TypeScript errors found"}'
    fi
fi

# Анализ деплоя
if [ -d "deployment-report" ] && [ -f "deployment-report/deployment-report.md" ]; then
    echo "## Deployment Status"
    cat deployment-report/deployment-report.md
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"
```

### PowerShell скрипт для Windows

```powershell
# analyze-artifacts.ps1
param(
    [Parameter(Mandatory)]
    [string]$RunId
)

$TempDir = Join-Path $env:TEMP "artifacts-$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    Set-Location $TempDir
    
    Write-Host "📁 Downloading artifacts for run $RunId..." -ForegroundColor Blue
    gh run download $RunId
    
    Write-Host "🔍 Analyzing artifacts..." -ForegroundColor Blue
    
    # Backend анализ
    $backendDir = "backend-errors"
    if (Test-Path $backendDir) {
        Write-Host "## Backend Analysis" -ForegroundColor Green
        
        $pytestLog = Join-Path $backendDir "pytest.log"
        if (Test-Path $pytestLog) {
            Write-Host "### Test Results:" -ForegroundColor Yellow
            $failures = Select-String -Path $pytestLog -Pattern "(FAILED|ERROR)"
            if ($failures) {
                $failures | ForEach-Object { Write-Host $_.Line }
            } else {
                Write-Host "No test failures found" -ForegroundColor Green
            }
        }
        
        $lintLog = Join-Path $backendDir "lint.log"
        if (Test-Path $lintLog) {
            Write-Host "### Lint Issues:" -ForegroundColor Yellow
            $lineCount = (Get-Content $lintLog).Count
            Write-Host "$lineCount lint issues found"
        }
    }
    
    # Frontend анализ
    $frontendDir = "frontend-errors"
    if (Test-Path $frontendDir) {
        Write-Host "## Frontend Analysis" -ForegroundColor Green
        
        $vitestLog = Join-Path $frontendDir "vitest.log"
        if (Test-Path $vitestLog) {
            Write-Host "### Test Results:" -ForegroundColor Yellow
            $failures = Select-String -Path $vitestLog -Pattern "(FAIL|✗)"
            if ($failures) {
                $failures | ForEach-Object { Write-Host $_.Line }
            } else {
                Write-Host "No test failures found" -ForegroundColor Green
            }
        }
    }
    
    # Deployment анализ
    $deployReport = "deployment-report/deployment-report.md"
    if (Test-Path $deployReport) {
        Write-Host "## Deployment Status" -ForegroundColor Green
        Get-Content $deployReport | Write-Host
    }
}
finally {
    Set-Location -
    Remove-Item -Recurse -Force $TempDir
}
```

## Управление Хранением Артефактов

### Настройка Retention (Срок хранения)

По умолчанию GitHub хранит артефакты 90 дней. Можно настроить индивидуально:

```yaml
- name: Upload logs
  uses: actions/upload-artifact@v4
  with:
    name: test-logs
    path: logs/
    retention-days: 30  # Хранить 30 дней
```

### Очистка старых артефактов

```bash
#!/bin/bash
# cleanup-artifacts.sh

# Получить все старые runs (старше 30 дней)
CUTOFF_DATE=$(date -d '30 days ago' --iso-8601)

gh api repos/:owner/:repo/actions/runs \
  --paginate \
  --jq ".workflow_runs[] | select(.created_at < \"$CUTOFF_DATE\") | .id" \
  | while read -r run_id; do
    echo "Deleting artifacts for run $run_id"
    gh api repos/:owner/:repo/actions/runs/$run_id/artifacts \
      --jq '.artifacts[].id' \
      | while read -r artifact_id; do
        gh api -X DELETE repos/:owner/:repo/actions/artifacts/$artifact_id
      done
  done
```

## Интеграция с Внешними Системами

### Отправка артефактов в S3

```yaml
- name: Upload to S3
  if: always()
  run: |
    aws s3 cp deployment-report.md s3://my-bucket/reports/$(date +%Y-%m-%d)/${{ github.run_id }}/
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Отправка в Slack при ошибках

```yaml
- name: Download error summary
  if: failure()
  uses: actions/download-artifact@v4
  with:
    name: error-summary
    path: ./errors

- name: Send to Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    text: |
      CI/CD failed for ${{ github.ref }}
      Error summary: $(cat ./errors/error-summary.md | head -20)
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Мониторинг и Алерты

### Dashboard для мониторинга артефактов

```python
# monitor_artifacts.py
import requests
import json
from datetime import datetime, timedelta

def check_artifact_freshness(repo, token):
    """Проверить свежесть артефактов"""
    headers = {'Authorization': f'token {token}'}
    
    # Получить последние runs
    url = f'https://api.github.com/repos/{repo}/actions/runs'
    response = requests.get(url, headers=headers)
    runs = response.json()['workflow_runs']
    
    for run in runs[:5]:  # Последние 5 runs
        run_id = run['id']
        created_at = datetime.fromisoformat(run['created_at'].replace('Z', '+00:00'))
        
        # Получить артефакты для run
        artifacts_url = f'https://api.github.com/repos/{repo}/actions/runs/{run_id}/artifacts'
        artifacts_response = requests.get(artifacts_url, headers=headers)
        artifacts = artifacts_response.json()['artifacts']
        
        print(f"Run {run_id} ({created_at.strftime('%Y-%m-%d %H:%M')}): {len(artifacts)} artifacts")
        
        for artifact in artifacts:
            size_mb = artifact['size_in_bytes'] / 1024 / 1024
            print(f"  - {artifact['name']}: {size_mb:.1f}MB")

if __name__ == '__main__':
    check_artifact_freshness('owner/repo', 'your_token')
```

### Автоматические уведомления

```yaml
# .github/workflows/artifact-monitor.yml
name: Artifact Monitor

on:
  schedule:
    - cron: '0 9 * * MON'  # Каждый понедельник в 9:00

jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
      - name: Check artifact usage
        run: |
          TOTAL_SIZE=$(gh api repos/:owner/:repo/actions/artifacts --paginate --jq '[.artifacts[].size_in_bytes] | add')
          TOTAL_SIZE_MB=$((TOTAL_SIZE / 1024 / 1024))
          
          echo "Total artifacts size: ${TOTAL_SIZE_MB}MB"
          
          if [ $TOTAL_SIZE_MB -gt 1000 ]; then
            echo "::warning::Artifacts size exceeds 1GB, consider cleanup"
          fi
```

## Лучшие практики

### 1. Структурирование артефактов

```yaml
# ✅ Хорошо - четкая структура
- name: Upload backend logs
  uses: actions/upload-artifact@v4
  with:
    name: backend-errors-${{ github.run_id }}
    path: |
      backend/logs/
      backend/coverage/
    if-no-files-found: error

# ❌ Плохо - неясная структура
- name: Upload stuff
  uses: actions/upload-artifact@v4
  with:
    name: files
    path: .
```

### 2. Условная загрузка

```yaml
# Загружать только при ошибках
- name: Upload logs on failure
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: failure-logs
    path: logs/

# Загружать только критические артефакты
- name: Upload critical reports
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: reports
    path: reports/critical/
```

### 3. Именование и версионирование

```yaml
# Включать контекст в имя
- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ matrix.os }}-${{ matrix.node-version }}
    path: test-results/

# Включать timestamp для уникальности
- name: Upload deployment report
  uses: actions/upload-artifact@v4
  with:
    name: deploy-report-$(date +%Y%m%d-%H%M%S)
    path: deployment-report.md
```

### 4. Размер и производительность

```yaml
# Сжимать большие файлы
- name: Compress logs
  run: |
    tar -czf logs.tar.gz logs/
    
- name: Upload compressed logs
  uses: actions/upload-artifact@v4
  with:
    name: compressed-logs
    path: logs.tar.gz

# Исключать ненужные файлы
- name: Upload source without node_modules
  uses: actions/upload-artifact@v4
  with:
    name: source-code
    path: |
      src/
      !src/node_modules/
      !src/**/*.tmp
```

---

Эта документация поможет эффективно работать с артефактами GitHub Actions и быстро диагностировать проблемы в CI/CD pipeline.
