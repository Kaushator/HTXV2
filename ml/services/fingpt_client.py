import asyncio
import time
from typing import Optional, Dict, Any
import structlog
import torch
from dataclasses import dataclass

from fingpt.model_loader import FinGPTLoader

logger = structlog.get_logger(__name__)

@dataclass
class FinGPTResponse:
    """Response from FinGPT model"""
    content: str
    tokens_used: int
    response_time: float
    gpu_memory_used: int
    confidence: float = 0.8  # Default confidence for local model

class FinGPTClient:
    """Client for local FinGPT model inference"""
    
    def __init__(self):
        self.loader = FinGPTLoader()
        self.is_initialized = False
        self.is_healthy = False
        
    async def initialize(self) -> bool:
        """Initialize the FinGPT model"""
        try:
            logger.info("Initializing FinGPT client...")
            success = await self.loader.load_model()
            self.is_initialized = success
            self.is_healthy = success
            
            if success:
                logger.info("FinGPT client initialized successfully")
            else:
                logger.error("Failed to initialize FinGPT client")
                
            return success
        except Exception as e:
            logger.error(f"Error initializing FinGPT client: {e}")
            self.is_healthy = False
            return False
    
    async def health_check(self) -> bool:
        """Check if the model is healthy"""
        if not self.is_initialized:
            return False
        
        try:
            # Simple test generation
            test_response = await self.generate(
                prompt="Hello",
                max_length=50
            )
            self.is_healthy = len(test_response.content) > 0
            return self.is_healthy
        except Exception as e:
            logger.error(f"FinGPT health check failed: {e}")
            self.is_healthy = False
            return False
    
    async def generate(self, 
                      prompt: str, 
                      max_length: int = 512,
                      temperature: float = 0.7,
                      **kwargs) -> FinGPTResponse:
        """Generate text using FinGPT"""
        if not self.is_initialized:
            raise RuntimeError("FinGPT client not initialized")
        
        start_time = time.time()
        
        try:
            # Get GPU memory before inference
            initial_memory = torch.cuda.memory_allocated() if torch.cuda.is_available() else 0
            
            # Generate text
            generated_text = await self.loader.generate_text(
                prompt=prompt,
                max_length=max_length,
                temperature=temperature,
                **kwargs
            )
            
            # Calculate metrics
            response_time = time.time() - start_time
            final_memory = torch.cuda.memory_allocated() if torch.cuda.is_available() else 0
            gpu_memory_used = final_memory - initial_memory
            
            # Estimate tokens (rough approximation)
            tokens_used = len(generated_text.split()) * 1.3  # Approximate token count
            
            return FinGPTResponse(
                content=generated_text,
                tokens_used=int(tokens_used),
                response_time=response_time,
                gpu_memory_used=gpu_memory_used,
                confidence=0.8
            )
            
        except Exception as e:
            logger.error(f"Error generating with FinGPT: {e}")
            raise
    
    async def generate_financial_analysis(self, 
                                        symbol: str,
                                        market_data: Dict[str, Any],
                                        context: Optional[str] = None) -> FinGPTResponse:
        """Generate financial analysis for a cryptocurrency"""
        
        # Prepare financial prompt
        prompt = self._build_financial_prompt(symbol, market_data, context)
        
        return await self.generate(
            prompt=prompt,
            max_length=1024,
            temperature=0.6  # Lower temperature for financial analysis
        )
    
    def _build_financial_prompt(self, 
                               symbol: str, 
                               market_data: Dict[str, Any],
                               context: Optional[str] = None) -> str:
        """Build a financial analysis prompt"""
        
        price = market_data.get("price", 0)
        change_24h = market_data.get("price_change_24h", 0)
        volume = market_data.get("volume_24h", 0)
        
        prompt = f"""
Financial Analysis Request for {symbol}

Current Market Data:
- Price: ${price:,.2f}
- 24h Change: {change_24h:+.2f}%
- 24h Volume: ${volume:,.0f}

Context: {context or "No additional context provided"}

Please provide a comprehensive financial analysis including:
1. Technical analysis of the current price action
2. Market sentiment assessment
3. Key support and resistance levels
4. Risk factors to consider
5. Short-term outlook (1-7 days)

Analysis:"""
        
        return prompt.strip()
    
    def get_status(self) -> Dict[str, Any]:
        """Get client status information"""
        model_info = self.loader.get_model_info() if self.is_initialized else {}
        
        return {
            "initialized": self.is_initialized,
            "healthy": self.is_healthy,
            "gpu_available": torch.cuda.is_available(),
            "gpu_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
            "gpu_memory_total": torch.cuda.get_device_properties(0).total_memory if torch.cuda.is_available() else 0,
            "gpu_memory_allocated": torch.cuda.memory_allocated() if torch.cuda.is_available() else 0,
            "model_info": model_info
        }

# Global instance
fingpt_client = FinGPTClient()

async def initialize_fingpt():
    """Initialize the global FinGPT client"""
    return await fingpt_client.initialize()

async def get_fingpt_client() -> FinGPTClient:
    """Get the initialized FinGPT client"""
    if not fingpt_client.is_initialized:
        await fingpt_client.initialize()
    return fingpt_client