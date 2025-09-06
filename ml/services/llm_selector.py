import asyncio
from typing import Optional, Dict, Any, List
from enum import Enum
import structlog
from dataclasses import dataclass

from services.fingpt_client import FinGPTClient
from services.vertex_ai_client import VertexAIClient
from services.openai_client import OpenAIClient

logger = structlog.get_logger(__name__)


class LLMProvider(Enum):
    """Available LLM providers"""
    FINGPT = "fingpt"
    VERTEX_AI = "vertex_ai"
    OPENAI = "openai"


@dataclass
class LLMResponse:
    """LLM response structure"""
    content: str
    provider: LLMProvider
    confidence: float
    tokens_used: int
    response_time: float
    metadata: Dict[str, Any]


class LLMSelector:
    """Intelligent LLM provider selection and fallback logic"""
    
    def __init__(self):
        self.providers = {
            LLMProvider.FINGPT: FinGPTClient(),
            LLMProvider.VERTEX_AI: VertexAIClient(),
            LLMProvider.OPENAI: OpenAIClient()
        }
        
        # Provider priority and selection logic
        self.provider_priority = [
            LLMProvider.FINGPT,      # Fastest, private, free
            LLMProvider.VERTEX_AI,   # GCP native, good performance
            LLMProvider.OPENAI       # Highest quality, fallback
        ]
        
        self.provider_health = {
            provider: True for provider in self.provider_priority
        }
    
    async def select_provider(self, 
                            query_type: str = "general",
                            quality_preference: str = "balanced") -> LLMProvider:
        """Select the best provider based on query type and preferences"""
        
        # Quality preference mapping
        if quality_preference == "speed":
            priority = [LLMProvider.FINGPT, LLMProvider.VERTEX_AI, LLMProvider.OPENAI]
        elif quality_preference == "quality":
            priority = [LLMProvider.OPENAI, LLMProvider.VERTEX_AI, LLMProvider.FINGPT]
        else:  # balanced
            priority = self.provider_priority
        
        # Query type specific selection
        if query_type == "financial_analysis":
            # FinGPT is optimized for financial tasks
            priority = [LLMProvider.FINGPT, LLMProvider.VERTEX_AI, LLMProvider.OPENAI]
        elif query_type == "general_conversation":
            # OpenAI excels at general conversation
            priority = [LLMProvider.OPENAI, LLMProvider.VERTEX_AI, LLMProvider.FINGPT]
        
        # Select first healthy provider
        for provider in priority:
            if self.provider_health.get(provider, False):
                return provider
        
        # Fallback to any available provider
        for provider in self.providers:
            if self.provider_health.get(provider, False):
                logger.warning(f"Using fallback provider: {provider}")
                return provider
        
        raise Exception("No healthy LLM providers available")
    
    async def generate_response(self,
                              prompt: str,
                              context: Optional[str] = None,
                              query_type: str = "general",
                              quality_preference: str = "balanced",
                              max_tokens: int = 1000) -> LLMResponse:
        """Generate response with automatic provider selection and fallback"""
        
        selected_provider = await self.select_provider(query_type, quality_preference)
        
        try:
            return await self._call_provider(
                selected_provider, prompt, context, max_tokens
            )
        except Exception as e:
            logger.warning(f"Provider {selected_provider} failed: {e}. Trying fallback.")
            
            # Mark provider as unhealthy temporarily
            self.provider_health[selected_provider] = False
            
            # Try next available provider
            for provider in self.provider_priority:
                if provider != selected_provider and self.provider_health.get(provider, False):
                    try:
                        return await self._call_provider(
                            provider, prompt, context, max_tokens
                        )
                    except Exception as fallback_error:
                        logger.warning(f"Fallback provider {provider} also failed: {fallback_error}")
                        continue
            
            raise Exception("All LLM providers failed")
    
    async def _call_provider(self,
                           provider: LLMProvider,
                           prompt: str,
                           context: Optional[str] = None,
                           max_tokens: int = 1000) -> LLMResponse:
        """Call specific provider"""
        
        client = self.providers[provider]
        
        if context:
            full_prompt = f"Context: {context}\n\nQuestion: {prompt}"
        else:
            full_prompt = prompt
        
        start_time = asyncio.get_event_loop().time()
        
        try:
            response = await client.generate(
                prompt=full_prompt,
                max_tokens=max_tokens
            )
            
            end_time = asyncio.get_event_loop().time()
            response_time = end_time - start_time
            
            return LLMResponse(
                content=response.content,
                provider=provider,
                confidence=response.confidence,
                tokens_used=response.tokens_used,
                response_time=response_time,
                metadata=response.metadata
            )
            
        except Exception as e:
            logger.error(f"Provider {provider} call failed: {e}")
            raise
    
    async def generate_trading_analysis(self,
                                      symbol: str,
                                      market_data: Dict[str, Any],
                                      news_context: Optional[str] = None) -> LLMResponse:
        """Generate trading analysis for a specific cryptocurrency"""
        
        prompt = f"""Analyze the trading opportunity for {symbol} based on the following market data:
        
Price: ${market_data.get('price', 'N/A')}
24h Change: {market_data.get('price_change_24h', 'N/A')}%
24h Volume: ${market_data.get('volume_24h', 'N/A'):,}
24h High: ${market_data.get('high_24h', 'N/A')}
24h Low: ${market_data.get('low_24h', 'N/A')}

Please provide:
1. Technical analysis summary
2. Key support and resistance levels
3. Trading recommendation (Buy/Hold/Sell)
4. Risk assessment
5. Price targets (if bullish)

Keep the analysis concise and actionable."""
        
        return await self.generate_response(
            prompt=prompt,
            context=news_context,
            query_type="financial_analysis",
            quality_preference="balanced"
        )
    
    async def health_check(self) -> Dict[LLMProvider, bool]:
        """Check health of all providers"""
        health_status = {}
        
        for provider in self.providers:
            try:
                client = self.providers[provider]
                # Simple health check with minimal prompt
                await client.generate("Hello", max_tokens=10)
                health_status[provider] = True
                self.provider_health[provider] = True
            except Exception as e:
                logger.warning(f"Health check failed for {provider}: {e}")
                health_status[provider] = False
                self.provider_health[provider] = False
        
        return health_status


# Global instance
llm_selector = LLMSelector()


async def main():
    """Test the LLM selector"""
    selector = LLMSelector()
    
    # Test health check
    health = await selector.health_check()
    print("Provider health:", health)
    
    # Test trading analysis
    market_data = {
        "price": 45000,
        "price_change_24h": 2.5,
        "volume_24h": 1000000000,
        "high_24h": 46000,
        "low_24h": 44000
    }
    
    try:
        response = await selector.generate_trading_analysis("BTC", market_data)
        print(f"Provider: {response.provider}")
        print(f"Response: {response.content}")
        print(f"Confidence: {response.confidence}")
        print(f"Response time: {response.response_time:.2f}s")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    asyncio.run(main())