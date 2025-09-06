#!/bin/bash

# HTXV2 Production Deployment Script
# This script provides a complete deployment solution for the HTXV2 platform

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
DOCKER_DIR="$PROJECT_ROOT/docker"

# Default values
ENVIRONMENT=${ENVIRONMENT:-production}
PROFILE=${PROFILE:-""}
BUILD_ARGS=${BUILD_ARGS:-""}
RECREATE=${RECREATE:-false}

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
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please install Docker Compose v2."
        exit 1
    fi
    
    # Check if running as root in production
    if [ "$ENVIRONMENT" = "production" ] && [ "$EUID" -eq 0 ]; then
        log_warning "Running as root in production is not recommended."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "Prerequisites check passed"
}

setup_environment() {
    log_info "Setting up environment configuration..."
    
    cd "$DOCKER_DIR"
    
    # Check for environment file
    if [ "$ENVIRONMENT" = "production" ]; then
        ENV_FILE=".env.prod"
        EXAMPLE_FILE=".env.prod.example"
    else
        ENV_FILE=".env"
        EXAMPLE_FILE="../backend/.env.example"
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        log_warning "Environment file $ENV_FILE not found."
        if [ -f "$EXAMPLE_FILE" ]; then
            log_info "Copying from example file..."
            cp "$EXAMPLE_FILE" "$ENV_FILE"
            log_warning "Please edit $ENV_FILE with your configuration before continuing."
            exit 1
        else
            log_error "No example environment file found."
            exit 1
        fi
    fi
    
    log_success "Environment configuration ready"
}

build_images() {
    log_info "Building Docker images..."
    
    cd "$DOCKER_DIR"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
        ENV_FILE=".env.prod"
    else
        COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env"
    fi
    
    # Build with cache unless recreate is specified
    BUILD_CMD="docker compose -f $COMPOSE_FILE"
    
    if [ -f "$ENV_FILE" ]; then
        BUILD_CMD="$BUILD_CMD --env-file $ENV_FILE"
    fi
    
    if [ "$PROFILE" != "" ]; then
        BUILD_CMD="$BUILD_CMD --profile $PROFILE"
    fi
    
    if [ "$RECREATE" = "true" ]; then
        BUILD_CMD="$BUILD_CMD build --no-cache $BUILD_ARGS"
    else
        BUILD_CMD="$BUILD_CMD build $BUILD_ARGS"
    fi
    
    log_info "Executing: $BUILD_CMD"
    eval $BUILD_CMD
    
    log_success "Docker images built successfully"
}

setup_volumes() {
    log_info "Setting up volumes and directories..."
    
    # Create necessary directories
    mkdir -p "$DOCKER_DIR/credentials"
    mkdir -p "$DOCKER_DIR/ssl"
    mkdir -p "$DOCKER_DIR/monitoring"
    
    # Set proper permissions
    chmod 600 "$DOCKER_DIR/credentials" 2>/dev/null || true
    chmod 644 "$DOCKER_DIR/ssl" 2>/dev/null || true
    
    log_success "Volumes and directories setup complete"
}

run_health_checks() {
    log_info "Running health checks..."
    
    cd "$DOCKER_DIR"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
        ENV_FILE=".env.prod"
    else
        COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env"
    fi
    
    # Wait for services to be ready
    log_info "Waiting for services to start..."
    sleep 30
    
    # Check database
    log_info "Checking database connection..."
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready; then
        log_success "Database is ready"
    else
        log_error "Database health check failed"
        return 1
    fi
    
    # Check Redis
    log_info "Checking Redis connection..."
    if docker compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping; then
        log_success "Redis is ready"
    else
        log_error "Redis health check failed"
        return 1
    fi
    
    # Check backend API
    log_info "Checking backend API..."
    if curl -f http://localhost:8000/health &>/dev/null; then
        log_success "Backend API is ready"
    else
        log_warning "Backend API health check failed - may still be starting"
    fi
    
    log_success "Health checks completed"
}

deploy_services() {
    log_info "Deploying services..."
    
    cd "$DOCKER_DIR"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
        ENV_FILE=".env.prod"
    else
        COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env"
    fi
    
    DEPLOY_CMD="docker compose -f $COMPOSE_FILE"
    
    if [ -f "$ENV_FILE" ]; then
        DEPLOY_CMD="$DEPLOY_CMD --env-file $ENV_FILE"
    fi
    
    if [ "$PROFILE" != "" ]; then
        DEPLOY_CMD="$DEPLOY_CMD --profile $PROFILE"
    fi
    
    if [ "$RECREATE" = "true" ]; then
        DEPLOY_CMD="$DEPLOY_CMD up -d --force-recreate"
    else
        DEPLOY_CMD="$DEPLOY_CMD up -d"
    fi
    
    log_info "Executing: $DEPLOY_CMD"
    eval $DEPLOY_CMD
    
    log_success "Services deployed successfully"
}

run_migrations() {
    log_info "Running database migrations..."
    
    cd "$DOCKER_DIR"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
    else
        COMPOSE_FILE="docker-compose.yml"
    fi
    
    # Run Alembic migrations
    if docker compose -f "$COMPOSE_FILE" exec -T backend alembic upgrade head; then
        log_success "Database migrations completed"
    else
        log_warning "Database migrations failed or not available"
    fi
}

show_status() {
    log_info "Deployment Status:"
    echo
    
    cd "$DOCKER_DIR"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
    else
        COMPOSE_FILE="docker-compose.yml"
    fi
    
    docker compose -f "$COMPOSE_FILE" ps
    
    echo
    log_info "Service URLs:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend API: http://localhost:8000"
    echo "  API Docs: http://localhost:8000/docs"
    echo "  ML Service: http://localhost:8080"
    
    if [ "$PROFILE" = "monitoring" ]; then
        echo "  Prometheus: http://localhost:9090"
        echo "  Grafana: http://localhost:3001"
    fi
    
    echo
    log_success "Deployment completed successfully!"
}

cleanup() {
    log_info "Cleaning up previous deployment..."
    
    cd "$DOCKER_DIR"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
    else
        COMPOSE_FILE="docker-compose.yml"
    fi
    
    docker compose -f "$COMPOSE_FILE" down
    
    if [ "$RECREATE" = "true" ]; then
        log_warning "Removing volumes (this will delete all data)..."
        docker compose -f "$COMPOSE_FILE" down -v
        docker system prune -f
    fi
    
    log_success "Cleanup completed"
}

show_help() {
    echo "HTXV2 Production Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo
    echo "Commands:"
    echo "  deploy     Deploy the complete HTXV2 stack"
    echo "  build      Build Docker images only"
    echo "  start      Start existing services"
    echo "  stop       Stop running services"
    echo "  restart    Restart all services"
    echo "  status     Show service status"
    echo "  logs       Show service logs"
    echo "  cleanup    Remove containers and optionally volumes"
    echo "  help       Show this help message"
    echo
    echo "Options:"
    echo "  --env ENVIRONMENT      Set environment (development|production) [default: production]"
    echo "  --profile PROFILE      Use specific docker-compose profile (monitoring|proxy)"
    echo "  --recreate            Force recreate containers and rebuild images"
    echo "  --no-cache            Build images without cache"
    echo
    echo "Examples:"
    echo "  $0 deploy                                 # Deploy production environment"
    echo "  $0 --env development deploy               # Deploy development environment"
    echo "  $0 --profile monitoring deploy            # Deploy with monitoring stack"
    echo "  $0 --recreate deploy                      # Force recreate everything"
    echo "  $0 --env production --profile proxy deploy # Deploy with Nginx proxy"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --recreate)
            RECREATE=true
            shift
            ;;
        --no-cache)
            BUILD_ARGS="--no-cache"
            shift
            ;;
        deploy|build|start|stop|restart|status|logs|cleanup|help)
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
case "${COMMAND:-deploy}" in
    deploy)
        log_info "Starting HTXV2 deployment (Environment: $ENVIRONMENT)"
        check_prerequisites
        setup_environment
        setup_volumes
        build_images
        deploy_services
        run_migrations
        run_health_checks
        show_status
        ;;
    build)
        log_info "Building HTXV2 images"
        check_prerequisites
        setup_environment
        build_images
        ;;
    start)
        log_info "Starting HTXV2 services"
        cd "$DOCKER_DIR"
        if [ "$ENVIRONMENT" = "production" ]; then
            docker compose -f docker-compose.prod.yml up -d
        else
            docker compose up -d
        fi
        ;;
    stop)
        log_info "Stopping HTXV2 services"
        cd "$DOCKER_DIR"
        if [ "$ENVIRONMENT" = "production" ]; then
            docker compose -f docker-compose.prod.yml down
        else
            docker compose down
        fi
        ;;
    restart)
        log_info "Restarting HTXV2 services"
        cd "$DOCKER_DIR"
        if [ "$ENVIRONMENT" = "production" ]; then
            docker compose -f docker-compose.prod.yml restart
        else
            docker compose restart
        fi
        ;;
    status)
        cd "$DOCKER_DIR"
        if [ "$ENVIRONMENT" = "production" ]; then
            docker compose -f docker-compose.prod.yml ps
        else
            docker compose ps
        fi
        ;;
    logs)
        cd "$DOCKER_DIR"
        if [ "$ENVIRONMENT" = "production" ]; then
            docker compose -f docker-compose.prod.yml logs -f
        else
            docker compose logs -f
        fi
        ;;
    cleanup)
        cleanup
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