# Процесс релиза и деплоя HTXEnterface_v2

## Обзор процесса

Данный документ описывает полный процесс подготовки релиза и деплоя приложения HTXEnterface_v2 на локальной машине. Процесс разделен на несколько этапов, каждый из которых должен быть успешно завершен перед переходом к следующему.

## 1. Подготовка к релизу

### 1.1. Анализ готовности функциональности

1. Проверка завершенности всех задач в текущем спринте/милестоуне
2. Убедиться, что все запланированные функции реализованы и протестированы
3. Проверка, что все известные ошибки исправлены или задокументированы как известные ограничения

### 1.2. Подготовка документации

1. Обновление документации API (при необходимости)
2. Обновление руководства пользователя
3. Составление списка изменений (changelog)
4. Проверка актуальности README и других документов проекта

### 1.3. Создание релизной ветки

```bash
# Перейти на ветку dev и получить последние изменения
git checkout dev
git pull origin dev

# Создать релизную ветку
git checkout -b release/vX.Y.Z

# Отправить ветку в удаленный репозиторий
git push -u origin release/vX.Y.Z
```

## 2. Финальное тестирование

### 2.1. Запуск комплексного тестирования

1. Запуск всех автоматических тестов:

```bash
# Тесты бэкенда
cd backend
pytest

# Тесты фронтенда
cd frontend
npm test

# Интеграционные тесты
npm run test:integration
```

2. Мануальное тестирование критических путей:
   - Процесс авторизации и управления пользователями
   - Основные функции приложения
   - Интеграция с внешними сервисами

### 2.2. Тестирование производительности

1. Запуск нагрузочных тестов:

```bash
cd tests/performance
python load_test.py --users 100 --duration 300
```

2. Анализ результатов и устранение узких мест (если обнаружены)

### 2.3. Аудит безопасности

1. Проверка зависимостей на наличие уязвимостей:

```bash
# Проверка npm зависимостей
npm audit

# Проверка Python зависимостей
safety check -r backend/requirements.txt
```

2. Проверка безопасности API-точек и аутентификации

## 3. Сборка релизных артефактов

### 3.1. Обновление версии

1. Обновление версии в файлах проекта:

```bash
# Обновление версии в package.json
sed -i 's/"version": ".*"/"version": "X.Y.Z"/g' package.json

# Обновление версии в backend/__init__.py
sed -i 's/__version__ = ".*"/__version__ = "X.Y.Z"/g' backend/app/__init__.py
```

2. Коммит изменений версии:

```bash
git add package.json backend/app/__init__.py
git commit -m "Bump version to X.Y.Z"
```

### 3.2. Сборка фронтенда

```bash
cd frontend
npm ci
npm run build
```

### 3.3. Сборка бэкенда

```bash
cd backend
pip install -r requirements.txt
python -m build
```

### 3.4. Сборка Docker образов

```bash
# Сборка всех образов
docker compose -f docker-compose.build.yml build

# Тегирование образов версией
docker tag htx-interface-app:latest htx-interface-app:vX.Y.Z
docker tag htx-fingpt:latest htx-fingpt:vX.Y.Z
```

## 4. Финализация релиза

### 4.1. Слияние в основную ветку

1. Создание Pull Request из релизной ветки в main
2. Code review и финальное утверждение
3. Слияние в main:

```bash
git checkout main
git pull origin main
git merge release/vX.Y.Z
git push origin main
```

### 4.2. Создание тега релиза

```bash
# Создание аннотированного тега
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin vX.Y.Z
```

### 4.3. Создание релиза в GitHub

1. Перейдите на страницу релизов в GitHub
2. Создайте новый релиз на основе тега vX.Y.Z
3. Добавьте описание изменений и загрузите артефакты (если необходимо)

## 5. Деплой на локальную машину

### 5.1. Подготовка локальной среды

1. Создание необходимых директорий:

```bash
# Создание директорий для данных и логов
mkdir -p ~/htx/data
mkdir -p ~/htx/logs
mkdir -p ~/htx/config
```

2. Настройка переменных окружения:

```bash
# Создание файла .env
cat > ~/htx/config/.env << EOL
ENV=production
DB_HOST=localhost
DB_PORT=5432
DB_USER=htx_user
DB_PASSWORD=your_secure_password
SECRET_KEY=$(openssl rand -hex 32)
EOL
```

### 5.2. Настройка базы данных

1. Запуск базы данных:

```bash
docker run --name htx-postgres -e POSTGRES_USER=htx_user \
  -e POSTGRES_PASSWORD=your_secure_password \
  -e POSTGRES_DB=htx \
  -v ~/htx/data/postgres:/var/lib/postgresql/data \
  -p 5432:5432 -d postgres:13
```

2. Инициализация схемы БД:

```bash
docker run --rm --network=host \
  -v ~/htx/config:/config \
  htx-interface-app:latest \
  alembic upgrade head
```

### 5.3. Запуск приложения

1. Запуск всех сервисов:

```bash
docker compose -f docker-compose.local.yml up -d
```

2. Проверка статуса:

```bash
docker compose -f docker-compose.local.yml ps
```

### 5.4. Проверка работоспособности

1. Проверка доступности API:

```bash
curl http://localhost:8000/api/v1/health
```

2. Проверка доступности фронтенда через браузер: http://localhost:3000

## 6. Мониторинг и поддержка

### 6.1. Настройка мониторинга

1. Настройка логирования:

```bash
# Проверка логов приложения
docker compose -f docker-compose.local.yml logs -f app

# Проверка логов FinGPT
docker compose -f docker-compose.local.yml logs -f fingpt
```

2. Настройка алертов (опционально):

```bash
# Установка Prometheus и Grafana для мониторинга
docker compose -f docker-compose.monitoring.yml up -d
```

### 6.2. Резервное копирование данных

```bash
# Скрипт резервного копирования
cat > ~/htx/scripts/backup.sh << EOL
#!/bin/bash
TIMESTAMP=\$(date +%Y%m%d%H%M%S)
mkdir -p ~/htx/backups
docker exec htx-postgres pg_dump -U htx_user htx > ~/htx/backups/htx_db_\$TIMESTAMP.sql
tar -czf ~/htx/backups/htx_data_\$TIMESTAMP.tar.gz ~/htx/data
EOL
chmod +x ~/htx/scripts/backup.sh
```

### 6.3. Процедура отката

В случае обнаружения критических проблем после деплоя:

```bash
# Остановка текущей версии
docker compose -f docker-compose.local.yml down

# Возврат к предыдущей версии
docker tag htx-interface-app:previous htx-interface-app:latest
docker tag htx-fingpt:previous htx-fingpt:latest

# Запуск предыдущей версии
docker compose -f docker-compose.local.yml up -d
```

## 7. Проверка релиза после деплоя

### 7.1. Валидация релиза

1. Проверка основной функциональности через пользовательский интерфейс
2. Подтверждение исправления ошибок, включенных в данный релиз
3. Проверка производительности в реальных условиях

### 7.2. Сбор обратной связи

1. Документирование возникающих проблем
2. Планирование исправлений для следующего релиза (если необходимо)

### 7.3. Формальное закрытие релиза

1. Обновление статуса задач в системе отслеживания
2. Проведение ретроспективы релиза для улучшения процесса

## Приложение A: Контрольный список релиза

### Перед релизом

- [ ] Все запланированные функции реализованы
- [ ] Все автоматические тесты проходят успешно
- [ ] Документация обновлена
- [ ] Версии в файлах проекта обновлены
- [ ] Changelog составлен

### Во время релиза

- [ ] Релизная ветка создана
- [ ] Все релизные артефакты успешно собраны
- [ ] Docker образы созданы и правильно тегированы
- [ ] PR в main ветку создан и одобрен
- [ ] Тег релиза создан и отправлен в репозиторий

### После релиза

- [ ] Приложение успешно развернуто
- [ ] Базовые проверки работоспособности пройдены
- [ ] Система мониторинга настроена
- [ ] Процедуры резервного копирования и отката проверены
