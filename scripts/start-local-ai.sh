#!/bin/bash

# HTXV2 Local AI Environment Startup Script
# For RTX 4060 + WSL2 + Docker Desktop

set -e

echo "🚀 Starting HTXV2 Local AI Environment"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if running in WSL2
if ! grep -q "microsoft" /proc/version 2>/dev/null; then
    print_warning "Not running in WSL2. Some optimizations may not apply."
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install Docker Desktop."
    exit 1
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose not found. Please update Docker Desktop."
    exit 1
fi

# Check GPU support
print_status "Checking GPU support..."
if docker run --rm --gpus all nvidia/cuda:12.1-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    print_success "GPU support confirmed"
    COMPOSE_FILE="docker/docker-compose.gpu.yml"
else
    print_warning "GPU support not available. Running in CPU mode."
    COMPOSE_FILE="docker/docker-compose.yml"
fi
print_status "Using compose file: $COMPOSE_FILE"

# Create necessary directories
print_status "Creating directories..."
mkdir -p ~/fingpt_models
mkdir -p ~/htxv2_data/postgres
mkdir -p ~/htxv2_data/redis
mkdir -p ~/htxv2_data/ml_cache

# Check available memory
AVAILABLE_MEMORY=$(free -g | awk '/^Mem:/{print $7}')
if [ "$AVAILABLE_MEMORY" -lt 50 ]; then
    print_warning "Low available memory (${AVAILABLE_MEMORY}GB). Consider closing other applications."
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker compose -f $COMPOSE_FILE down 2>/dev/null || true

# Pull latest images
print_status "Pulling latest images..."
docker compose -f $COMPOSE_FILE pull

# Build images
print_status "Building images..."
docker compose -f $COMPOSE_FILE build

# Start services
print_status "Starting services..."
docker compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
print_status "Waiting for services to be ready..."

# Function to wait for service
wait_for_service() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service is ready"
            return 0
        fi
        
        print_status "Waiting for $service... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    print_error "$service failed to start within timeout"
    return 1
}

# Wait for database
print_status "Waiting for database..."
sleep 10

# Wait for backend
wait_for_service "Backend API" "http://localhost:8000/health"

# Wait for ML service
wait_for_service "ML Service" "http://localhost:8080/health"

# Wait for frontend
wait_for_service "Frontend" "http://localhost:3000"

# Display status
echo ""
echo "🎉 HTXV2 Local AI Environment is ready!"
echo "======================================"
echo ""
echo "📱 Frontend:      http://localhost:3000"
echo "🔧 Backend API:   http://localhost:8000"
echo "📚 API Docs:      http://localhost:8000/docs"
echo "🤖 ML Service:    http://localhost:8080"
echo ""

# Show GPU status if available
if command -v nvidia-smi &> /dev/null; then
    echo "🎮 GPU Status:"
    nvidia-smi --query-gpu=name,memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv,noheader,nounits | \
    awk -F', ' '{printf "   GPU: %s | Memory: %s/%s MB | Temp: %s°C | Usage: %s%%\n", $1, $2, $3, $4, $5}'
    echo ""
fi

# Show service status
echo "📊 Service Status:"
docker compose -f $COMPOSE_FILE ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "💡 Tips:"
echo "   - Monitor GPU usage: watch -n 1 nvidia-smi"
echo "   - View logs: docker compose -f $COMPOSE_FILE logs -f [service]"
echo "   - Stop services: docker compose -f $COMPOSE_FILE down"
echo "   - Restart ML service: docker compose -f $COMPOSE_FILE restart ml-gpu"
echo ""

# Optional: Open browser
if command -v explorer.exe &> /dev/null; then
    read -p "Open frontend in browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        explorer.exe "http://localhost:3000"
    fi
fi

print_success "Setup complete! Happy coding! 🚀"