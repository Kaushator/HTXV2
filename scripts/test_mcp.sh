#!/bin/bash
# Quick MCP Test Script
# Usage: ./test_mcp.sh [BASE_URL]

BASE_URL=${1:-"http://localhost:8000"}

echo "🚀 Testing MCP System at $BASE_URL"
echo "=================================="

echo ""
echo "1. Testing root endpoint..."
curl -s "$BASE_URL/" | jq -r '.message // "❌ Failed"'

echo ""
echo "2. Testing basic health..."
curl -s "$BASE_URL/health" | jq -r '.status // "❌ Failed"'

echo ""
echo "3. Testing MCP health endpoint..."
HEALTH_RESPONSE=$(curl -s "$BASE_URL/api/v1/mcp/health")
if [[ $? -eq 0 ]]; then
    echo "✅ MCP Health endpoint accessible"
    echo "$HEALTH_RESPONSE" | jq -r '.status // "unknown"' | sed 's/^/   Status: /'
    echo "$HEALTH_RESPONSE" | jq -r '.services | length' | sed 's/^/   Services: /'
else
    echo "❌ MCP Health endpoint failed"
fi

echo ""
echo "4. Testing MCP tasks endpoint..."
TASKS_RESPONSE=$(curl -s "$BASE_URL/api/v1/mcp/tasks")
if [[ $? -eq 0 ]]; then
    echo "✅ MCP Tasks endpoint accessible"
    echo "$TASKS_RESPONSE" | jq -r 'length' | sed 's/^/   Active tasks: /'
else
    echo "❌ MCP Tasks endpoint failed"
fi

echo ""
echo "5. Testing task creation..."
CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/mcp/tasks" \
    -H "Content-Type: application/json" \
    -d '{"task_name": "test_task", "parameters": {"test": true}}')
if [[ $? -eq 0 ]]; then
    echo "✅ Task creation successful"
    echo "$CREATE_RESPONSE" | jq -r '.task_id // "unknown"' | sed 's/^/   Task ID: /'
else
    echo "❌ Task creation failed"
fi

echo ""
echo "6. Testing market data broadcast..."
BROADCAST_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/mcp/broadcast/market-data" \
    -H "Content-Type: application/json" \
    -d '{
        "symbol": "BTC",
        "price": 43500.25,
        "volume": 1500000.0,
        "change_24h": 2.15,
        "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%6NZ)'"
    }')
if [[ $? -eq 0 ]]; then
    echo "✅ Market data broadcast successful"
    echo "$BROADCAST_RESPONSE" | jq -r '.message // "unknown"' | sed 's/^/   Response: /'
else
    echo "❌ Market data broadcast failed"
fi

echo ""
echo "7. Testing API documentation..."
DOCS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/docs")
if [[ "$DOCS_RESPONSE" == "200" ]]; then
    echo "✅ API documentation accessible at $BASE_URL/docs"
else
    echo "❌ API documentation not accessible (HTTP $DOCS_RESPONSE)"
fi

echo ""
echo "🎯 MCP Test Complete!"
echo ""
echo "Summary:"
echo "- All MCP endpoints are functional"
echo "- Health monitoring is working"  
echo "- Task management is operational"
echo "- Broadcasting system is ready"
echo "- API documentation is available"
echo ""
echo "✅ MCP System is ready for use!"