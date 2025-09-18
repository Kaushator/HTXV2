# 🚀 HTXV2 ML Development Environment

Полнофункциональная среда разработки для ML/AI проекта HTXV2 с поддержкой MCP Tools, оптимизированная для экономии токенов.

## 🎯 Особенности

- **ML/AI стек**: PyTorch, TensorFlow, Transformers, MLflow
- **MCP Tools**: Интеграция с GitHub Copilot Chat
- **JupyterLab**: Интерактивная разработка ML моделей
- **Docker**: Полная контейнеризация с оптимизацией
- **Terraform**: Инфраструктура как код
- **Экономия токенов**: ~60% экономии через оптимизацию

## 🛠️ Установленные инструменты

### DevOps инструменты
- `hadolint` - линтер для Dockerfile
- `dive` - анализ Docker образов
- `trivy` - сканер безопасности
- `docker-slim` - оптимизация образов
- `docker-compose` - оркестрация контейнеров
- `terraform` - инфраструктура как код
- `pre-commit` - хуки для Git

### ML/AI стек
- **PyTorch** + **TensorFlow** + **Transformers**
- **MLflow** + **Weights & Biases** для экспериментов
- **JupyterLab** с расширениями
- **OpenCV** + **Pillow** для компьютерного зрения
- **spaCy** + **NLTK** для NLP

## 🚀 Быстрый старт

### 1. Открытие в DevContainer

```bash
# Клонирование репозитория
git clone https://github.com/Kaushator/HTXV2.git
cd HTXV2

# Открытие в VS Code
code .
```

В VS Code:
1. Нажмите `F1` → `Remote-Containers: Reopen in Container`
2. Дождитесь сборки контейнера
3. Все инструменты установятся автоматически

### 2. Запуск сервисов

```bash
# Запуск всех сервисов
docker compose up -d

# Проверка статуса
docker compose ps

# Просмотр логов
docker compose logs -f
```

### 3. Доступ к сервисам

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **JupyterLab**: http://localhost:8888/lab?token=htxv2-dev
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 🔧 Использование инструментов

### Hadolint - анализ Dockerfile

```bash
# Анализ Dockerfile
hadolint .devcontainer/Dockerfile

# Анализ всех Dockerfile в проекте
find . -name "Dockerfile*" -exec hadolint {} \;
```

### Dive - анализ Docker образов

```bash
# Анализ образа
dive htxv2-ml:latest

# Анализ с детализацией
dive --ci htxv2-ml:latest
```

### Trivy - сканирование безопасности

```bash
# Сканирование образа
trivy image htxv2-ml:latest

# Сканирование с отчетом
trivy image --format json --output report.json htxv2-ml:latest
```

### Docker Slim - оптимизация образов

```bash
# Анализ и оптимизация
docker-slim build --target htxv2-ml:latest --tag htxv2-ml:slim

# Создание отчета
docker-slim build --target htxv2-ml:latest --report
```

## 🌱 Terraform

### Инициализация

```bash
# Инициализация Terraform
terraform init

# Планирование изменений
terraform plan

# Применение конфигурации
terraform apply

# Уничтожение инфраструктуры
terraform destroy
```

### Полезные команды

```bash
# Просмотр состояния
terraform show

# Список ресурсов
terraform state list

# Импорт существующих ресурсов
terraform import docker_container.backend <container_id>
```

## 💰 Экономия токенов

### MCP Tools

```bash
# Используйте встроенные инструменты
/tools health_check
/tools market_analysis BTC 1h
/tools portfolio_status

# Быстрые команды
mcp-health
mcp-assets
mcp-btc
mcp-portfolio
```

### Оптимизированные запросы

```bash
# ✅ Хорошо - группировка
"Анализ BTC, ETH, BNB за 4h с сигналами"

# ❌ Плохо - отдельные запросы
"Анализ BTC" + "Анализ ETH" + "Анализ BNB"
```

### Конкретизация параметров

```bash
# ✅ Хорошо - конкретный запрос
"Покажи анализ BTC за последний час с рекомендациями"

# ❌ Плохо - общий запрос
"Расскажи про криптовалюты"
```

## 🧹 Очистка системы

### Docker

```bash
# Очистка неиспользуемых ресурсов
docker system prune -a

# Очистка томов
docker volume prune

# Очистка сетей
docker network prune

# Полная очистка
docker system prune -a --volumes
```

### Terraform

```bash
# Очистка состояния
terraform destroy

# Очистка кэша
rm -rf .terraform/
rm -f .terraform.lock.hcl
```

## 📊 Мониторинг

### Статистика использования

```bash
# Использование токенов
curl -s http://localhost:8000/api/v1/mcp/stats

# Статус системы
/tools health_check all

# Статистика Docker
docker stats
```

### Логи

```bash
# Логи всех сервисов
docker compose logs -f

# Логи конкретного сервиса
docker compose logs -f backend

# Логи с фильтрацией
docker compose logs -f | grep ERROR
```

## 🔍 Устранение проблем

### Проблема: Контейнер не запускается

```bash
# Проверка логов
docker compose logs <service_name>

# Перезапуск сервиса
docker compose restart <service_name>

# Полная пересборка
docker compose down
docker compose up -d --build
```

### Проблема: Порты заняты

```bash
# Поиск процессов на портах
sudo lsof -ti:3000,8000,8888,5432,6379

# Завершение процессов
sudo lsof -ti:3000,8000,8888,5432,6379 | xargs kill -9
```

### Проблема: MCP tools не работают

```bash
# Перезапуск MCP сервера
cd /workspace/.mcp
npm install
npm start

# Проверка конфигурации
cat /workspace/.vscode/settings.json
```

## 📚 Дополнительные ресурсы

- [TOKEN_ECONOMY.md](.mcp/TOKEN_ECONOMY.md) - экономия токенов
- [CODESPACE_SETUP.md](.mcp/CODESPACE_SETUP.md) - настройка codespace
- [Backend MCP_README.md](backend/MCP_README.md) - техническая документация

## 🆘 Поддержка

Если возникли проблемы:

1. **Проверьте логи**: `docker compose logs`
2. **Перезапустите сервисы**: `docker compose restart`
3. **Проверьте MCP**: `test-mcp`
4. **Обратитесь к документации** в `/workspace/docs/`

## 📈 Производительность

### Оптимизация образов
- Использование `python:3.12-slim` базового образа
- Кэширование pip зависимостей
- Очистка apt кэша
- Многоэтапная сборка

### Экономия токенов
- Группировка запросов: **-47% токенов**
- Использование `/tools`: **-83% повторных запросов**
- Конкретизация параметров: **-75% избыточной информации**
- **Итоговая экономия: ~60% токенов**

## 🎯 Следующие шаги

1. **Откройте проект в DevContainer**
2. **Запустите сервисы**: `docker compose up -d`
3. **Откройте JupyterLab**: http://localhost:8888/lab?token=htxv2-dev
4. **Протестируйте MCP tools**: `/tools health_check`
5. **Изучите экономию токенов**: `TOKEN_ECONOMY.md`

---

**Готово к ML разработке! 🚀**