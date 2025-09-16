# Настройка GitHub для проекта HTXEnterface_v2

В этом документе описаны шаги и скрипты для настройки GitHub репозитория и автоматизации для проекта HTXEnterface_v2.

## Содержание

1. [Подготовка к работе с GitHub](#подготовка-к-работе-с-github)
2. [Инициализация репозитория](#инициализация-репозитория)
3. [Настройка GitHub Actions](#настройка-github-actions)
4. [Автоматизация PR и проверки кода](#автоматизация-pr-и-проверки-кода)
5. [Локальное тестирование GitHub Actions](#локальное-тестирование-github-actions)
6. [Оптимизация кода](#оптимизация-кода)

## Подготовка к работе с GitHub

### Требования

Для работы со скриптами необходимо установить:

- [Git](https://git-scm.com/downloads)
- [GitHub CLI](https://cli.github.com/) (gh)
- [act](https://github.com/nektos/act) (для локального тестирования GitHub Actions)

### Аутентификация

Перед использованием скриптов необходимо авторизоваться в GitHub CLI:

```bash
gh auth login
```

## Инициализация репозитория

### Использование PowerShell

Для инициализации репозитория в PowerShell используйте скрипт:

```powershell
.\.devcontainer\scripts\powershell\github\init-github-repo.ps1 -RepoName "HTXEnterface_v2" -Description "Проект HTXEnterface версии 2" -CreatePrivateRepo $true
```

Параметры:

- `-RepoName`: Имя репозитория (по умолчанию: имя текущей директории)
- `-Description`: Описание репозитория (по умолчанию: "HTXV2 project repository")
- `-BranchName`: Имя основной ветки (по умолчанию: "main")
- `-CreatePrivateRepo`: Создать приватный репозиторий (по умолчанию: $false)

### Использование Bash

Для Linux/MacOS используйте bash скрипт:

```bash
./.devcontainer/scripts/github/init-github-repo.sh HTXEnterface_v2 true
```

Параметры:

- Первый аргумент: Имя репозитория (по умолчанию: "HTXEnterface_v2")
- Второй аргумент: Приватный репозиторий (true/false, по умолчанию: true)

## Настройка GitHub Actions

### Настройка через PowerShell

Для настройки GitHub Actions в PowerShell:

```powershell
.\.devcontainer\scripts\powershell\github\setup-github-actions.ps1
```

### Настройка через Bash

Для Linux/MacOS:

```bash
./.devcontainer/scripts/github/setup-github-actions.sh
```

Эти скрипты создают:

- Рабочие процессы для автоматической оптимизации кода
- Проверки безопасности
- Шаблоны PR и Issues
- Настройку Dependabot для автоматического обновления зависимостей

## Автоматизация PR и проверки кода

### Автоматическое создание PR

#### Создание PR через PowerShell

```powershell
.\.devcontainer\scripts\powershell\github\auto-pr.ps1 -Title "Название PR" -Branch "feature/my-feature"
```

Параметры:

- `-Title`: Название PR (если не указано, используется последний коммит)
- `-Branch`: Ветка для PR (если не указана, используется текущая ветка)

#### Создание PR через Bash

```bash
./.devcontainer/scripts/github/auto-pr.sh --title "Название PR" --branch "feature/my-feature"
```

### Оптимизация кода

#### Оптимизация через PowerShell

```powershell
.\.devcontainer\scripts\powershell\github\optimize-code.ps1 -Target All
```

Параметры:

- `-Target`: "Backend", "Frontend" или "All"

#### Оптимизация через Bash

```bash
./.devcontainer/scripts/github/optimize-code.sh --all
```

Параметры:

- `--backend`: только бэкенд
- `--frontend`: только фронтенд
- `--all`: все части проекта

## Локальное тестирование GitHub Actions

Для локального тестирования GitHub Actions используйте инструмент [act](https://github.com/nektos/act).

### Тестирование через PowerShell

```powershell
.\.devcontainer\scripts\powershell\github\github-actions-test.ps1
```

### Тестирование через Bash

```bash
./.devcontainer/scripts/github/github-actions-test.sh
```

Эти скрипты позволяют выбрать конкретный workflow и событие для его локального тестирования.

## Статус проекта

Настроен автоматический отправитель отчетов о состоянии проекта по email через GitHub Actions.
Отчет содержит информацию о:

- Недавних коммитах
- Открытых issues и PR
- Статусе тестирования
- Метриках качества кода

Расписание отправки: ежедневно в полночь по UTC.

## Дополнительная информация

Все скрипты содержат подробные комментарии и справку, которую можно просмотреть стандартными
средствами PowerShell или с помощью команды `--help` для bash скриптов.
