# HTX Interface v2 - Setup Script for Windows
# PowerShell скрипт для установки и запуска (без Docker)

param(
    [Parameter(Position=0)]
    [ValidateSet("setup", "dev", "backend", "frontend", "fingpt", "mcp", "help")]
    [string]$Command = "help"
)

function Show-Help {
    Write-Host "🚀 HTX Interface v2 - Development Commands" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Setup & Installation:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup.ps1 setup       - Complete project setup"
    Write-Host ""
    Write-Host "🔧 Development:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup.ps1 dev         - Start all services"
    Write-Host "  .\scripts\setup.ps1 backend     - Start FastAPI backend only"
    Write-Host "  .\scripts\setup.ps1 frontend    - Start Next.js frontend only"
    Write-Host "  .\scripts\setup.ps1 fingpt      - Start FinGPT service only"
    Write-Host "  .\scripts\setup.ps1 mcp         - Start MCP server only"
}

function Install-Dependencies {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Green
    
    # MCP Server
    Write-Host "Installing MCP server dependencies..." -ForegroundColor Cyan
    npm install
    
    # Frontend
    Write-Host "Installing frontend dependencies..." -ForegroundColor Cyan
    Set-Location frontend
    npm install
    Set-Location ..
    
    # Backend
    Write-Host "Installing backend dependencies..." -ForegroundColor Cyan
    Set-Location backend
    if (-not (Test-Path "venv")) {
        python -m venv venv
    }
    .\venv\Scripts\Activate.ps1
    pip install -r requirements.txt
    Set-Location ..
    
    Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
}

function Start-Backend {
    Write-Host "🐍 Starting FastAPI backend..." -ForegroundColor Green
    Set-Location backend
    .\venv\Scripts\Activate.ps1
    Start-Process -FilePath "uvicorn" -ArgumentList "app.main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"
    Set-Location ..
}

function Start-Frontend {
    Write-Host "⚛️ Starting Next.js frontend..." -ForegroundColor Green
    Set-Location frontend
    Start-Process -FilePath "npm" -ArgumentList "run", "dev"
    Set-Location ..
}

function Start-FinGPT {
    Write-Host "🤖 Starting FinGPT service..." -ForegroundColor Green
    Set-Location fingpt
    Start-Process -FilePath "python" -ArgumentList "server.py"
    Set-Location ..
}

function Start-MCP {
    Write-Host "🔗 Starting MCP server..." -ForegroundColor Green
    npm start
}

function Start-All {
    Write-Host "🚀 Starting all services..." -ForegroundColor Green
    Start-MCP
    Start-Backend
    Start-Frontend
    Start-FinGPT
    
    Write-Host ""
    Write-Host "✅ All services started!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📱 Access points:" -ForegroundColor Yellow
    Write-Host "   Frontend:      http://localhost:3000"
    Write-Host "   Backend API:   http://localhost:8000/docs"
    Write-Host "   FinGPT:        http://localhost:8055"
    Write-Host "   MCP Server:    Running in VS Code"
}

function Setup-Project {
    Write-Host "🏗️ Setting up HTX Interface v2..." -ForegroundColor Green
    
    # Check prerequisites
    Write-Host "📋 Checking prerequisites..." -ForegroundColor Cyan
    
    try {
        node --version | Out-Null
        Write-Host "✅ Node.js found" -ForegroundColor Green
    } catch {
        Write-Host "❌ Node.js not found. Please install Node.js 18+" -ForegroundColor Red
        return
    }
    
    try {
        python --version | Out-Null
        Write-Host "✅ Python found" -ForegroundColor Green
    } catch {
        Write-Host "❌ Python not found. Please install Python 3.11+" -ForegroundColor Red
        return
    }
    
    # Docker is not required for local development
    
    # Setup environment files
    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Host "📝 Created .env file - please edit with your configuration" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path "frontend\.env.local")) {
        @"
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws
"@ | Out-File -FilePath "frontend\.env.local" -Encoding UTF8
        Write-Host "📝 Created frontend\.env.local" -ForegroundColor Yellow
    }
    
    # Install dependencies
    Install-Dependencies
    
    # Build MCP server
    Write-Host "🔨 Building MCP server..." -ForegroundColor Cyan
    npm run build
    
    Write-Host ""
    Write-Host "✅ Project setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📚 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Configure your API keys in .env files"
    Write-Host "2. Run '.\\scripts\\setup.ps1 dev' to start development"
}

# Main execution
switch ($Command) {
    "setup" { Setup-Project }
    "dev" { Start-All }
    "backend" { Start-Backend }
    "frontend" { Start-Frontend }
    "fingpt" { Start-FinGPT }
    "mcp" { Start-MCP }
    "help" { Show-Help }
    default { Show-Help }
}
