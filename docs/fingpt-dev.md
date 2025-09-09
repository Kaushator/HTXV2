# FinGPT Developer Guide

This guide provides comprehensive instructions for setting up, running, and troubleshooting the FinGPT ML server component.

## Overview

FinGPT is a specialized machine learning server that provides financial analysis capabilities using PyTorch and FastAPI. It's designed to run on NVIDIA GPUs (specifically tested with RTX 4060) for optimal performance.

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backend API   │────│   FinGPT Server │────│   NVIDIA GPU    │
│   (FastAPI)     │    │   (Port 8055)   │    │   (CUDA 12.1)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    HTTP/REST              PyTorch Models          Tensor Operations
```

## Prerequisites

### System Requirements

#### Minimum Requirements
- **GPU**: NVIDIA RTX 4060 or equivalent (8GB VRAM)
- **RAM**: 16GB system memory
- **Storage**: 10GB free space
- **OS**: Windows 10/11 or Ubuntu 20.04+

#### Recommended Requirements
- **GPU**: NVIDIA RTX 4070 or higher (12GB+ VRAM)
- **RAM**: 32GB system memory
- **Storage**: 50GB free space (for models and datasets)

### Software Prerequisites

#### Windows
1. **NVIDIA Drivers**: Version 530.x or newer
2. **CUDA Toolkit**: 12.1 (specific version required)
3. **Python**: 3.9-3.11 (avoid 3.12 due to PyTorch compatibility)
4. **Docker Desktop**: With WSL2 backend (for containerized deployment)

#### Linux (Ubuntu)
1. **NVIDIA Drivers**: Version 530.x or newer
2. **CUDA Toolkit**: 12.1
3. **Python**: 3.9-3.11
4. **Docker**: Latest stable version

## Installation & Setup

### Method 1: Local Development Setup

#### Windows Setup

1. **Install NVIDIA Drivers**
   ```powershell
   # Check current driver version
   nvidia-smi
   
   # If version < 530.x, download from NVIDIA website
   # https://www.nvidia.com/drivers/
   ```

2. **Install CUDA Toolkit 12.1**
   ```powershell
   # Download from https://developer.nvidia.com/cuda-12-1-0-download-archive
   # Follow installer instructions
   
   # Verify installation
   nvcc --version
   ```

3. **Setup Python Environment**
   ```powershell
   # Create virtual environment
   python -m venv fingpt-env
   fingpt-env\\Scripts\\activate
   
   # Upgrade pip
   python -m pip install --upgrade pip
   
   # Install PyTorch with CUDA support
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
   
   # Install other dependencies
   cd fingpt
   pip install -r requirements.txt
   ```

4. **Verify GPU Setup**
   ```python
   import torch
   print(f\"CUDA available: {torch.cuda.is_available()}\")
   print(f\"CUDA version: {torch.version.cuda}\")
   print(f\"GPU count: {torch.cuda.device_count()}\")
   print(f\"GPU name: {torch.cuda.get_device_name(0)}\")
   ```

#### Linux Setup

1. **Install NVIDIA Drivers**
   ```bash
   # Update package list
   sudo apt update
   
   # Install recommended driver
   sudo apt install nvidia-driver-535
   
   # Reboot system
   sudo reboot
   
   # Verify installation
   nvidia-smi
   ```

2. **Install CUDA Toolkit**
   ```bash
   # Download and install CUDA 12.1
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
   sudo dpkg -i cuda-keyring_1.0-1_all.deb
   sudo apt-get update
   sudo apt-get -y install cuda-toolkit-12-1
   
   # Add to PATH
   echo 'export PATH=/usr/local/cuda-12.1/bin:$PATH' >> ~/.bashrc
   echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
   source ~/.bashrc
   
   # Verify installation
   nvcc --version
   ```

3. **Setup Python Environment**
   ```bash
   # Install Python 3.10
   sudo apt install python3.10 python3.10-venv python3.10-dev
   
   # Create virtual environment
   python3.10 -m venv fingpt-env
   source fingpt-env/bin/activate
   
   # Install dependencies
   pip install --upgrade pip
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
   cd fingpt
   pip install -r requirements.txt
   ```

### Method 2: Docker Setup

#### Build and Run Container

```bash
# Navigate to project root
cd HTXEnterface_v2

# Build FinGPT Docker image
docker build -t fingpt-server ./fingpt

# Run with GPU support
docker run --gpus all -p 8055:8055 fingpt-server

# For development with volume mounting
docker run --gpus all -p 8055:8055 -v $(pwd)/fingpt:/app fingpt-server
```

#### Docker Compose Integration

```yaml
# Add to docker-compose.yml
services:
  fingpt:
    build: ./fingpt
    ports:
      - \"8055:8055\"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
```

## Running the Server

### Local Development

```bash
# Activate virtual environment
# Windows: fingpt-env\\Scripts\\activate
# Linux: source fingpt-env/bin/activate

# Navigate to fingpt directory
cd fingpt

# Start server
python server.py

# Alternative: Use uvicorn directly
uvicorn server:app --host 0.0.0.0 --port 8055 --reload
```

### Production Mode

```bash
# Run with optimized settings
uvicorn server:app --host 0.0.0.0 --port 8055 --workers 1 --loop uvloop
```

### Verification

1. **Health Check**
   ```bash
   curl http://localhost:8055/health
   ```

2. **Expected Response**
   ```json
   {
     \"status\": \"healthy\",
     \"service\": \"FinGPT ML Server\",
     \"version\": \"0.1.0\",
     \"device\": \"cuda:0\",
     \"cuda_available\": true,
     \"gpu_name\": \"NVIDIA GeForce RTX 4060\",
     \"timestamp\": \"2024-01-15T10:30:00\"
   }
   ```

## API Endpoints

### Core Endpoints

| Endpoint | Method | Description | Example |
|----------|---------|-------------|---------|
| `/health` | GET | Health check with GPU status | `curl localhost:8055/health` |
| `/predict` | POST | Generate price predictions | See below |
| `/train` | POST | Train model with new data | See below |
| `/model/info` | GET | Current model information | `curl localhost:8055/model/info` |

### Example API Calls

#### Price Prediction
```bash
curl -X POST \"http://localhost:8055/predict\" \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"symbol\": \"BTCUSDT\",
    \"price_data\": [50000, 51000, 49500, 52000],
    \"timeframe\": \"24h\"
  }'
```

#### Model Training
```bash
curl -X POST \"http://localhost:8055/train\" \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"training_data\": [
      {\"symbol\": \"BTCUSDT\", \"price\": 50000, \"volume\": 1000000},
      {\"symbol\": \"ETHUSDT\", \"price\": 3000, \"volume\": 500000}
    ],
    \"epochs\": 10,
    \"learning_rate\": 0.001
  }'
```

## Monitoring & Logging

### Log Locations

#### Local Development
```bash
# Server logs (stdout)
python server.py > fingpt.log 2>&1

# Container logs
docker logs fingpt-server
```

#### Log Levels
- `INFO`: Normal operations, GPU status, model loading
- `WARNING`: Performance issues, fallback to CPU
- `ERROR`: Model failures, CUDA errors
- `DEBUG`: Detailed tensor operations (enable for debugging)

### Key Log Messages

#### Successful Startup
```
INFO:__main__:Using device: cuda:0
INFO:__main__:GPU: NVIDIA GeForce RTX 4060
INFO:__main__:CUDA Version: 12.1
INFO:uvicorn.error:Uvicorn running on http://0.0.0.0:8055
```

#### GPU Memory Usage
```bash
# Monitor GPU usage
nvidia-smi -l 1

# In Python/server code
import torch
print(f\"GPU Memory: {torch.cuda.memory_allocated() / 1024**3:.2f} GB\")
```

### Performance Monitoring

```bash
# GPU utilization
watch -n 1 nvidia-smi

# Server metrics endpoint
curl http://localhost:8055/metrics

# Memory usage
htop
```

## Troubleshooting

### Common Issues

#### 1. CUDA Not Available
**Symptoms:**
```
Using device: cpu
RuntimeError: CUDA not available
```

**Solutions:**
```bash
# Check NVIDIA driver
nvidia-smi

# Reinstall PyTorch with CUDA
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Verify CUDA installation
nvcc --version
```

#### 2. Out of Memory (OOM)
**Symptoms:**
```
RuntimeError: CUDA out of memory
```

**Solutions:**
```python
# Reduce batch size
# Clear cache
torch.cuda.empty_cache()

# Monitor memory
print(torch.cuda.memory_summary())
```

#### 3. Version Incompatibility
**Symptoms:**
```
ImportError: cannot import name 'xxx' from 'torch'
ModuleNotFoundError: No module named 'torch'
```

**Solutions:**
```bash
# Check versions
python -c \"import torch; print(torch.__version__)\"
nvcc --version

# Reinstall with correct CUDA version
pip install torch==2.1.0+cu121 --index-url https://download.pytorch.org/whl/cu121
```

#### 4. Server Won't Start
**Symptoms:**
```
OSError: [Errno 98] Address already in use
Permission denied
```

**Solutions:**
```bash
# Kill existing process
lsof -ti:8055 | xargs kill -9

# Use different port
uvicorn server:app --port 8056

# Check permissions
sudo netstat -tulpn | grep 8055
```

### Advanced Debugging

#### Enable Debug Logging
```python
# Add to server.py
import logging
logging.basicConfig(level=logging.DEBUG)

# Or set environment variable
export LOGLEVEL=DEBUG
```

#### CUDA Debugging
```bash
# Enable CUDA debugging
export CUDA_LAUNCH_BLOCKING=1

# Check CUDA runtime
python -c \"import torch; print(torch.cuda.is_available(), torch.cuda.device_count())\"
```

#### Memory Profiling
```python
# Add memory profiling
import torch.profiler
with torch.profiler.profile(
    activities=[
        torch.profiler.ProfilerActivity.CPU,
        torch.profiler.ProfilerActivity.CUDA,
    ]
) as prof:
    # Your model operations
    pass
print(prof.key_averages().table())
```

## Model Management

### Updating Models

1. **Download New Model**
   ```bash
   # Stop server
   pkill -f \"python server.py\"
   
   # Backup current model
   cp -r models/ models_backup_$(date +%Y%m%d)/
   
   # Download/copy new model files
   # ...
   
   # Restart server
   python server.py
   ```

2. **Model Versioning**
   ```bash
   # Use environment variables
   export MODEL_VERSION=v2.1.0
   export MODEL_PATH=/app/models/fingpt-v2.1.0
   
   # Update Docker image
   docker build -t fingpt-server:v2.1.0 ./fingpt
   ```

### Model Files Structure
```
fingpt/
├── models/
│   ├── fingpt-base/
│   │   ├── config.json
│   │   ├── pytorch_model.bin
│   │   └── tokenizer.json
│   └── checkpoints/
├── server.py
├── requirements.txt
└── Dockerfile
```

## Performance Optimization

### GPU Optimization
```python
# Enable mixed precision
from torch.cuda.amp import autocast, GradScaler

# Optimize memory usage
torch.backends.cudnn.benchmark = True
torch.backends.cudnn.deterministic = False

# Use tensor cores (RTX 4060)
torch.backends.cuda.matmul.allow_tf32 = True
```

### Server Optimization
```bash
# Use optimized uvicorn settings
uvicorn server:app \\
  --host 0.0.0.0 \\
  --port 8055 \\
  --workers 1 \\
  --loop uvloop \\
  --http httptools
```

## Integration with Main Backend

### Connection Configuration
```python
# In backend/app/services/ml_service.py
FINGPT_URL = \"http://localhost:8055\"
FINGPT_TIMEOUT = 30  # seconds

async def predict_price(symbol: str, data: List[float]):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f\"{FINGPT_URL}/predict\",
            json={\"symbol\": symbol, \"price_data\": data},
            timeout=FINGPT_TIMEOUT
        )
        return response.json()
```

### Health Check Integration
```python
# Add to backend health checks
@app.get(\"/health\")
async def health_check():
    # Check FinGPT service
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f\"{FINGPT_URL}/health\", timeout=5)
            fingpt_status = response.status_code == 200
    except:
        fingpt_status = False
    
    return {
        \"status\": \"healthy\" if fingpt_status else \"degraded\",
        \"services\": {
            \"fingpt\": \"healthy\" if fingpt_status else \"unhealthy\"
        }
    }
```

## Development Workflow

### Local Development Cycle
1. **Start Services**
   ```bash
   # Terminal 1: Backend
   cd backend && uvicorn app.main:app --reload
   
   # Terminal 2: FinGPT
   cd fingpt && python server.py
   
   # Terminal 3: Frontend
   cd frontend && npm run dev
   ```

2. **Testing Changes**
   ```bash
   # Test FinGPT endpoint
   curl http://localhost:8055/health
   
   # Test integration
   curl http://localhost:8000/api/ml/predict
   ```

3. **Debugging**
   ```bash
   # Check logs
   tail -f fingpt.log
   
   # Monitor GPU
   nvidia-smi -l 1
   ```

### Production Deployment

1. **Build Production Image**
   ```bash
   docker build -t gcr.io/your-project/fingpt:latest ./fingpt
   docker push gcr.io/your-project/fingpt:latest
   ```

2. **Deploy to Cloud Run**
   ```bash
   gcloud run deploy fingpt-service \\
     --image gcr.io/your-project/fingpt:latest \\
     --port 8055 \\
     --memory 8Gi \\
     --cpu 4 \\
     --gpu 1 \\
     --gpu-type nvidia-t4
   ```

## Support & Resources

### Documentation
- [PyTorch Documentation](https://pytorch.org/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [NVIDIA CUDA Documentation](https://docs.nvidia.com/cuda/)

### Community
- PyTorch Forums: https://discuss.pytorch.org/
- FastAPI Discussions: https://github.com/tiangolo/fastapi/discussions

### Internal Resources
- Architecture Overview: `docs/architecture.md`
- API Documentation: `docs/api-endpoints.md`
- Deployment Guide: `docs/deployment-plan.md`

---

**Last Updated**: January 2024  
**Tested On**: Windows 11, Ubuntu 22.04, RTX 4060  
**Maintainer**: HTX Interface Team
