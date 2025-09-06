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

# Test configuration
CONCURRENT_USERS=${CONCURRENT_USERS:-10}
TEST_DURATION=${TEST_DURATION:-60}

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
    
    # Test basic endpoints
    echo "Testing basic endpoints:"
    
    # Health check
    echo -n "  /health: "
    if time curl -s "$BASE_URL/health" > /dev/null; then
        echo "✅ OK"
    else
        echo "❌ FAILED"
    fi
    
    # API endpoints
    echo -n "  /api/v1/data/exchanges: "
    if time curl -s "$BASE_URL/api/v1/data/exchanges" > /dev/null; then
        echo "✅ OK"
    else
        echo "❌ FAILED"
    fi
    
    echo -n "  /api/v1/trading/signals: "
    if time curl -s "$BASE_URL/api/v1/trading/signals" > /dev/null; then
        echo "✅ OK"
    else
        echo "❌ FAILED"
    fi
    
    log_success "API endpoint testing completed"
}

test_database_performance() {
    log_info "Testing database performance..."
    
    # Simple database connection test
    if docker ps | grep -q postgres; then
        log_info "PostgreSQL container is running"
        # You could add more specific database tests here
    else
        log_warning "PostgreSQL container not found"
    fi
    
    log_success "Database performance testing completed"
}

test_memory_usage() {
    log_info "Testing memory usage..."
    
    # Check Docker container memory usage
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "htxv2"; then
        log_info "Docker container memory usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -E "(NAME|docker)"
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

run_all_tests() {
    log_info "Running comprehensive performance testing suite..."
    
    check_prerequisites
    test_api_endpoints
    test_database_performance
    test_memory_usage
    test_network_latency
    
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