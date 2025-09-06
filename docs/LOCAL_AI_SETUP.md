# Local AI Environment Setup for RTX 4060 + WSL2

This guide helps you set up a local AI environment for the HTXV2 project using Docker Desktop on Windows with WSL2 and RTX 4060 GPU.

## Prerequisites

- Windows 11 (or Windows 10 with latest updates)
- Docker Desktop with WSL2 backend
- NVIDIA RTX 4060 GPU
- 90GB RAM (you'll use ~85GB for optimal performance)
- WSL2 with Ubuntu distribution

## GPU Setup

### 1. Install NVIDIA Drivers

1. Download and install the latest NVIDIA Game Ready or Studio drivers
2. Ensure CUDA 12.1+ support is available

### 2. Install NVIDIA Container Toolkit

In your WSL2 Ubuntu distribution:

```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-container-toolkit
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

# Restart Docker Desktop after installation
```

### 3. Configure WSL2

Copy the `.wslconfig` file to your Windows user directory:

```powershell
# In PowerShell
copy docker\.wslconfig %USERPROFILE%\.wslconfig
```

Restart WSL2:
```powershell
wsl --shutdown
```

## Docker Configuration

### 1. Enable GPU Support in Docker Desktop

1. Open Docker Desktop
2. Go to Settings → Resources → WSL Integration
3. Enable integration with your Ubuntu distribution
4. Go to Settings → Docker Engine
5. Add GPU runtime configuration:

```json
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}
```

### 2. Verify GPU Access

Test GPU access in Docker:

```bash
docker run --rm --gpus all nvidia/cuda:12.1-base-ubuntu22.04 nvidia-smi
```

## Running the AI Environment

### 1. Clone and Setup

```bash
git clone https://github.com/Kaushator/HTXV2.git
cd HTXV2
```

### 2. Start GPU-Enabled Services

```bash
cd docker
docker compose -f docker-compose.gpu.yml up -d
```

This will start:
- PostgreSQL database with pgvector
- Redis cache
- Backend API
- Frontend application
- ETL services
- **ML services with RTX 4060 GPU support**

### 3. Verify Services

Check that all services are running:

```bash
docker compose -f docker-compose.gpu.yml ps
```

Check ML service GPU access:

```bash
docker compose -f docker-compose.gpu.yml exec ml-gpu nvidia-smi
```

### 4. Access Applications

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs
- ML Service: http://localhost:8080

## FinGPT Local Model

The local FinGPT model will be automatically downloaded and set up on first run. It will be stored in `~/fingpt_models/` on your host system.

### Model Configuration

The model is configured for RTX 4060 with:
- 4-bit quantization for memory efficiency
- LoRA adapters for fine-tuning
- Mixed precision (FP16) training
- Dynamic batching based on GPU memory

### GPU Memory Usage

The configuration uses:
- ~7GB of RTX 4060's 8GB VRAM
- Up to 85GB of system RAM for large model loading
- Shared memory optimization for model inference

## Performance Optimization

### RTX 4060 Specific

- **Memory Management**: 4-bit quantization reduces VRAM usage by ~75%
- **Compute Optimization**: FP16 mixed precision for 2x speed improvement
- **LoRA Adapters**: Efficient fine-tuning with minimal memory overhead

### System RAM (90GB)

- **Model Caching**: Large models cached in system RAM
- **Batch Processing**: Large batch sizes for training efficiency
- **Memory Mapping**: Efficient model loading with memory mapping

## Monitoring

### GPU Monitoring

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Docker container GPU usage
docker stats ml-gpu
```

### Application Monitoring

The ML service provides monitoring endpoints:

- GPU Status: http://localhost:8080/gpu/status
- Model Info: http://localhost:8080/model/info
- Health Check: http://localhost:8080/health

## Troubleshooting

### Common Issues

1. **GPU not detected in container**:
   - Verify NVIDIA drivers are installed
   - Check nvidia-container-toolkit installation
   - Restart Docker Desktop

2. **Out of memory errors**:
   - Reduce batch size in model configuration
   - Enable gradient checkpointing
   - Use smaller model variants

3. **Slow model loading**:
   - Ensure model cache is on fast storage (NVMe SSD)
   - Increase shared memory size
   - Check RAM allocation in .wslconfig

### Performance Tips

1. **Use NVMe SSD** for model storage
2. **Close unnecessary applications** to free up RAM
3. **Monitor GPU temperature** to avoid throttling
4. **Use Docker BuildKit** for faster builds

## Integration with Google Cloud

While running locally, you can still integrate with Google Cloud services:

- **Data Storage**: Store training data in Google Cloud Storage
- **Model Registry**: Save trained models to Google Cloud
- **Monitoring**: Use Google Cloud Monitoring for production metrics
- **Backup**: Sync local models to Google Cloud for backup

The local environment provides fast development and training, while Google Cloud provides production scaling and data management.