#!/bin/bash
#
# Script: optimize-code.sh
# Description: Optimizes code in the HTXEnterface_v2 project using best practices.
# Author: GitHub Copilot
# Date: 2023-07-25
#
# Usage: ./optimize-code.sh [--backend|--frontend|--all]
#
# Requirements:
#   - Python tools: black, isort, ruff, pylint
#   - Node.js tools: eslint, prettier

set -e  # Exit immediately if a command exits with a non-zero status

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Process command line arguments
TARGET="all"
if [ $# -gt 0 ]; then
    if [ "$1" == "--backend" ]; then
        TARGET="backend"
    elif [ "$1" == "--frontend" ]; then
        TARGET="frontend"
    elif [ "$1" == "--all" ]; then
        TARGET="all"
    else
        print_error "Unknown argument: $1"
        echo "Usage: $0 [--backend|--frontend|--all]"
        exit 1
    fi
fi

print_info "Starting code optimization for $TARGET..."

# Get the project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo $(pwd))
cd "$PROJECT_ROOT"

# Function to optimize backend code
optimize_backend() {
    print_info "Optimizing backend code..."

    # Check if necessary tools are installed
    local backend_tools=("black" "isort" "ruff" "pylint")
    local missing_tools=()

    for tool in "${backend_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Some Python tools are missing: ${missing_tools[*]}"
        read -p "Would you like to install them now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pip install --upgrade black isort ruff pylint
        else
            print_warning "Skipping tools that are not installed."
        fi
    fi

    # Black formatting
    if command -v black &> /dev/null; then
        print_info "Running Black formatter..."
        black ./backend --exclude=venv || true
    fi

    # isort for import sorting
    if command -v isort &> /dev/null; then
        print_info "Running isort to organize imports..."
        isort ./backend --profile black || true
    fi

    # Ruff for fast linting and auto-fixing
    if command -v ruff &> /dev/null; then
        print_info "Running Ruff for quick fixes..."
        ruff check ./backend --fix || true
    fi

    # Pylint for deeper code quality analysis
    if command -v pylint &> /dev/null; then
        print_info "Running Pylint for code quality analysis..."
        # Only report, don't fail on issues
        pylint --recursive=y ./backend || true
    fi

    print_success "Backend optimization complete!"
}

# Function to optimize frontend code
optimize_frontend() {
    print_info "Optimizing frontend code..."

    # Check if frontend directory exists
    if [ ! -d "./frontend" ]; then
        print_warning "Frontend directory not found. Skipping frontend optimization."
        return
    fi

    # Check if package.json exists
    if [ ! -f "./frontend/package.json" ]; then
        print_warning "Frontend package.json not found. Skipping frontend optimization."
        return
    fi

    # Check if necessary tools are available via npm
    cd ./frontend

    # Lint and fix with ESLint if available
    if grep -q "\"eslint\"" package.json; then
        print_info "Running ESLint to fix issues..."
        if grep -q "\"lint\"" package.json; then
            npm run lint -- --fix || true
        else
            npx eslint . --ext .js,.jsx,.ts,.tsx --fix || true
        fi
    else
        print_warning "ESLint not found in package.json. Skipping linting."
    fi

    # Format with Prettier if available
    if grep -q "\"prettier\"" package.json; then
        print_info "Running Prettier to format code..."
        if grep -q "\"format\"" package.json; then
            npm run format || true
        else
            npx prettier --write "**/*.{js,jsx,ts,tsx,json,css,scss,md}" || true
        fi
    else
        print_warning "Prettier not found in package.json. Skipping formatting."
    fi

    cd "$PROJECT_ROOT"
    print_success "Frontend optimization complete!"
}

# Execute optimization based on target
if [ "$TARGET" == "backend" ] || [ "$TARGET" == "all" ]; then
    if [ -d "./backend" ]; then
        optimize_backend
    else
        print_warning "Backend directory not found. Skipping backend optimization."
    fi
fi

if [ "$TARGET" == "frontend" ] || [ "$TARGET" == "all" ]; then
    if [ -d "./frontend" ]; then
        optimize_frontend
    else
        print_warning "Frontend directory not found. Skipping frontend optimization."
    fi
fi

print_success "Code optimization completed successfully!"
exit 0
