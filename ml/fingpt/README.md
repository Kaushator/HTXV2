# FinGPT Local Model

This directory contains the local FinGPT model setup for RTX 4060 GPU.

## Model Files

- `config.json` - Model configuration
- `model_config.py` - Python configuration for local inference
- `requirements.txt` - Specific requirements for FinGPT
- `model_loader.py` - Model loading and initialization
- `inference_server.py` - Local inference server

## Setup

1. Download FinGPT model weights:
```bash
# This will be done automatically on first run
# Or manually download to ~/fingpt_models/ directory
```

2. The model will be loaded automatically when the ML service starts with GPU support.

## RTX 4060 Optimizations

- Mixed precision training (FP16)
- Gradient checkpointing
- LoRA adapters for memory efficiency
- Dynamic batching based on GPU memory