# Terraform configuration for HTXV2 ML Development Environment
terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Docker provider configuration
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create Docker network for HTXV2
resource "docker_network" "htxv2_network" {
  name = "htxv2-network"
  driver = "bridge"
  
  ipam_config {
    subnet = "172.20.0.0/16"
  }
}

# Create Docker volume for models (bind mount to /mnt/hdd/models)
resource "docker_volume" "models_volume" {
  name = "htxv2-models"
  
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "/mnt/hdd/models"
  }
}

# Create Docker volume for PostgreSQL data
resource "docker_volume" "postgres_data" {
  name = "htxv2-postgres-data"
}

# Create Docker volume for Redis data
resource "docker_volume" "redis_data" {
  name = "htxv2-redis-data"
}

# Build HTXV2 ML image
resource "docker_image" "htxv2_ml" {
  name = "htxv2-ml:latest"
  build {
    context    = "."
    dockerfile = ".devcontainer/Dockerfile"
    tag        = ["htxv2-ml:latest", "htxv2-ml:dev"]
  }
  
  triggers = {
    dockerfile_hash = filemd5(".devcontainer/Dockerfile")
    requirements_hash = filemd5("requirements.txt")
  }
}

# PostgreSQL container
resource "docker_container" "postgres" {
  name  = "htxv2-postgres"
  image = "pgvector/pgvector:pg15"
  
  ports {
    internal = 5432
    external = 5432
  }
  
  env = [
    "POSTGRES_DB=htxv2",
    "POSTGRES_USER=htxv2_user",
    "POSTGRES_PASSWORD=password"
  ]
  
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  
  volumes {
    host_path      = "${path.cwd}/docker/init-db.sql"
    container_path = "/docker-entrypoint-initdb.d/init-db.sql"
  }
  
  networks_advanced {
    name = docker_network.htxv2_network.name
  }
  
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U htxv2_user -d htxv2"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
  
  restart = "unless-stopped"
  
  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}

# Redis container
resource "docker_container" "redis" {
  name  = "htxv2-redis"
  image = "redis:7-alpine"
  
  ports {
    internal = 6379
    external = 6379
  }
  
  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }
  
  networks_advanced {
    name = docker_network.htxv2_network.name
  }
  
  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
  
  restart = "unless-stopped"
  
  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}

# Backend container
resource "docker_container" "backend" {
  name  = "htxv2-backend"
  image = docker_image.htxv2_ml.name
  
  ports {
    internal = 8000
    external = 8000
  }
  
  env = [
    "DATABASE_URL=postgresql+asyncpg://htxv2_user:password@htxv2-postgres:5432/htxv2",
    "REDIS_URL=redis://htxv2-redis:6379/0",
    "SECRET_KEY=dev-secret-key-change-in-production",
    "DEBUG=true",
    "ENVIRONMENT=development",
    "HF_HOME=/workspace/models/huggingface",
    "TRANSFORMERS_CACHE=/workspace/models/transformers",
    "TORCH_HOME=/workspace/models/torch",
    "MLFLOW_TRACKING_URI=/workspace/models/mlflow"
  ]
  
  volumes {
    host_path      = "${path.cwd}/backend"
    container_path = "/app"
  }
  
  volumes {
    volume_name    = docker_volume.models_volume.name
    container_path = "/workspace/models"
  }
  
  networks_advanced {
    name = docker_network.htxv2_network.name
  }
  
  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]
  
  command = ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
  
  restart = "unless-stopped"
  
  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}

# JupyterLab container
resource "docker_container" "jupyter" {
  name  = "htxv2-jupyter"
  image = docker_image.htxv2_ml.name
  
  ports {
    internal = 8888
    external = 8888
  }
  
  env = [
    "JUPYTER_ENABLE_LAB=yes",
    "JUPYTER_TOKEN=htxv2-dev",
    "HF_HOME=/workspace/models/huggingface",
    "TRANSFORMERS_CACHE=/workspace/models/transformers",
    "TORCH_HOME=/workspace/models/torch"
  ]
  
  volumes {
    host_path      = path.cwd
    container_path = "/workspace"
  }
  
  volumes {
    volume_name    = docker_volume.models_volume.name
    container_path = "/workspace/models"
  }
  
  networks_advanced {
    name = docker_network.htxv2_network.name
  }
  
  command = [
    "jupyter", "lab", 
    "--ip=0.0.0.0", 
    "--port=8888", 
    "--no-browser", 
    "--allow-root", 
    "--NotebookApp.token=htxv2-dev"
  ]
  
  restart = "unless-stopped"
  
  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}

# Output values
output "network_name" {
  value = docker_network.htxv2_network.name
}

output "models_volume_name" {
  value = docker_volume.models_volume.name
}

output "postgres_connection" {
  value = "postgresql://htxv2_user:password@localhost:5432/htxv2"
}

output "redis_connection" {
  value = "redis://localhost:6379/0"
}

output "jupyter_url" {
  value = "http://localhost:8888/lab?token=htxv2-dev"
}

output "backend_url" {
  value = "http://localhost:8000"
}

output "api_docs_url" {
  value = "http://localhost:8000/docs"
}