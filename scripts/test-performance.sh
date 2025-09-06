#!/bin/bash

# HTXV2 Performance Testing and Bottleneck Detection Script
# This script performs comprehensive testing to identify performance bottlenecks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BASE_URL=${BASE_URL:-"http://localhost:8000"}
FRONTEND_URL=${FRONTEND_URL:-"http://localhost:3000"}
ML_URL=${ML_URL:-"http://localhost:8080"}

# Test configuration
CONCURRENT_USERS=${CONCURRENT_USERS:-10}
TEST_DURATION=${TEST_DURATION:-60}
RAMP_UP_TIME=${RAMP_UP_TIME:-10}

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking testing prerequisites..."
    
    # Check if services are running
    if ! curl -s "$BASE_URL/health" > /dev/null; then
        log_error "Backend service is not running at $BASE_URL"
        exit 1
    fi
    
    # Check for testing tools
    if ! command -v curl &> /dev/null; then
        log_error "curl is required for API testing"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is required for performance testing"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

test_api_endpoints() {
    log_info "Testing API endpoint performance..."
    
    local test_results_file="/tmp/htxv2_api_test_results.json"
    
    # Create Python script for API testing
    cat > /tmp/test_api_performance.py << 'EOF'
import asyncio
import aiohttp
import time
import json
import sys
from typing import Dict, List

class APIPerformanceTester:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.results = {}
        
    async def test_endpoint(self, session: aiohttp.ClientSession, method: str, 
                           endpoint: str, data: dict = None) -> Dict:
        """Test a single endpoint and measure performance"""
        url = f"{self.base_url}{endpoint}"
        
        start_time = time.time()
        try:
            if method.upper() == "GET":
                async with session.get(url) as response:
                    status = response.status
                    response_time = time.time() - start_time
                    content_length = len(await response.text())
            elif method.upper() == "POST":
                async with session.post(url, json=data) as response:
                    status = response.status
                    response_time = time.time() - start_time
                    content_length = len(await response.text())
            else:
                return {"error": f"Unsupported method: {method}"}
                
            return {
                "status": status,
                "response_time": response_time,
                "content_length": content_length,
                "success": 200 <= status < 300
            }
        except Exception as e:
            return {
                "error": str(e),
                "response_time": time.time() - start_time,
                "success": False
            }
    
    async def run_load_test(self, endpoints: List[Dict], concurrent_users: int = 10, 
                           duration: int = 60):
        """Run load test on multiple endpoints"""
        log_info(f"Running load test with {concurrent_users} concurrent users for {duration}s")
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            start_time = time.time()
            
            # Create tasks for concurrent testing
            for _ in range(concurrent_users):
                for endpoint_config in endpoints:
                    task = asyncio.create_task(
                        self.test_endpoint_continuously(
                            session, endpoint_config, duration, start_time
                        )
                    )
                    tasks.append(task)
            
            # Wait for all tasks to complete
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Process results
            self.process_load_test_results(results, endpoints)
    
    async def test_endpoint_continuously(self, session: aiohttp.ClientSession, 
                                        endpoint_config: Dict, duration: int, 
                                        start_time: float):
        """Test an endpoint continuously for specified duration"""
        endpoint_results = []
        
        while time.time() - start_time < duration:
            result = await self.test_endpoint(
                session, 
                endpoint_config["method"], 
                endpoint_config["endpoint"],
                endpoint_config.get("data")
            )
            endpoint_results.append(result)
            
            # Small delay to prevent overwhelming the server
            await asyncio.sleep(0.1)
        
        return {
            "endpoint": endpoint_config["endpoint"],
            "method": endpoint_config["method"],
            "results": endpoint_results
        }
    
    def process_load_test_results(self, results: List, endpoints: List[Dict]):
        """Process and analyze load test results"""
        for result in results:
            if isinstance(result, Exception):
                continue
                
            endpoint = result["endpoint"]
            method = result["method"]
            endpoint_results = result["results"]
            
            if not endpoint_results:
                continue
            
            # Calculate statistics
            response_times = [r.get("response_time", 0) for r in endpoint_results if r.get("success")]
            success_count = sum(1 for r in endpoint_results if r.get("success"))
            total_requests = len(endpoint_results)
            
            if response_times:
                avg_response_time = sum(response_times) / len(response_times)
                min_response_time = min(response_times)
                max_response_time = max(response_times)
                p95_response_time = sorted(response_times)[int(len(response_times) * 0.95)]
            else:
                avg_response_time = min_response_time = max_response_time = p95_response_time = 0
            
            self.results[f"{method} {endpoint}"] = {
                "total_requests": total_requests,
                "successful_requests": success_count,
                "success_rate": success_count / total_requests if total_requests > 0 else 0,
                "avg_response_time": avg_response_time,
                "min_response_time": min_response_time,
                "max_response_time": max_response_time,
                "p95_response_time": p95_response_time,
                "requests_per_second": success_count / 60 if success_count > 0 else 0
            }
    
    def generate_report(self):
        """Generate performance test report"""
        report = {
            "test_summary": {
                "total_endpoints_tested": len(self.results),
                "test_timestamp": time.time()
            },
            "endpoint_results": self.results,
            "bottleneck_analysis": self.analyze_bottlenecks()
        }
        return report
    
    def analyze_bottlenecks(self):
        """Analyze results to identify potential bottlenecks"""
        bottlenecks = []
        
        for endpoint, stats in self.results.items():
            # Check for slow endpoints (> 2 seconds average)
            if stats["avg_response_time"] > 2.0:
                bottlenecks.append({
                    "type": "slow_response",
                    "endpoint": endpoint,
                    "avg_response_time": stats["avg_response_time"],
                    "severity": "high"
                })
            
            # Check for low success rate (< 95%)
            if stats["success_rate"] < 0.95:
                bottlenecks.append({
                    "type": "low_success_rate",
                    "endpoint": endpoint,
                    "success_rate": stats["success_rate"],
                    "severity": "critical"
                })
            
            # Check for high variance in response times
            if stats["max_response_time"] > stats["avg_response_time"] * 3:
                bottlenecks.append({
                    "type": "high_variance",
                    "endpoint": endpoint,
                    "max_time": stats["max_response_time"],
                    "avg_time": stats["avg_response_time"],
                    "severity": "medium"
                })
        
        return bottlenecks

async def main():
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
    concurrent_users = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    duration = int(sys.argv[3]) if len(sys.argv) > 3 else 60
    
    tester = APIPerformanceTester(base_url)
    
    # Define endpoints to test
    endpoints = [
        {"method": "GET", "endpoint": "/health"},
        {"method": "GET", "endpoint": "/api/v1/data/exchanges"},
        {"method": "GET", "endpoint": "/api/v1/trading/signals"},
        {"method": "GET", "endpoint": "/api/v1/trading/market-data/BTC"},
        {"method": "GET", "endpoint": "/api/v1/data/market-overview"},
        {"method": "POST", "endpoint": "/api/v1/gpt/suggest-prompt", 
         "data": {"context": "test", "purpose": "analysis", "symbol": "BTC"}},
        {"method": "POST", "endpoint": "/api/v1/ml/predict", 
         "data": {"symbol": "BTC", "features": {"rsi": 65, "volume": 1000000}}},
    ]
    
    # Run load test
    await tester.run_load_test(endpoints, concurrent_users, duration)
    
    # Generate and save report
    report = tester.generate_report()
    
    with open("/tmp/htxv2_api_test_results.json", "w") as f:
        json.dump(report, f, indent=2)
    
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    asyncio.run(main())
EOF
    
    # Run the performance test
    log_info "Running API performance test (this may take a few minutes)..."
    python3 /tmp/test_api_performance.py "$BASE_URL" "$CONCURRENT_USERS" "$TEST_DURATION" > "$test_results_file"
    
    # Display results
    log_info "API Performance Test Results:"
    python3 -c "
import json
with open('$test_results_file') as f:
    data = json.load(f)
    
print('\\n=== TEST SUMMARY ===')
print(f'Total endpoints tested: {data[\"test_summary\"][\"total_endpoints_tested\"]}')

print('\\n=== ENDPOINT PERFORMANCE ===')
for endpoint, stats in data['endpoint_results'].items():
    print(f'\\n{endpoint}:')
    print(f'  Success Rate: {stats[\"success_rate\"]:.2%}')
    print(f'  Avg Response Time: {stats[\"avg_response_time\"]:.3f}s')
    print(f'  P95 Response Time: {stats[\"p95_response_time\"]:.3f}s')
    print(f'  Requests/Second: {stats[\"requests_per_second\"]:.1f}')

print('\\n=== BOTTLENECK ANALYSIS ===')
bottlenecks = data['bottleneck_analysis']
if bottlenecks:
    for bottleneck in bottlenecks:
        severity = bottleneck['severity'].upper()
        print(f'[{severity}] {bottleneck[\"type\"]} - {bottleneck[\"endpoint\"]}')
        if 'avg_response_time' in bottleneck:
            print(f'  Average response time: {bottleneck[\"avg_response_time\"]:.3f}s')
        if 'success_rate' in bottleneck:
            print(f'  Success rate: {bottleneck[\"success_rate\"]:.2%}')
else:
    print('No significant bottlenecks detected!')
"
    
    log_success "API performance testing completed"
}

test_database_performance() {
    log_info "Testing database performance..."
    
    # Create database performance test
    cat > /tmp/test_db_performance.py << 'EOF'
import asyncio
import asyncpg
import time
import statistics
import os

async def test_database_performance():
    # Database connection details
    db_url = os.getenv('DATABASE_URL', 'postgresql://htxv2_user:password@localhost:5432/htxv2')
    
    try:
        # Connect to database
        conn = await asyncpg.connect(db_url)
        
        # Test simple query performance
        query_times = []
        for i in range(100):
            start_time = time.time()
            await conn.fetchval('SELECT 1')
            query_times.append(time.time() - start_time)
        
        # Test more complex queries
        complex_query_times = []
        for i in range(10):
            start_time = time.time()
            await conn.fetch('''
                SELECT COUNT(*) as count, 
                       AVG(EXTRACT(EPOCH FROM NOW() - created_at)) as avg_age
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            ''')
            complex_query_times.append(time.time() - start_time)
        
        # Calculate statistics
        simple_avg = statistics.mean(query_times) * 1000  # Convert to ms
        simple_p95 = statistics.quantiles(query_times, n=20)[18] * 1000
        
        complex_avg = statistics.mean(complex_query_times) * 1000
        complex_p95 = statistics.quantiles(complex_query_times, n=10)[8] * 1000
        
        print(f"Database Performance Results:")
        print(f"Simple queries (SELECT 1):")
        print(f"  Average: {simple_avg:.2f}ms")
        print(f"  P95: {simple_p95:.2f}ms")
        print(f"Complex queries:")
        print(f"  Average: {complex_avg:.2f}ms")
        print(f"  P95: {complex_p95:.2f}ms")
        
        # Check for performance issues
        if simple_avg > 10:
            print("WARNING: Simple queries are slow (>10ms average)")
        if complex_avg > 100:
            print("WARNING: Complex queries are slow (>100ms average)")
        
        await conn.close()
        
    except Exception as e:
        print(f"Database test failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_database_performance())
EOF
    
    python3 /tmp/test_db_performance.py
    log_success "Database performance testing completed"
}

test_memory_usage() {
    log_info "Testing memory usage..."
    
    # Check Docker container memory usage
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "htxv2"; then
        log_info "Docker container memory usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -E "(NAME|htxv2|docker)"
    else
        log_warning "No HTXV2 Docker containers found running"
    fi
    
    # System memory usage
    log_info "System memory usage:"
    free -h
    
    log_success "Memory usage analysis completed"
}

test_network_latency() {
    log_info "Testing network latency and connectivity..."
    
    # Test API endpoint latency
    log_info "API endpoint latency:"
    for endpoint in "/health" "/api/v1/data/exchanges" "/api/v1/trading/signals"; do
        latency=$(curl -o /dev/null -s -w "%{time_total}" "$BASE_URL$endpoint" || echo "failed")
        echo "  $endpoint: ${latency}s"
    done
    
    # Test frontend connectivity
    if curl -s "$FRONTEND_URL" > /dev/null; then
        frontend_latency=$(curl -o /dev/null -s -w "%{time_total}" "$FRONTEND_URL")
        echo "  Frontend: ${frontend_latency}s"
    else
        echo "  Frontend: not accessible"
    fi
    
    log_success "Network latency testing completed"
}

generate_recommendations() {
    log_info "Generating performance recommendations..."
    
    cat << 'EOF'

=== PERFORMANCE OPTIMIZATION RECOMMENDATIONS ===

Based on the test results, here are recommendations for improving performance:

1. DATABASE OPTIMIZATION:
   - Add database indexes for frequently queried columns
   - Consider connection pooling for high-concurrency scenarios
   - Monitor slow query logs and optimize problematic queries
   - Consider read replicas for read-heavy workloads

2. API OPTIMIZATION:
   - Implement response caching for frequently requested data
   - Add request rate limiting to prevent abuse
   - Use pagination for large result sets
   - Consider API versioning for backward compatibility

3. INFRASTRUCTURE OPTIMIZATION:
   - Monitor resource usage and scale containers as needed
   - Implement load balancing for high availability
   - Use CDN for static assets and frontend distribution
   - Consider horizontal scaling for API services

4. MONITORING AND ALERTING:
   - Set up comprehensive monitoring with Prometheus/Grafana
   - Implement health checks for all services
   - Create alerts for performance degradation
   - Monitor business metrics and SLA compliance

5. SECURITY CONSIDERATIONS:
   - Implement proper authentication and authorization
   - Use HTTPS in production environments
   - Regular security audits and vulnerability scanning
   - Input validation and sanitization

EOF

    log_success "Recommendations generated"
}

run_all_tests() {
    log_info "Running comprehensive performance testing suite..."
    
    check_prerequisites
    test_api_endpoints
    test_database_performance
    test_memory_usage
    test_network_latency
    generate_recommendations
    
    log_success "All performance tests completed!"
}

show_help() {
    echo "HTXV2 Performance Testing Script"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  api           Test API endpoint performance"
    echo "  database      Test database performance"
    echo "  memory        Test memory usage"
    echo "  network       Test network latency"
    echo "  all           Run all performance tests (default)"
    echo "  help          Show this help message"
    echo
    echo "Options:"
    echo "  --base-url URL         API base URL [default: http://localhost:8000]"
    echo "  --frontend-url URL     Frontend URL [default: http://localhost:3000]"
    echo "  --users N             Concurrent users for load testing [default: 10]"
    echo "  --duration N          Test duration in seconds [default: 60]"
    echo
    echo "Examples:"
    echo "  $0 api --users 20 --duration 120"
    echo "  $0 all --base-url https://api.yourdomain.com"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --frontend-url)
            FRONTEND_URL="$2"
            shift 2
            ;;
        --users)
            CONCURRENT_USERS="$2"
            shift 2
            ;;
        --duration)
            TEST_DURATION="$2"
            shift 2
            ;;
        api|database|memory|network|all|help)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
case "${COMMAND:-all}" in
    api)
        check_prerequisites
        test_api_endpoints
        ;;
    database)
        test_database_performance
        ;;
    memory)
        test_memory_usage
        ;;
    network)
        test_network_latency
        ;;
    all)
        run_all_tests
        ;;
    help)
        show_help
        ;;
    *)
        log_error "Unknown command: ${COMMAND}"
        show_help
        exit 1
        ;;
esac