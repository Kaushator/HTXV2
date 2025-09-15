#!/usr/bin/env bash

# HTXV2 Container Deployment Validation with AI Token Optimization
# Validates both frontend and backend containers with comprehensive checks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
ERRORS=0
WARNINGS=0
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Print functions
print_header() {
    echo -e "${BLUE}$1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
}

print_success() {
    echo -e "  ${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "  ${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

print_error() {
    echo -e "  ${RED}❌ $1${NC}"
    ((ERRORS++))
}

print_info() {
    echo -e "  ${BLUE}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Docker environment
check_docker_environment() {
    print_header "🐳 DOCKER ENVIRONMENT CHECK"
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running"
        return 1
    fi
    
    print_success "Docker is available and running"
    
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not available"
        return 1
    fi
    
    print_success "Docker Compose is available"
    
    # Check Docker Compose configuration
    if docker compose -f docker/docker-compose.yml config --quiet; then
        print_success "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration has errors"
    fi
}

# Token optimization analysis
check_token_optimization() {
    print_header "🤖 TOKEN OPTIMIZATION ANALYSIS"
    
    # Check for large files (>10KB)
    local large_files=()
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
            if [[ $size -gt 10240 ]]; then # 10KB
                large_files+=("$file:$size")
            fi
        fi
    done < <(find . -name "*.py" -o -name "*.ts" -o -name "*.tsx" -print0 2>/dev/null)
    
    if [[ ${#large_files[@]} -gt 0 ]]; then
        print_warning "Found ${#large_files[@]} files larger than 10KB:"
        for file_info in "${large_files[@]}"; do
            file_path="${file_info%:*}"
            file_size="${file_info#*:}"
            size_kb=$((file_size / 1024))
            print_info "  $file_path (${size_kb}KB) - Consider splitting for AI assistance"
        done
    else
        print_success "All source files are optimally sized for AI tools"
    fi
    
    # Check for AI optimization comments
    local ai_comments=$(grep -r "@cursor\|@codex" --include="*.py" --include="*.ts" --include="*.tsx" . 2>/dev/null | wc -l)
    if [[ $ai_comments -gt 0 ]]; then
        print_success "Found $ai_comments AI assistant comments for context optimization"
    else
        print_warning "No AI assistant comments found - consider adding @cursor/@codex annotations"
    fi
}

# Backend container validation
check_backend_container() {
    print_header "🔧 BACKEND CONTAINER VALIDATION"
    
    # Check Python environment
    if [[ -d "backend/venv" ]]; then
        print_success "Python virtual environment exists"
        
        # Check if dependencies are installed
        if [[ -f "backend/venv/bin/python" ]] || [[ -f "backend/venv/Scripts/python.exe" ]]; then
            if backend/venv/bin/python -c "import fastapi" 2>/dev/null || backend/venv/Scripts/python.exe -c "import fastapi" 2>/dev/null; then
                print_success "Backend dependencies are installed"
            else
                print_error "Backend dependencies are missing - run 'make setup'"
            fi
        else
            print_error "Python interpreter not found in virtual environment"
        fi
    else
        print_warning "Backend virtual environment not found"
    fi
    
    # Check core validation
    if [[ -f "backend/validate_core.py" ]]; then
        print_info "Running backend core validation..."
        if cd backend && ./venv/bin/python validate_core.py >/dev/null 2>&1; then
            print_success "Backend core functionality validated"
        else
            print_error "Backend core validation failed"
        fi
        cd "$PROJECT_ROOT"
    fi
    
    # Check Docker build capability
    print_info "Testing backend container build..."
    if timeout 300 docker build -f docker/backend.Dockerfile -t htxv2-backend:test . >/dev/null 2>&1; then
        print_success "Backend container builds successfully"
        docker rmi htxv2-backend:test >/dev/null 2>&1 || true
    else
        print_error "Backend container build failed"
    fi
}

# Frontend container validation
check_frontend_container() {
    print_header "🎨 FRONTEND CONTAINER VALIDATION"
    
    # Check Node.js environment
    if [[ -d "frontend/node_modules" ]]; then
        print_success "Node.js dependencies are installed"
    else
        print_warning "Frontend node_modules not found - run 'make setup'"
    fi
    
    # Check package vulnerabilities
    print_info "Checking npm vulnerabilities..."
    cd frontend
    local audit_output
    if audit_output=$(npm audit --audit-level=high 2>&1); then
        print_success "No high-severity npm vulnerabilities found"
    else
        local vuln_count=$(echo "$audit_output" | grep -c "high\|critical" 2>/dev/null || echo "0")
        if [[ $vuln_count -gt 0 ]]; then
            print_warning "Found $vuln_count high/critical npm vulnerabilities - run 'npm audit fix'"
        else
            print_success "npm audit completed with minor issues only"
        fi
    fi
    cd "$PROJECT_ROOT"
    
    # Check TypeScript compilation
    print_info "Testing TypeScript compilation..."
    cd frontend
    if npm run type-check >/dev/null 2>&1; then
        print_success "TypeScript compilation successful"
    else
        print_error "TypeScript compilation failed"
    fi
    cd "$PROJECT_ROOT"
    
    # Check Docker build capability
    print_info "Testing frontend container build..."
    if timeout 300 docker build -f docker/frontend.Dockerfile -t htxv2-frontend:test . >/dev/null 2>&1; then
        print_success "Frontend container builds successfully" 
        docker rmi htxv2-frontend:test >/dev/null 2>&1 || true
    else
        print_error "Frontend container build failed"
    fi
}

# Container integration test
check_container_integration() {
    print_header "🔄 CONTAINER INTEGRATION TEST"
    
    # Test docker-compose startup (without actually starting everything)
    print_info "Validating container orchestration..."
    
    # Check if ports are available
    local ports=(5432 6379 8000 3000)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "Port $port is already in use"
        else
            print_success "Port $port is available"
        fi
    done
    
    # Validate compose file structure
    if docker compose -f docker/docker-compose.yml config >/dev/null 2>&1; then
        print_success "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration has errors"
    fi
    
    # Check health check configuration
    local health_checks=$(docker compose -f docker/docker-compose.yml config | grep -c "healthcheck:" 2>/dev/null || echo "0")
    if [[ $health_checks -ge 3 ]]; then
        print_success "Health checks configured for critical services"
    else
        print_warning "Missing health checks for some services"
    fi
}

# AI tool optimization recommendations
generate_optimization_recommendations() {
    print_header "📋 AI OPTIMIZATION RECOMMENDATIONS"
    
    # Check for optimization opportunities
    local recommendations=()
    
    # Large file analysis
    local large_files_count=$(find . -name "*.py" -o -name "*.ts" -o -name "*.tsx" | xargs wc -l 2>/dev/null | awk 'NF>1 && $1>300 {count++} END {print count+0}')
    if [[ $large_files_count -gt 0 ]]; then
        recommendations+=("Split $large_files_count large files (>300 lines) for better AI assistance")
    fi
    
    # Documentation check
    if [[ ! -f "docs/AI-OPTIMIZATION-GUIDE.md" ]]; then
        recommendations+=("Create AI optimization guide with token-efficient prompts")
    fi
    
    # Template check
    local template_count=$(find . -name "*template*" -o -name "*pattern*" | wc -l)
    if [[ $template_count -lt 3 ]]; then
        recommendations+=("Create code templates for common AI-generated patterns")
    fi
    
    # Performance optimization check
    if ! grep -q "resources:" docker/docker-compose.yml 2>/dev/null; then
        recommendations+=("Add resource limits to Docker services for better performance")
    fi
    
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        print_info "Optimization recommendations:"
        for rec in "${recommendations[@]}"; do
            print_info "  • $rec"
        done
    else
        print_success "No optimization recommendations - project is well-configured"
    fi
}

# Security and performance checks
check_security_performance() {
    print_header "🔒 SECURITY & PERFORMANCE CHECKS"
    
    # Check for secrets in code
    print_info "Scanning for potential secrets..."
    local secret_patterns=("password\s*=" "api_key\s*=" "secret\s*=" "token\s*=" "auth\s*=")
    local secret_found=false
    
    for pattern in "${secret_patterns[@]}"; do
        if grep -r -i "$pattern" --include="*.py" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules --exclude-dir=venv . 2>/dev/null | grep -v "example\|template\|schema" >/dev/null; then
            secret_found=true
            break
        fi
    done
    
    if [[ $secret_found == true ]]; then
        print_warning "Potential hardcoded secrets found - review and use environment variables"
    else
        print_success "No hardcoded secrets detected"
    fi
    
    # Check environment file configuration
    if [[ -f "backend/.env.example" ]]; then
        print_success "Backend environment template exists"
    else
        print_warning "Missing backend .env.example file"
    fi
    
    if [[ -f "frontend/.env.example" ]]; then
        print_success "Frontend environment template exists"
    else
        print_warning "Missing frontend .env.example file"
    fi
    
    # Check for production-ready configurations
    if grep -q "DEBUG=false\|ENVIRONMENT=production" backend/.env.example 2>/dev/null; then
        print_success "Production configuration template available"
    else
        print_warning "Add production environment configuration examples"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 HTXV2 Container Deployment Validation${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo "Date: $(date)"
    echo "Project Root: $PROJECT_ROOT"
    echo ""
    
    # Run all checks
    check_docker_environment
    echo ""
    
    check_token_optimization  
    echo ""
    
    check_backend_container
    echo ""
    
    check_frontend_container
    echo ""
    
    check_container_integration
    echo ""
    
    check_security_performance
    echo ""
    
    generate_optimization_recommendations
    echo ""
    
    # Summary
    print_header "📊 VALIDATION SUMMARY"
    
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        print_success "All checks passed! Containers are ready for deployment"
        echo ""
        print_info "Ready to run:"
        print_info "  • docker compose -f docker/docker-compose.yml up -d"
        print_info "  • make dev-all (for development)"
        print_info "  • make test-all (for validation)"
        
    elif [[ $ERRORS -eq 0 ]]; then
        echo -e "${YELLOW}✅ Validation completed with $WARNINGS warnings${NC}"
        echo -e "${YELLOW}Containers should work but may need optimization${NC}"
        
    else
        echo -e "${RED}❌ Validation failed with $ERRORS errors and $WARNINGS warnings${NC}"
        echo -e "${RED}Fix errors before deployment${NC}"
        exit 1
    fi
    
    echo ""
    print_info "For detailed optimization guide, see: docs/AI-OPTIMIZATION-GUIDE.md"
}

# Run main function
main "$@"