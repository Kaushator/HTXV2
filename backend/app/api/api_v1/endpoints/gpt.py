from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from app.core.security import get_current_active_user
from app.db.session import get_db
from app.models.user import User

router = APIRouter()


class PromptSuggestionRequest(BaseModel):
    """GPT Prompt suggestion request schema"""
    context: str
    purpose: str  # analysis, strategy, explanation, prediction
    symbol: Optional[str] = None
    data_context: Optional[dict] = None


class PromptSuggestionResponse(BaseModel):
    """GPT Prompt suggestion response schema"""
    suggested_prompts: List[str]
    context_analysis: str
    recommended_prompt: str
    parameters: dict


class MarketAnalysisRequest(BaseModel):
    """Market analysis request schema"""
    symbol: str
    timeframe: str = "24h"
    analysis_depth: str = "standard"  # basic, standard, detailed
    include_sentiment: bool = True
    include_technical: bool = True


class MarketAnalysisResponse(BaseModel):
    """Market analysis response schema"""
    symbol: str
    analysis: str
    key_insights: List[str]
    sentiment_score: float
    confidence: float
    timestamp: str


class StrategyRequest(BaseModel):
    """Strategy generation request schema"""
    symbol: str
    risk_tolerance: str = "medium"
    investment_horizon: str = "medium_term"
    capital_amount: Optional[float] = None
    preferences: Optional[dict] = None


class StrategyResponse(BaseModel):
    """Strategy response schema"""
    strategy_name: str
    description: str
    entry_conditions: List[str]
    exit_conditions: List[str]
    risk_management: dict
    expected_return: Optional[float]
    risk_score: float


class SignalExplanationRequest(BaseModel):
    """Signal explanation request schema"""
    signal_id: Optional[int] = None
    signal_data: Optional[dict] = None
    explanation_level: str = "detailed"  # basic, detailed, technical


@router.post("/suggest-prompt", response_model=PromptSuggestionResponse)
async def suggest_prompt(
    request: PromptSuggestionRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate intelligent prompt suggestions for GPT analysis"""
    
    # Analyze context and generate appropriate prompts
    purpose_templates = {
        "analysis": [
            f"Analyze the current market conditions for {request.symbol or 'the cryptocurrency market'} and provide insights on price movement, volume trends, and key technical indicators.",
            f"What are the key factors driving {request.symbol or 'cryptocurrency'} price action today? Include both technical and fundamental analysis.",
            f"Perform a comprehensive analysis of {request.symbol or 'the market'} including trend analysis, support/resistance levels, and market sentiment."
        ],
        "strategy": [
            f"Create a trading strategy for {request.symbol or 'cryptocurrency trading'} based on current market conditions and risk management principles.",
            f"Design an investment approach for {request.symbol or 'crypto portfolio'} considering market volatility and trend analysis.",
            f"Develop a risk-adjusted trading plan for {request.symbol or 'the current market'} with clear entry and exit criteria."
        ],
        "explanation": [
            f"Explain the reasoning behind the recent price movement in {request.symbol or 'cryptocurrency markets'} using technical and fundamental analysis.",
            f"Break down the key factors that led to the current market signal for {request.symbol or 'this asset'}.",
            f"Provide a detailed explanation of why {request.symbol or 'this cryptocurrency'} is showing the current technical pattern."
        ],
        "prediction": [
            f"Based on current technical indicators and market trends, what is the likely price direction for {request.symbol or 'cryptocurrency'} in the next 24-48 hours?",
            f"Analyze the probability of {request.symbol or 'this asset'} reaching key price levels based on historical patterns and current momentum.",
            f"Forecast potential price targets for {request.symbol or 'the market'} using technical analysis and market structure."
        ]
    }
    
    suggested_prompts = purpose_templates.get(request.purpose, purpose_templates["analysis"])
    
    # Select the most appropriate prompt based on context
    if request.symbol:
        recommended = suggested_prompts[0]  # Symbol-specific prompts
    else:
        recommended = suggested_prompts[1]  # General market prompts
    
    return PromptSuggestionResponse(
        suggested_prompts=suggested_prompts,
        context_analysis=f"Context indicates {request.purpose} purpose for {request.symbol or 'general market'}. Recommended prompt optimized for current market conditions.",
        recommended_prompt=recommended,
        parameters={
            "temperature": 0.7,
            "max_tokens": 1000,
            "focus_areas": ["technical_analysis", "market_sentiment", "risk_assessment"],
            "data_points_needed": ["price_history", "volume_data", "news_sentiment"]
        }
    )


@router.post("/analyze-market", response_model=MarketAnalysisResponse)
async def analyze_market(
    request: MarketAnalysisRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate AI-powered market analysis"""
    
    # This would integrate with actual LLM services (FinGPT, OpenAI, etc.)
    analysis = f"""
    Market Analysis for {request.symbol.upper()}:
    
    Technical Analysis:
    - Current trend shows bullish momentum with price above key moving averages
    - RSI indicates potential for continuation with current reading at 58
    - Volume profile supports the current price action
    
    Market Structure:
    - Key support level at $48,000 remains intact
    - Resistance zone identified at $52,500-$53,000
    - Overall market sentiment remains cautiously optimistic
    
    Recommendation: Consider accumulation on pullbacks to support levels with strict risk management.
    """
    
    key_insights = [
        "Strong technical momentum confirmed by volume",
        "Support levels holding well during recent volatility",
        "Market sentiment improving based on on-chain metrics",
        "Institutional interest remains elevated"
    ]
    
    return MarketAnalysisResponse(
        symbol=request.symbol.upper(),
        analysis=analysis.strip(),
        key_insights=key_insights,
        sentiment_score=0.68,  # 0.0 = very bearish, 1.0 = very bullish
        confidence=0.75,
        timestamp=datetime.utcnow().isoformat()
    )


@router.post("/generate-strategy", response_model=StrategyResponse)
async def generate_strategy(
    request: StrategyRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate AI-powered trading strategy"""
    
    risk_multipliers = {
        "low": 0.5,
        "medium": 1.0,
        "high": 1.5
    }
    
    multiplier = risk_multipliers.get(request.risk_tolerance, 1.0)
    
    return StrategyResponse(
        strategy_name=f"Momentum Breakout Strategy - {request.symbol.upper()}",
        description=f"A {request.risk_tolerance} risk strategy designed for {request.investment_horizon} trading of {request.symbol.upper()} based on technical momentum and volume confirmation.",
        entry_conditions=[
            "Price breaks above recent consolidation range with volume confirmation",
            "RSI between 45-70 indicating healthy momentum",
            "Volume exceeds 20-day average by at least 50%",
            "Overall market sentiment neutral to positive"
        ],
        exit_conditions=[
            "Take profit at 2-3% above entry for medium-term positions",
            "Stop loss at 1.5% below entry to maintain risk-reward ratio",
            "Exit if RSI exceeds 80 indicating overbought conditions",
            "Close position if overall market turns bearish"
        ],
        risk_management={
            "position_size": f"{2 * multiplier}% of portfolio",
            "max_drawdown": f"{5 * multiplier}%",
            "risk_per_trade": f"{1 * multiplier}%",
            "correlation_limit": "Max 30% in correlated assets"
        },
        expected_return=8.5 * multiplier,
        risk_score=0.4 * multiplier
    )


@router.post("/explain-signal")
async def explain_signal(
    request: SignalExplanationRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Explain trading signals using AI"""
    
    explanation = {
        "signal_summary": "BUY signal generated for BTC based on technical convergence",
        "reasoning": {
            "technical_factors": [
                "Moving average crossover detected (50 EMA above 200 EMA)",
                "RSI showing bullish divergence with price",
                "Volume breakout confirms momentum shift",
                "Support level successfully retested and held"
            ],
            "market_factors": [
                "Overall crypto market showing strength",
                "Bitcoin dominance stable around key level",
                "Institutional interest indicators positive",
                "Correlation with risk assets improving"
            ],
            "risk_factors": [
                "Approaching key resistance zone",
                "Market volatility elevated",
                "Regulatory sentiment remains uncertain"
            ]
        },
        "confidence_breakdown": {
            "technical_score": 0.78,
            "market_score": 0.65,
            "sentiment_score": 0.72,
            "overall_confidence": 0.72
        },
        "actionable_insights": [
            "Entry recommended above $49,500 with confirmation",
            "Initial target at $52,000-$52,500 range",
            "Stop loss suggested below $48,000",
            "Monitor volume for continuation signals"
        ],
        "timestamp": datetime.utcnow().isoformat()
    }
    
    return explanation