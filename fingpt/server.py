from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
import numpy as np
from datetime import datetime
import logging
from typing import List, Dict, Any, Optional

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="FinGPT ML Server",
    description="Financial GPT model for cryptocurrency analysis with tensor support",
    version="0.1.0"
)

# Проверка доступности GPU для RTX 4060
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
logger.info(f"Using device: {device}")

if torch.cuda.is_available():
    gpu_name = torch.cuda.get_device_name(0)
    logger.info(f"GPU: {gpu_name}")
    logger.info(f"CUDA Version: {torch.version.cuda}")

class PredictionRequest(BaseModel):
    symbol: str
    price_data: Optional[List[float]] = []
    timeframe: Optional[str] = "24h"

class TrainingRequest(BaseModel):
    training_data: List[Dict[str, Any]]
    epochs: Optional[int] = 10
    learning_rate: Optional[float] = 0.001

@app.get("/health")
@app.get("/healthz")
@app.get("/ping")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "FinGPT ML Server",
        "version": "0.1.0",
        "device": str(device),
        "cuda_available": torch.cuda.is_available(),
        "gpu_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/predict")
async def predict(request: PredictionRequest):
    """Generate ML prediction for cryptocurrency data"""
    try:
        # Mock ML prediction (в реальности здесь будет FinGPT модель)
        price_data = request.price_data or []
        prediction = generate_mock_prediction(request.symbol, price_data)
        
        return {
            "symbol": request.symbol,
            "prediction": prediction,
            "model": "FinGPT-mock",
            "device": str(device),
            "timestamp": datetime.now().isoformat()
        }
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/train")
async def train(request: TrainingRequest):
    """Train model on new data"""
    try:
        # Mock training process
        epochs = request.epochs or 10
        training_result = simulate_training(request.training_data, epochs)
        
        return {
            "status": "training_completed",
            "epochs": epochs,
            "loss": training_result['loss'],
            "accuracy": training_result['accuracy'],
            "device": str(device),
            "timestamp": datetime.now().isoformat()
        }
    
    except Exception as e:
        logger.error(f"Training error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/model/info")
async def model_info():
    """Get model information"""
    return {
        "model_name": "FinGPT",
        "version": "0.1.0",
        "parameters": "7B (mock)",
        "fine_tuned": True,
        "training_data": "Financial texts + Market data",
        "capabilities": [
            "Price prediction",
            "Sentiment analysis", 
            "Market trend analysis",
            "Risk assessment"
        ],
        "device": str(device),
        "memory_usage": get_memory_usage(),
        "timestamp": datetime.now().isoformat()
    }

def generate_mock_prediction(symbol: str, price_data: List[float]):
    """Generate mock ML prediction"""
    np.random.seed(42)  # для воспроизводимости
    
    # Симуляция анализа
    base_confidence = 0.75 + np.random.random() * 0.2
    
    # Технический анализ (mock)
    technical_signal = np.random.choice(['bullish', 'bearish', 'neutral'], 
                                      p=[0.4, 0.3, 0.3])
    technical_confidence = base_confidence + np.random.random() * 0.1
    
    # Анализ настроений (mock)
    sentiment_signal = np.random.choice(['positive', 'negative', 'neutral'],
                                      p=[0.5, 0.2, 0.3])
    sentiment_confidence = base_confidence + np.random.random() * 0.15
    
    # Прогноз цены
    price_change = (np.random.random() - 0.5) * 0.2  # ±10%
    
    return {
        "technical_analysis": {
            "signal": technical_signal,
            "confidence": min(technical_confidence, 1.0),
            "indicators": {
                "rsi": 50 + np.random.random() * 40,
                "macd": "bullish" if np.random.random() > 0.5 else "bearish",
                "moving_average": "above" if np.random.random() > 0.4 else "below"
            }
        },
        "sentiment_analysis": {
            "signal": sentiment_signal,
            "confidence": min(sentiment_confidence, 1.0),
            "sources": ["news", "social_media", "market_data"]
        },
        "price_prediction": {
            "direction": "up" if price_change > 0 else "down",
            "magnitude": abs(price_change),
            "timeframe": "24h",
            "confidence": min(base_confidence, 1.0)
        },
        "risk_assessment": {
            "level": "medium",
            "factors": ["volatility", "market_conditions", "liquidity"],
            "score": 0.6 + np.random.random() * 0.3
        }
    }

def simulate_training(training_data: List[Dict], epochs: int):
    """Simulate model training"""
    # Симуляция обучения с убывающей потерей
    initial_loss = 0.8
    final_loss = 0.15 + np.random.random() * 0.1
    
    loss_progression = np.logspace(np.log10(initial_loss), 
                                 np.log10(final_loss), epochs)
    
    final_accuracy = 0.85 + np.random.random() * 0.1
    
    return {
        "loss": float(loss_progression[-1]),
        "accuracy": min(final_accuracy, 0.95),
        "loss_history": loss_progression.tolist()
    }

def get_memory_usage():
    """Get GPU memory usage if available"""
    if torch.cuda.is_available():
        return {
            "allocated": f"{torch.cuda.memory_allocated() / 1024**3:.2f} GB",
            "cached": f"{torch.cuda.memory_reserved() / 1024**3:.2f} GB",
            "total": f"{torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB"
        }
    return {"cpu_only": True}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8055)
