FROM python:3.11-slim-bullseye

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
  gcc \
  g++ \
  libpq-dev \
  python3-pip \
  gcc \
  g++ \
  libpq-dev \
  curl \
  wget \
  git \
  && rm -rf /var/lib/apt/lists/*

# Create symlinks for Python (force overwrite if exists)
RUN ln -sf /usr/bin/python3.11 /usr/bin/python && \
  ln -sf /usr/bin/python3.11 /usr/bin/python3

# Set memory optimization for 90GB RAM
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
ENV TRANSFORMERS_CACHE=/app/models/cache
ENV HF_HOME=/app/models/cache

# Copy requirements first for better caching
COPY ml/requirements.txt .

# Upgrade pip and install PyTorch (CPU version for stability)
RUN python -m pip install --upgrade pip
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install other Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ml/ .

# Create directories for models and cache
RUN mkdir -p models/fingpt models/cache /app/data

# Set memory optimization for 90GB RAM
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
ENV CUDA_LAUNCH_BLOCKING=0
ENV TRANSFORMERS_CACHE=/app/models/cache
ENV HF_HOME=/app/models/cache

# Create non-root user
RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app
USER app

# Expose port for model serving
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the model server
CMD ["python", "services/model_server.py"]
