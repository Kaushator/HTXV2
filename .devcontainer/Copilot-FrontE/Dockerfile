# Используем официальный образ Node.js 18 на Linux
FROM node:18-slim

# Установим системные пакеты (git, curl для проверок)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем глобальные Node.js утилиты
RUN npm install -g npm@latest

# Создаём пользователя для работы (не root)
RUN useradd -ms /bin/bash vscode

# Устанавливаем зависимости фронтенда
WORKDIR /workspace
RUN mkdir -p /workspace/frontend
COPY frontend/package*.json /workspace/frontend/
RUN cd /workspace/frontend && npm ci

# Устанавливаем зависимости MCP
COPY package*.json /workspace/
RUN cd /workspace && npm install

# Даём права пользователю vscode
RUN chown -R vscode:vscode /workspace
USER vscode

# Рабочая директория по умолчанию – папка проекта
WORKDIR /workspace

# Открываем нужные порты: 3000 (Next.js), 6006 (Storybook), 3010 (MCP)
EXPOSE 3000 6006 3010

# По умолчанию команда не запускается (контейнер будет запущен через VSCode devcontainer)
CMD ["sleep", "infinity"]
