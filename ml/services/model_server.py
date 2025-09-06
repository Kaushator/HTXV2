"""
ML Model Server for HTXV2 with GPU support
Serves FinGPT and other AI models locally on RTX 4060
"""

import asyncio
import os
import time
from typing import Dict, Any, Optional
import structlog
import torch
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

from fingpt_client import fingpt_client, initialize_fingpt

logger = structlog.get_logger(__name__)

# Pydantic models
class GenerationRequest(BaseModel):
    prompt: str
    max_length: int = 512
    temperature: float = 0.7
    top_p: float = 0.9

class FinancialAnalysisRequest(BaseModel):
    symbol: str
    market_data: Dict[str, Any]
    context: Optional[str] = None

class GenerationResponse(BaseModel):
    content: str
    tokens_used: int
    response_time: float
    model_used: str
    gpu_memory_used: int
    confidence: float

class HealthResponse(BaseModel):
    status: str
    gpu_available: bool
    gpu_name: Optional[str]
    gpu_memory_total: int
    gpu_memory_allocated: int
    models_loaded: Dict[str, bool]
    uptime: float

class ModelInfoResponse(BaseModel):
    fingpt: Dict[str, Any]
    system: Dict[str, Any]
    gpu: Dict[str, Any]

# FastAPI app
app = FastAPI(
    title="HTXV2 ML Model Server",
    description="Local AI model server with RTX 4060 GPU support",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global state
startup_time = time.time()
models_initialized = {"fingpt": False}

@app.on_event("startup")
async def startup_event():
    """Initialize models on startup"""
    logger.info("Starting ML Model Server...")
    
    # Check GPU availability
    gpu_available = torch.cuda.is_available()
    if gpu_available:
        gpu_name = torch.cuda.get_device_name(0)
        gpu_memory = torch.cuda.get_device_properties(0).total_memory / 1024**3
        logger.info(f"GPU detected: {gpu_name} ({gpu_memory:.1f}GB)")
    else:
        logger.warning("No GPU detected, running in CPU mode")
    
    # Initialize FinGPT
    if os.getenv("USE_GPU", "true").lower() == "true" and gpu_available:
        logger.info("Initializing FinGPT with GPU support...")
        success = await initialize_fingpt()
        models_initialized["fingpt"] = success
        if success:
            logger.info("FinGPT initialized successfully")
        else:
            logger.error("Failed to initialize FinGPT")
    else:
        logger.info("GPU disabled or not available, skipping FinGPT initialization")

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    gpu_available = torch.cuda.is_available()
    
    return HealthResponse(
        status="healthy",
        gpu_available=gpu_available,
        gpu_name=torch.cuda.get_device_name(0) if gpu_available else None,
        gpu_memory_total=torch.cuda.get_device_properties(0).total_memory if gpu_available else 0,
        gpu_memory_allocated=torch.cuda.memory_allocated() if gpu_available else 0,
        models_loaded=models_initialized,
        uptime=time.time() - startup_time
    )

@app.get("/gpu/status")
async def gpu_status():
    """Get detailed GPU status"""
    if not torch.cuda.is_available():
        return {"error": "No GPU available"}
    
    return {
        "gpu_count": torch.cuda.device_count(),
        "current_device": torch.cuda.current_device(),
        "device_name": torch.cuda.get_device_name(0),
        "memory_allocated": torch.cuda.memory_allocated(),
        "memory_reserved": torch.cuda.memory_reserved(),
        "memory_total": torch.cuda.get_device_properties(0).total_memory,
        "cuda_version": torch.version.cuda,
        "pytorch_version": torch.__version__
    }

@app.get("/model/info", response_model=ModelInfoResponse)
async def model_info():
    """Get model information"""
    fingpt_status = fingpt_client.get_status() if models_initialized["fingpt"] else {"status": "not_initialized"}
    
    system_info = {
        "python_version": os.sys.version,
        "pytorch_version": torch.__version__,
        "transformers_version": "4.35.0+",  # From requirements
        "cuda_available": torch.cuda.is_available(),
        "cuda_version": torch.version.cuda if torch.cuda.is_available() else None
    }
    
    gpu_info = {}
    if torch.cuda.is_available():
        props = torch.cuda.get_device_properties(0)
        gpu_info = {
            "name": props.name,
            "major": props.major,
            "minor": props.minor,
            "total_memory": props.total_memory,
            "multi_processor_count": props.multi_processor_count
        }
    
    return ModelInfoResponse(
        fingpt=fingpt_status,
        system=system_info,
        gpu=gpu_info
    )

@app.post("/generate", response_model=GenerationResponse)
async def generate_text(request: GenerationRequest):
    """Generate text using FinGPT"""
    if not models_initialized["fingpt"]:
        raise HTTPException(status_code=503, detail="FinGPT model not initialized")
    
    try:
        response = await fingpt_client.generate(
            prompt=request.prompt,
            max_length=request.max_length,
            temperature=request.temperature,
            top_p=request.top_p
        )
        
        return GenerationResponse(
            content=response.content,
            tokens_used=response.tokens_used,
            response_time=response.response_time,
            model_used="FinGPT",
            gpu_memory_used=response.gpu_memory_used,
            confidence=response.confidence
        )
    except Exception as e:
        logger.error(f"Generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze/financial", response_model=GenerationResponse)
async def analyze_financial(request: FinancialAnalysisRequest):
    """Generate financial analysis for a cryptocurrency"""
    if not models_initialized["fingpt"]:
        raise HTTPException(status_code=503, detail="FinGPT model not initialized")
    
    try:
        response = await fingpt_client.generate_financial_analysis(
            symbol=request.symbol,
            market_data=request.market_data,
            context=request.context
        )
        
        return GenerationResponse(
            content=response.content,
            tokens_used=response.tokens_used,
            response_time=response.response_time,
            model_used="FinGPT",
            gpu_memory_used=response.gpu_memory_used,
            confidence=response.confidence
        )
    except Exception as e:
        logger.error(f"Financial analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/models/reload")
async def reload_models(background_tasks: BackgroundTasks):
    """Reload models (useful for development)"""
    background_tasks.add_task(reload_models_task)
    return {"message": "Model reload initiated"}

async def reload_models_task():
    """Background task to reload models"""
    global models_initialized
    logger.info("Reloading models...")
    
    # Reload FinGPT
    success = await initialize_fingpt()
    models_initialized["fingpt"] = success
    
    logger.info("Model reload complete")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "HTXV2 ML Model Server",
        "version": "1.0.0",
        "gpu_available": torch.cuda.is_available(),
        "models_loaded": models_initialized
    }

if __name__ == "__main__":
    # Configure logging
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Run server
    uvicorn.run(
        "model_server:app",
        host="0.0.0.0",
        port=8080,
        reload=False,  # Disable reload for GPU models
        workers=1,     # Single worker for GPU sharing
        log_level="info"
    )