# ML DevContainer для HTXV2 с MCP Tools
FROM python:3.12-slim

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    # Основные инструменты
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tree \
    jq \
    unzip \
    zip \
    # Docker CLI
    ca-certificates \
    gnupg \
    lsb-release \
    # ML зависимости
    build-essential \
    gcc \
    g++ \
    # Jupyter
    nodejs \
    npm \
    # Cleanup
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Установка Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Установка Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Установка DevOps инструментов
RUN curl -L https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint \
    && chmod +x /usr/local/bin/hadolint

RUN curl -L https://github.com/wagoodman/dive/releases/latest/download/dive_0.12.0_linux_amd64.deb -o /tmp/dive.deb \
    && dpkg -i /tmp/dive.deb \
    && rm /tmp/dive.deb

RUN curl -L https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.50.1_Linux-64bit.tar.gz -o /tmp/trivy.tar.gz \
    && tar -xzf /tmp/trivy.tar.gz -C /usr/local/bin \
    && rm /tmp/trivy.tar.gz

RUN curl -L https://github.com/docker-slim/docker-slim/releases/latest/download/dist_linux.tar.gz -o /tmp/docker-slim.tar.gz \
    && tar -xzf /tmp/docker-slim.tar.gz -C /usr/local/bin \
    && rm /tmp/docker-slim.tar.gz

# Установка Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Установка pre-commit
RUN pip install --no-cache-dir pre-commit

# Создание пользователя для разработки
RUN useradd -m -s /bin/bash devuser \
    && usermod -aG docker devuser

# Настройка рабочей директории
WORKDIR /workspace

# Создание директорий для моделей и кэша
RUN mkdir -p /workspace/models \
    && mkdir -p /workspace/.cache \
    && mkdir -p /workspace/.mcp

# Установка Python зависимостей (кэширование)
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Установка JupyterLab и расширений
RUN pip install --no-cache-dir jupyterlab \
    jupyterlab-git \
    jupyterlab-lsp \
    jupyterlab-widgets \
    ipywidgets \
    && jupyter lab --generate-config

# Настройка переменных окружения для ML
ENV HF_HOME=/workspace/models/huggingface
ENV TRANSFORMERS_CACHE=/workspace/models/transformers
ENV TORCH_HOME=/workspace/models/torch
ENV MLFLOW_TRACKING_URI=/workspace/models/mlflow
ENV PYTHONPATH=/workspace:$PYTHONPATH

# Настройка Jupyter
RUN jupyter lab --generate-config \
    && echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.port = 8888" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py

# Установка MCP зависимостей
RUN cd /workspace/.mcp \
    && npm init -y \
    && npm install @modelcontextprotocol/sdk

# Создание символических ссылок для удобства
RUN ln -sf /usr/local/bin/docker-compose /usr/local/bin/dc

# Настройка прав доступа
RUN chown -R devuser:devuser /workspace \
    && chmod -R 755 /workspace

# Переключение на пользователя devuser
USER devuser

# Настройка bash для пользователя
RUN echo 'alias ll="ls -la"' >> /home/devuser/.bashrc \
    && echo 'alias dc="docker-compose"' >> /home/devuser/.bashrc \
    && echo 'alias tf="terraform"' >> /home/devuser/.bashrc \
    && echo 'export PATH="/workspace/.local/bin:$PATH"' >> /home/devuser/.bashrc

# Открытие портов
EXPOSE 8888 3000 8000 5432 6379

# Команда по умолчанию
CMD ["/bin/bash"]