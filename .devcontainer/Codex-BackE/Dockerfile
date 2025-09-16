# Используем официальный образ Python 3.11 на Ubuntu 22.04 в качестве основы
FROM python:3.11-slim-bullseye

# Установим системные пакеты (git, gcc для сборки, постгрес-клиент, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget build-essential libpq-dev python3-dev \
    postgresql-client gnupg \
    && rm -rf /var/lib/apt/lists/*

# Установка Node.js для MCP
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем pip-зависимости бекенда
WORKDIR /workspace
COPY backend/requirements.txt /workspace/requirements.txt
RUN pip install --upgrade pip && pip install -r /workspace/requirements.txt

# (Опционально) Устанавливаем зависимости ML-модуля, если нужны в бекенде:
# COPY fingpt/requirements.txt /workspace/ml-requirements.txt
# RUN pip install -r /workspace/ml-requirements.txt

# Создаём пользователя для работы (не root)
RUN useradd -ms /bin/bash vscode
USER vscode

# Рабочая директория по умолчанию – папка проекта
WORKDIR /workspace

# Открываем нужные порты: 8000 (API), 5432 (Postgres), 6379 (Redis), 8080 (ML)
EXPOSE 8000 5432 6379 8080

# По умолчанию команда не запускается (контейнер будет запущен через VSCode devcontainer)
CMD ["sleep", "infinity"]
