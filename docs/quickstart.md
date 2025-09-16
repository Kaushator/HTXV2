# Быстрый старт HTXV2

## Введение

Этот документ описывает краткие шаги по инициализации и запуску проекта HTXV2. Для более подробной информации обратитесь к полной документации в директории `docs/`.

## Предварительные требования

1. **Docker и Docker Compose**

   - Установите [Docker Desktop](https://www.docker.com/products/docker-desktop/) для вашей ОС.
   - Убедитесь, что Docker Engine и Docker Compose установлены и работают.

2. **VS Code (опционально, но рекомендуется)**

   - Установите [Visual Studio Code](https://code.visualstudio.com/).
   - Установите расширение [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

3. **PowerShell 7+ (опционально)**
   - Для Windows и других ОС рекомендуется установить [PowerShell 7+](https://github.com/PowerShell/PowerShell).

## Шаги инициализации

### Вариант 1: Использование VS Code и Dev-контейнера (рекомендуется)

1. **Клонирование репозитория**:

   ```bash
   git clone <URL_репозитория> htxv2
   cd htxv2
   ```

2. **Открытие проекта в VS Code**:

   ```bash
   code .
   ```

3. **Запуск в Dev-контейнере**:

   - Нажмите F1 и введите "Remote-Containers: Reopen in Container"
   - VS Code перезапустится и автоматически настроит среду разработки

4. **Инициализация проекта**:

   - После запуска контейнера скрипт инициализации запустится автоматически
   - Или выполните вручную:

     ```bash
     # Для Linux/macOS
     .devcontainer/scripts/init-dev-container.sh

     # Для PowerShell
     .\.devcontainer\scripts\powershell\init-dev-container.ps1
     ```

### Вариант 2: Ручная настройка с Docker

1. **Клонирование репозитория**:

   ```bash
   git clone <URL_репозитория> htxv2
   cd htxv2
   ```

2. **Запуск контейнеров**:

   ```bash
   docker compose up -d
   ```

3. **Проверка баз данных**:

   ```bash
   # Для Linux/macOS
   ./.devcontainer/scripts/check-databases.sh

   # Для PowerShell
   .\.devcontainer\scripts\powershell\check-databases.ps1
   ```

## Проверка работоспособности

После инициализации проверьте доступность сервисов:

1. **Frontend**: http://localhost:3000
2. **Backend API**: http://localhost:8000
3. **FinGPT**: http://localhost:5000

## Полезные команды

```bash
# Проверка состояния контейнеров
docker ps

# Просмотр логов контейнеров
docker logs htxenterface_v2-backend-1

# Остановка всех контейнеров
docker compose down

# Перезапуск конкретного контейнера
docker restart htxenterface_v2-backend-1
```

## Утилитные скрипты

В проекте доступны следующие утилитные скрипты:

- **test-htx**: Тестирование контейнеров
- **update-htx**: Обновление контейнеров
- **backup-htx**: Создание резервных копий данных

Для выполнения в терминале:

```bash
# В Linux/macOS
bash -c "$(pwd)/.devcontainer/scripts/powershell/test-containers.ps1"

# В PowerShell
.\devcontainer\scripts\powershell\test-containers.ps1
```

## Документация

Для получения дополнительной информации обратитесь к следующим документам:

- [Полное руководство по инициализации dev-контейнера](./devcontainer-init.md)
- [Руководство по управлению Docker](./docker-management.md)
- [Руководство для ИИ-помощников](./ai-assistant-guide.md)

## Решение проблем

В случае проблем:

1. Убедитесь, что все контейнеры запущены: `docker ps`
2. Проверьте логи контейнеров: `docker logs <имя_контейнера>`
3. Убедитесь, что база данных `htx` создана
4. Перезапустите контейнеры: `docker compose restart`
