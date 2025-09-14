#!/bin/bash

# Setup development environment

set -e

echo "🚀 Setting up HTXV2 development environment..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required. Please install Node.js 18+"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required. Please install Python 3.11+"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required. Please install Docker"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "⚠️  Terraform not found. Terraform is optional for local development."
else
    echo "✅ Terraform found"
fi

echo "✅ All prerequisites found"

# Setup backend
echo "🐍 Setting up backend..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Setup frontend
echo "⚛️  Setting up frontend..."
cd frontend
npm install
cd ..

# Setup ETL
echo "🔄 Setting up ETL..."
cd etl
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Setup ML
echo "🤖 Setting up ML..."
cd ml
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Setup environment files
echo "📝 Setting up environment files..."
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    echo "⚠️  Please edit backend/.env with your configuration"
fi

if [ ! -f "frontend/.env.local" ]; then
    cp frontend/.env.example frontend/.env.local
    echo "⚠️  Please edit frontend/.env.local with your configuration"
fi

if [ ! -f "infrastructure/terraform.tfvars" ]; then
    cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
    echo "⚠️  Please edit infrastructure/terraform.tfvars with your GCP project details"
fi

# Start services with Docker
echo "🐳 Starting services with Docker..."
docker compose -f docker/docker-compose.yml up -d

echo "✅ Development environment setup complete!"
echo ""
echo "📚 Next steps:"
echo "1. Edit configuration files as noted above"
echo "2. Run 'make dev-all' to start development servers"
echo "3. Visit http://localhost:3000 for frontend"
echo "4. Visit http://localhost:8000/docs for API documentation"
echo ""
echo "🔧 Useful commands:"
echo "  make dev-backend   - Start backend only"
echo "  make dev-frontend  - Start frontend only"
echo "  make test-all      - Run all tests"
echo "  make lint-all      - Run all linting"