# Руководство по работе с GitHub

Это руководство описывает процедуры работы с GitHub в проекте HTXV2, включая инициализацию репозитория, настройку GitHub Actions и создание Pull Request'ов.

## Содержание

1. [Предварительные требования](#предварительные-требования)
2. [Настройка GitHub CLI](#настройка-github-cli)
3. [Инициализация репозитория](#инициализация-репозитория)
4. [Настройка GitHub Actions](#настройка-github-actions)
5. [Создание Pull Request](#создание-pull-request)
6. [Оптимизация кода](#оптимизация-кода)
7. [Использование VS Code Tasks](#использование-vs-code-tasks)
8. [Решение проблем](#решение-проблем)

## Предварительные требования

Для работы с GitHub в проекте вам потребуется:

1. Установленный [Git](https://git-scm.com/downloads)
2. Установленный [GitHub CLI](https://cli.github.com/) (gh)
3. Аккаунт на GitHub с доступом к проекту
4. Visual Studio Code с установленным расширением Git

## Настройка GitHub CLI

Перед началом работы необходимо настроить GitHub CLI:

```bash
# Авторизация в GitHub CLI
gh auth login

# Проверка авторизации
gh auth status
```

## Инициализация репозитория

### Для Windows (PowerShell)

```powershell
# Запустите скрипт инициализации репозитория
.\.devcontainer\scripts\powershell\github\init-repo.ps1 -Owner <имя-владельца> -Repo <имя-репозитория> -Description "Описание репозитория"
```

### Для Linux и MacOS

```bash
# Сделайте скрипты исполняемыми, если они еще не исполняемые
./.devcontainer/scripts/github/set-executable.sh ./.devcontainer/scripts/github -r

# Запустите скрипт инициализации репозитория
./.devcontainer/scripts/github/init-repo.sh <имя-владельца> <имя-репозитория> "Описание репозитория"
```

## Настройка GitHub Actions

### Инструкции для Windows

```powershell
# Настройка GitHub Actions
.\.devcontainer\scripts\powershell\github\setup-github-actions.ps1
```

### Инструкции для Linux и MacOS

```bash
# Настройка GitHub Actions
./.devcontainer/scripts/github/setup-github-actions.sh
```

Скрипт создаст директорию `.github/workflows` и добавит базовые workflow-файлы для CI/CD.

## Создание Pull Request

### Использование PowerShell

```powershell
# Создание ветки и Pull Request
.\.devcontainer\scripts\powershell\github\create-pr.ps1 -Branch "feature/новая-функция" -Base "main" -Title "Добавление новой функции" -Body "Подробное описание изменений"
```

### Использование Bash

```bash
# Создание ветки и Pull Request
./.devcontainer/scripts/github/create-pr.sh "feature/новая-функция" "main" "Добавление новой функции" "Подробное описание изменений"
```

## Оптимизация кода

### Для Windows

```powershell
# Запуск оптимизации кода
.\.devcontainer\scripts\powershell\github\optimize-code.ps1
```

### Для Unix-систем

```bash
# Запуск оптимизации кода
./.devcontainer/scripts/github/optimize-code.sh
```

Скрипт выполнит:

- Форматирование кода
- Проверку линтером
- Исправление простых ошибок
- Запуск тестов для проверки работоспособности

## Использование VS Code Tasks

В проекте настроены задачи VS Code для работы с GitHub. Для их использования:

1. Откройте палитру команд с помощью `Ctrl+Shift+P` (Windows/Linux) или `Cmd+Shift+P` (MacOS)
2. Введите `Tasks: Run Task`
3. Выберите одну из задач GitHub:
   - `GitHub: Initialize Repository`
   - `GitHub: Setup GitHub Actions`
   - `GitHub: Create Pull Request`
   - `GitHub: Optimize Code`
   - `GitHub: Test GitHub Actions`
   - `GitHub: Check Repository Status`
   - `GitHub: Update Repository`

## Решение проблем

### Проблемы с авторизацией

Если возникают ошибки авторизации:

```bash
# Переавторизация в GitHub CLI
gh auth logout
gh auth login
```

### Проблемы с GitHub Actions

Для проверки корректности workflow-файлов:

```bash
# Windows
.\.devcontainer\scripts\powershell\github\test-github-actions.ps1

# Linux/MacOS
./.devcontainer/scripts/github/test-github-actions.sh
```

### Настройка разрешений для скриптов

Если у вас возникают проблемы с запуском скриптов из-за отсутствия разрешений:

```bash
# Windows (PowerShell)
.\.devcontainer\scripts\powershell\set-executable.ps1 -Directory ".devcontainer\scripts\github" -Recursive

# Linux/MacOS
chmod +x ./.devcontainer/scripts/github/*.sh
```

---

Для получения более подробной информации о CI/CD процессах, обратитесь к документации в файле [ci-cd-guide.md](ci-cd-guide.md).
