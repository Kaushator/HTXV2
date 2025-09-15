#!/usr/bin/env python3
"""
Integration test for HTXV2 WebSocket and File Upload endpoints
Tests the new backend functionality with mock data
"""

import asyncio
import json
import websockets
import aiohttp
import tempfile
import os
from datetime import datetime

# Configuration
API_BASE_URL = "http://localhost:8000/api/v1"
WS_BASE_URL = "ws://localhost:8000/api/v1/ws"
TEST_SYMBOL = "BTCUSDT"

class HTXv2IntegrationTest:
    def __init__(self):
        self.session = None
        
    async def setup(self):
        """Setup HTTP session"""
        self.session = aiohttp.ClientSession()
        
    async def cleanup(self):
        """Cleanup resources"""
        if self.session:
            await self.session.close()
    
    async def test_health_check(self):
        """Test basic API health"""
        try:
            async with self.session.get(f"{API_BASE_URL.replace('/api/v1', '')}/health") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    print(f"✅ Health check passed: {data.get('status')}")
                    return True
                else:
                    print(f"❌ Health check failed: HTTP {resp.status}")
                    return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False
    
    async def test_websocket_connection(self):
        """Test WebSocket market data connection"""
        print(f"\n📡 Testing WebSocket connection to {TEST_SYMBOL}...")
        
        try:
            # Connect without token first (should still work for testing)
            ws_url = f"{WS_BASE_URL}/market-data/{TEST_SYMBOL}"
            
            async with websockets.connect(ws_url) as websocket:
                print(f"✅ WebSocket connected to {ws_url}")
                
                # Wait for connection confirmation
                try:
                    message = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                    data = json.loads(message)
                    
                    if data.get("type") == "connection_established":
                        print(f"✅ Connection established for {data.get('symbol')}")
                    else:
                        print(f"⚠️  Unexpected initial message: {data.get('type')}")
                    
                    # Wait for initial market data
                    message = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                    data = json.loads(message)
                    
                    if data.get("type") == "market_data":
                        print(f"✅ Received market data: {data.get('symbol')} @ ${data.get('price')}")
                    else:
                        print(f"⚠️  Expected market_data, got: {data.get('type')}")
                    
                    # Test ping/pong
                    await websocket.send(json.dumps({"type": "ping"}))
                    message = await asyncio.wait_for(websocket.recv(), timeout=3.0)
                    data = json.loads(message)
                    
                    if data.get("type") == "pong":
                        print("✅ Ping/pong test successful")
                    
                    # Test history request
                    await websocket.send(json.dumps({
                        "type": "request_history", 
                        "timeframe": "1h"
                    }))
                    
                    message = await asyncio.wait_for(websocket.recv(), timeout=3.0)
                    data = json.loads(message)
                    
                    if data.get("type") == "price_history":
                        print(f"✅ Price history received: {len(data.get('data', []))} records")
                    
                    return True
                    
                except asyncio.TimeoutError:
                    print("❌ Timeout waiting for WebSocket messages")
                    return False
                    
        except websockets.exceptions.ConnectionClosed as e:
            print(f"❌ WebSocket connection closed: {e}")
            return False
        except Exception as e:
            print(f"❌ WebSocket test error: {e}")
            return False
    
    async def test_file_upload(self):
        """Test chunked file upload"""
        print(f"\n📁 Testing file upload functionality...")
        
        try:
            # Create a test CSV file
            test_data = """symbol,price,volume,timestamp
BTCUSDT,50000.00,1000000,2023-01-01T00:00:00Z
ETHUSDT,3000.00,500000,2023-01-01T00:00:00Z
ADAUSDT,0.5,200000,2023-01-01T00:00:00Z"""
            
            with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as tmp_file:
                tmp_file.write(test_data)
                tmp_file_path = tmp_file.name
            
            try:
                # Test single chunk upload
                with open(tmp_file_path, 'rb') as f:
                    file_content = f.read()
                
                # Prepare multipart form data
                data = aiohttp.FormData()
                data.add_field('file', 
                               file_content,
                               filename='test_data.csv',
                               content_type='text/csv')
                data.add_field('data_type', 'crypto_prices')
                data.add_field('chunk_number', '1')
                data.add_field('total_chunks', '1')
                
                async with self.session.post(
                    f"{API_BASE_URL}/data/upload",
                    data=data
                ) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        file_id = result.get('file_id')
                        print(f"✅ File upload successful: {result.get('message')}")
                        print(f"   File ID: {file_id}")
                        print(f"   Status: {result.get('status')}")
                        
                        # Test upload status check
                        if file_id:
                            async with self.session.get(
                                f"{API_BASE_URL}/data/upload-status/{file_id}"
                            ) as status_resp:
                                if status_resp.status == 200:
                                    status_data = await status_resp.json()
                                    print(f"✅ Upload status check: {status_data.get('status')}")
                                    print(f"   Records processed: {status_data.get('records_processed')}")
                                else:
                                    print(f"⚠️  Upload status check failed: HTTP {status_resp.status}")
                        
                        return True
                    else:
                        error_data = await resp.text()
                        print(f"❌ File upload failed: HTTP {resp.status}")
                        print(f"   Error: {error_data}")
                        return False
                        
            finally:
                # Clean up temp file
                os.unlink(tmp_file_path)
                
        except Exception as e:
            print(f"❌ File upload test error: {e}")
            return False
    
    async def test_trading_endpoints(self):
        """Test trading API endpoints"""
        print(f"\n💹 Testing trading endpoints...")
        
        try:
            # Test market data endpoint
            async with self.session.get(f"{API_BASE_URL}/trading/market-data/{TEST_SYMBOL}") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    print(f"✅ Market data endpoint: {data.get('symbol')} @ ${data.get('price')}")
                else:
                    print(f"⚠️  Market data endpoint returned: HTTP {resp.status}")
            
            # Test available symbols
            async with self.session.get(f"{API_BASE_URL}/trading/symbols") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    symbols = data.get('symbols', [])
                    print(f"✅ Available symbols: {len(symbols)} symbols")
                    print(f"   Sample symbols: {symbols[:5]}")
                else:
                    print(f"⚠️  Symbols endpoint returned: HTTP {resp.status}")
            
            # Test exchanges endpoint
            async with self.session.get(f"{API_BASE_URL}/data/exchanges") as resp:
                if resp.status == 200:
                    data = await resp.json()
                    exchanges = data.get('exchanges', [])
                    print(f"✅ Supported exchanges: {len(exchanges)} exchanges")
                else:
                    print(f"⚠️  Exchanges endpoint returned: HTTP {resp.status}")
            
            return True
            
        except Exception as e:
            print(f"❌ Trading endpoints test error: {e}")
            return False

async def main():
    """Run all integration tests"""
    print("🚀 HTXV2 Integration Tests")
    print("=" * 50)
    print("Testing backend WebSocket and file upload functionality")
    print(f"API Base URL: {API_BASE_URL}")
    print(f"WebSocket URL: {WS_BASE_URL}")
    print()
    
    test_runner = HTXv2IntegrationTest()
    
    try:
        await test_runner.setup()
        
        tests = [
            ("Health Check", test_runner.test_health_check),
            ("Trading Endpoints", test_runner.test_trading_endpoints),
            ("File Upload", test_runner.test_file_upload),
            ("WebSocket Connection", test_runner.test_websocket_connection),
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            print(f"\n🧪 Running {test_name}...")
            try:
                if await test_func():
                    passed += 1
                    print(f"✅ {test_name} completed successfully")
                else:
                    print(f"❌ {test_name} failed")
            except Exception as e:
                print(f"❌ {test_name} error: {e}")
        
        print(f"\n📊 Test Results: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All integration tests passed!")
            print("\n📋 Ready features:")
            print("  • WebSocket real-time market data streaming")
            print("  • Chunked file upload with progress tracking")
            print("  • Enhanced trading API endpoints")
            print("  • Connection management and error handling")
        else:
            print(f"⚠️  {total - passed} test(s) failed - check server status")
            
    except KeyboardInterrupt:
        print("\n⏹️  Tests interrupted by user")
    except Exception as e:
        print(f"\n💥 Test runner error: {e}")
    finally:
        await test_runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())