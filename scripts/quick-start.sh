#!/bin/bash

# HTX Interface v2 - Quick Start Script
# Скрипт для быстрого запуска всей системы

set -e

echo "🚀 HTX Interface v2 - Quick Start"
echo "=================================="

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

echo "✅ All prerequisites found"

# Setup environment
echo ""
echo "🔧 Setting up environment..."

# Copy environment files if they don't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "📝 Created .env file - please edit with your configuration"
fi

if [ ! -f "frontend/.env.local" ]; then
    echo "NEXT_PUBLIC_BACKEND_URL=http://localhost:8000" > frontend/.env.local
    echo "NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws" >> frontend/.env.local
    echo "📝 Created frontend/.env.local"
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."

# MCP Server
echo "Installing MCP server dependencies..."
npm install

# Frontend
echo "Installing frontend dependencies..."
cd frontend
npm install
cd ..

# Backend
echo "Installing backend dependencies..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
cd ..

echo "✅ Dependencies installed"

# Build MCP server
echo ""
echo "🔨 Building MCP server..."
npm run build

echo "✅ MCP server built"

# Option selection
echo ""
echo "🎯 Choose startup option:"
echo "1. Full Docker environment (recommended)"
echo "2. Local development servers"
echo "3. MCP server only"
echo "4. Show status and exit"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🐳 Starting full Docker environment..."
        docker-compose up -d
        echo ""
        echo "✅ All services started!"
        echo ""
        echo "📱 Access points:"
        echo "   Frontend:      http://localhost:3000"
        echo "   Backend API:   http://localhost:8000/docs"
        echo "   FinGPT:        http://localhost:8055"
        echo ""
        echo "📊 Service status:"
        docker-compose ps
        ;;
    2)
        echo ""
        echo "🔧 Starting local development servers..."
        
        # Start MCP server in background
        echo "Starting MCP server..."
        npm start &
        MCP_PID=$!
        
        # Start backend in background
        echo "Starting backend..."
        cd backend
        source venv/bin/activate
        uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
        BACKEND_PID=$!
        cd ..
        
        # Start frontend in background
        echo "Starting frontend..."
        cd frontend
        npm run dev &
        FRONTEND_PID=$!
        cd ..
        
        echo ""
        echo "✅ Local services started!"
        echo ""
        echo "📱 Access points:"
        echo "   Frontend:      http://localhost:3000"
        echo "   Backend API:   http://localhost:8000/docs"
        echo "   MCP Server:    Running in VS Code"
        echo ""
        echo "🛑 To stop services, run: make clean"
        
        # Wait for user input to stop
        read -p "Press Enter to stop all services..."
        
        # Stop all background processes
        kill $MCP_PID $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
        echo "🛑 All services stopped"
        ;;
    3)
        echo ""
        echo "🔗 Starting MCP server only..."
        npm start
        ;;
    4)
        echo ""
        echo "📊 System status:"
        echo ""
        echo "📁 Project structure:"
        ls -la
        echo ""
        echo "🔧 Environment files:"
        [ -f ".env" ] && echo "✅ .env exists" || echo "❌ .env missing"
        [ -f "frontend/.env.local" ] && echo "✅ frontend/.env.local exists" || echo "❌ frontend/.env.local missing"
        echo ""
        echo "📦 Dependencies:"
        [ -d "node_modules" ] && echo "✅ MCP server dependencies installed" || echo "❌ MCP server dependencies missing"
        [ -d "frontend/node_modules" ] && echo "✅ Frontend dependencies installed" || echo "❌ Frontend dependencies missing"
        [ -d "backend/venv" ] && echo "✅ Backend virtual environment exists" || echo "❌ Backend virtual environment missing"
        echo ""
        echo "🏗️ Build artifacts:"
        [ -d "dist" ] && echo "✅ MCP server built" || echo "❌ MCP server not built"
        [ -d "frontend/.next" ] && echo "✅ Frontend built" || echo "❌ Frontend not built"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🎉 HTX Interface v2 setup complete!"
echo ""
echo "📚 Next steps:"
echo "1. Configure your API keys in .env files"
echo "2. Set up Google Cloud credentials (optional)"
echo "3. Visit the frontend at http://localhost:3000"
echo "4. Check API documentation at http://localhost:8000/docs"
echo ""
echo "🆘 Need help? Check the documentation:"
echo "   Architecture: docs/architecture.md"
echo "   Quick Start:  docs/quick-start.md"
echo "   Deployment:   docs/deployment-plan.md"
