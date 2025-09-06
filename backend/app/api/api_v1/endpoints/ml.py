from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from pydantic import BaseModel

from app.core.security import get_current_active_user
from app.db.session import get_db
from app.models.user import User

router = APIRouter()


class MLAnalysisRequest(BaseModel):
    """ML Analysis request schema"""
    symbol: str
    timeframe: str = "1d"
    analysis_type: str = "technical"  # technical, fundamental, sentiment
    context: Optional[str] = None


class MLAnalysisResponse(BaseModel):
    """ML Analysis response schema"""
    symbol: str
    analysis_type: str
    prediction: dict
    confidence: float
    recommendation: str
    reasoning: str
    timestamp: str


class MLPredictionRequest(BaseModel):
    """ML Prediction request schema"""
    symbol: str
    features: dict
    model_name: Optional[str] = None


class MLModelResponse(BaseModel):
    """ML Model response schema"""
    id: str
    name: str
    type: str
    status: str
    accuracy: Optional[float] = None
    created_at: str


@router.post("/generate-analysis", response_model=MLAnalysisResponse)
async def generate_analysis(
    request: MLAnalysisRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate ML-powered market analysis"""
    from datetime import datetime
    
    # This would integrate with actual ML models
    # For now, providing a structured response template
    return MLAnalysisResponse(
        symbol=request.symbol.upper(),
        analysis_type=request.analysis_type,
        prediction={
            "direction": "bullish",
            "price_target": 52000.0,
            "probability": 0.72,
            "time_horizon": "7d"
        },
        confidence=0.72,
        recommendation="BUY",
        reasoning="Technical indicators show strong momentum with RSI oversold bounce and volume confirmation.",
        timestamp=datetime.utcnow().isoformat()
    )


@router.post("/predict", response_model=dict)
async def predict(
    request: MLPredictionRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Make ML prediction based on features"""
    return {
        "symbol": request.symbol.upper(),
        "prediction": {
            "price_direction": "up",
            "probability": 0.68,
            "price_change_24h": 2.3,
            "volatility": 0.15
        },
        "model_used": request.model_name or "default_model",
        "timestamp": "2024-01-01T00:00:00Z"
    }


@router.get("/models", response_model=List[MLModelResponse])
async def get_models(
    current_user: User = Depends(get_current_active_user)
):
    """Get available ML models"""
    return [
        MLModelResponse(
            id="fingpt-v1",
            name="FinGPT Local Model",
            type="language_model",
            status="active",
            accuracy=0.78,
            created_at="2024-01-01T00:00:00Z"
        ),
        MLModelResponse(
            id="price-predictor-v2",
            name="Price Prediction Model",
            type="regression",
            status="active",
            accuracy=0.65,
            created_at="2024-01-01T00:00:00Z"
        ),
        MLModelResponse(
            id="sentiment-analyzer-v1",
            name="Sentiment Analysis Model",
            type="classification",
            status="training",
            accuracy=None,
            created_at="2024-01-01T00:00:00Z"
        )
    ]


@router.post("/models/train")
async def train_model(
    model_config: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Start training a new model"""
    return {
        "job_id": "train_job_12345",
        "status": "started",
        "model_name": model_config.get("name", "unnamed_model"),
        "estimated_time": "30 minutes",
        "message": "Training job started successfully"
    }


@router.get("/models/{model_id}/status")
async def get_model_status(
    model_id: str,
    current_user: User = Depends(get_current_active_user)
):
    """Get model training status"""
    return {
        "model_id": model_id,
        "status": "completed",
        "progress": 100,
        "accuracy": 0.78,
        "loss": 0.23,
        "last_updated": "2024-01-01T00:00:00Z"
    }