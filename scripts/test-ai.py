#!/usr/bin/env python3
"""
Test script for local FinGPT model
Tests various AI capabilities and performance on RTX 4060
"""

import asyncio
import json
import time
import httpx
import argparse
from typing import Dict, Any

class AITester:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.client = httpx.AsyncClient(timeout=300.0)  # 5 minutes timeout
        
    async def test_health(self) -> Dict[str, Any]:
        """Test service health"""
        print("🏥 Testing service health...")
        response = await self.client.get(f"{self.base_url}/health")
        health_data = response.json()
        
        print(f"   Status: {health_data['status']}")
        print(f"   GPU Available: {health_data['gpu_available']}")
        if health_data['gpu_available']:
            print(f"   GPU: {health_data['gpu_name']}")
            memory_gb = health_data['gpu_memory_total'] / (1024**3)
            allocated_gb = health_data['gpu_memory_allocated'] / (1024**3)
            print(f"   Memory: {allocated_gb:.1f}GB / {memory_gb:.1f}GB")
        
        print(f"   Models Loaded: {health_data['models_loaded']}")
        print(f"   Uptime: {health_data['uptime']:.1f}s")
        
        return health_data
        
    async def test_basic_generation(self) -> Dict[str, Any]:
        """Test basic text generation"""
        print("\n🤖 Testing basic text generation...")
        
        request = {
            "prompt": "The future of cryptocurrency is",
            "max_length": 256,
            "temperature": 0.7
        }
        
        start_time = time.time()
        response = await self.client.post(f"{self.base_url}/generate", json=request)
        result = response.json()
        
        print(f"   Prompt: {request['prompt']}")
        print(f"   Generated: {result['content'][:200]}...")
        print(f"   Tokens: {result['tokens_used']}")
        print(f"   Response Time: {result['response_time']:.2f}s")
        print(f"   GPU Memory Used: {result['gpu_memory_used'] / (1024**2):.1f}MB")
        print(f"   Confidence: {result['confidence']:.2f}")
        
        return result
        
    async def test_financial_analysis(self) -> Dict[str, Any]:
        """Test financial analysis capability"""
        print("\n📈 Testing financial analysis...")
        
        request = {
            "symbol": "BTC",
            "market_data": {
                "price": 45000,
                "price_change_24h": 2.5,
                "volume_24h": 25000000000,
                "high_24h": 46000,
                "low_24h": 44000
            },
            "context": "Recent news suggests institutional adoption is increasing"
        }
        
        start_time = time.time()
        response = await self.client.post(f"{self.base_url}/analyze/financial", json=request)
        result = response.json()
        
        print(f"   Symbol: {request['symbol']}")
        print(f"   Analysis: {result['content'][:300]}...")
        print(f"   Tokens: {result['tokens_used']}")
        print(f"   Response Time: {result['response_time']:.2f}s")
        print(f"   GPU Memory Used: {result['gpu_memory_used'] / (1024**2):.1f}MB")
        
        return result
        
    async def test_performance_batch(self, batch_size: int = 5) -> Dict[str, Any]:
        """Test performance with multiple requests"""
        print(f"\n⚡ Testing batch performance ({batch_size} requests)...")
        
        requests = [
            {"prompt": f"Cryptocurrency market analysis #{i+1}:", "max_length": 200}
            for i in range(batch_size)
        ]
        
        start_time = time.time()
        
        # Send requests sequentially (GPU models typically handle one at a time)
        results = []
        for req in requests:
            response = await self.client.post(f"{self.base_url}/generate", json=req)
            results.append(response.json())
        
        total_time = time.time() - start_time
        avg_response_time = sum(r['response_time'] for r in results) / len(results)
        total_tokens = sum(r['tokens_used'] for r in results)
        
        print(f"   Total Time: {total_time:.2f}s")
        print(f"   Average Response Time: {avg_response_time:.2f}s")
        print(f"   Total Tokens: {total_tokens}")
        print(f"   Tokens/Second: {total_tokens / total_time:.1f}")
        
        return {
            "total_time": total_time,
            "avg_response_time": avg_response_time,
            "total_tokens": total_tokens,
            "tokens_per_second": total_tokens / total_time
        }
        
    async def get_model_info(self) -> Dict[str, Any]:
        """Get detailed model information"""
        print("\n🔍 Getting model information...")
        
        response = await self.client.get(f"{self.base_url}/model/info")
        info = response.json()
        
        print("   FinGPT Status:")
        fingpt = info['fingpt']
        for key, value in fingpt.items():
            print(f"     {key}: {value}")
            
        print("   System Info:")
        system = info['system']
        for key, value in system.items():
            print(f"     {key}: {value}")
            
        if info['gpu']:
            print("   GPU Info:")
            gpu = info['gpu']
            for key, value in gpu.items():
                if key == 'total_memory':
                    print(f"     {key}: {value / (1024**3):.1f}GB")
                else:
                    print(f"     {key}: {value}")
        
        return info
        
    async def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting FinGPT AI Tests")
        print("=" * 40)
        
        try:
            # Health check
            health = await self.test_health()
            if health['status'] != 'healthy':
                print("❌ Service not healthy, aborting tests")
                return
                
            if not health['models_loaded']['fingpt']:
                print("❌ FinGPT not loaded, aborting tests")
                return
            
            # Model info
            await self.get_model_info()
            
            # Basic generation
            await self.test_basic_generation()
            
            # Financial analysis
            await self.test_financial_analysis()
            
            # Performance test
            await self.test_performance_batch(3)
            
            print("\n✅ All tests completed successfully!")
            
        except Exception as e:
            print(f"\n❌ Test failed: {e}")
        finally:
            await self.client.aclose()

async def main():
    parser = argparse.ArgumentParser(description="Test FinGPT AI model")
    parser.add_argument("--url", default="http://localhost:8080", help="ML service URL")
    parser.add_argument("--test", choices=["health", "generate", "financial", "performance", "all"], 
                       default="all", help="Test to run")
    
    args = parser.parse_args()
    
    tester = AITester(args.url)
    
    if args.test == "health":
        await tester.test_health()
    elif args.test == "generate":
        await tester.test_basic_generation()
    elif args.test == "financial":
        await tester.test_financial_analysis()
    elif args.test == "performance":
        await tester.test_performance_batch()
    else:
        await tester.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())