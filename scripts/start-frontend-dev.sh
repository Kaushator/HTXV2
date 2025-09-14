#!/bin/bash

# Simple frontend development setup without Docker
# This script starts the frontend in development mode

set -e

echo "🚀 Starting HTXV2 Frontend Development Server"
echo "============================================="

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required. Please install Node.js 18+"
    exit 1
fi

cd frontend

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Setup environment file
if [ ! -f ".env.local" ]; then
    echo "📝 Setting up environment file..."
    cp .env.example .env.local
    echo "⚠️  Please edit .env.local with your configuration if needed"
fi

echo "✅ Starting development server..."
echo "📚 Available at: http://localhost:3000"
echo "🔗 Backend API: http://localhost:8000"
echo "📖 API Docs: http://localhost:8000/docs"
echo ""

# Start development server
npm run dev