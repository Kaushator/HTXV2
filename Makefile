# HTX Interface v2 - Development Commands
.PHONY: help setup prepare ensure-submodules ci-local scan-secrets dev backend frontend fingpt mcp install-deps clean tf-init tf-plan tf-apply test lint-backend lint-frontend typecheck-frontend

help:
	@echo "🚀 HTX Interface v2 - Development Commands"
	@echo ""
	@echo "📦 Setup & Installation:"
	@echo "  setup           - Complete project setup"
	@echo "  prepare         - Bootstrap env + deps + submodules"
	@echo "  install-deps    - Install all dependencies"
	@echo ""
	@echo "🔧 Development:"
	@echo "  dev             - Start all services"
	@echo "  backend         - Start FastAPI backend only"
	@echo "  frontend        - Start Next.js frontend only"
	@echo "  fingpt          - Start FinGPT service only"
	@echo "  mcp             - Start MCP server only"
	@echo ""
	@echo "(Docker targets removed — use Terraform and local dev)"
	@echo ""
	@echo "☁️ Infrastructure:"
	@echo "  tf-init         - Initialize Terraform"
	@echo "  tf-plan         - Plan Terraform deployment"
	@echo "  tf-apply        - Apply Terraform changes"
	@echo ""
	@echo "🧹 Utilities:"
	@echo "  test            - Run all tests"
	@echo "  lint-backend    - Run Ruff on backend"
	@echo "  lint-frontend   - Run ESLint on frontend"
	@echo "  typecheck-frontend - Run TypeScript type check"
	@echo "  ci-local        - Run local CI (pytest + lint/test)"
	@echo "  scan-secrets    - Run TruffleHog filesystem scan (if installed)"
	@echo "  clean           - Clean build artifacts"

# Setup commands
setup: install-deps
	@echo "✅ Project setup complete!"
	@echo "Next steps:"
	@echo "1. Configure .env files"
	@echo "2. Run 'make dev' to start development"

prepare: ensure-submodules install-deps
	@echo "✅ Preparation complete (submodules + dependencies)"

ensure-submodules:
	@echo "🔁 Ensuring submodules..."
	git submodule update --init --recursive || true

install-deps:
	@echo "📦 Installing MCP server dependencies..."
	npm install
	@echo "📦 Installing frontend dependencies..."
	cd frontend && npm install
	@echo "📦 Installing backend dependencies..."
	cd backend && pip install -r requirements.txt

# Development commands
dev: mcp backend frontend fingpt

backend:
	@echo "🐍 Starting FastAPI backend..."
	cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &

frontend:
	@echo "⚛️ Starting Next.js frontend..."
	cd frontend && npm run dev &

fingpt:
	@echo "🤖 Starting FinGPT service..."
	cd fingpt && python server.py &

mcp:
	@echo "🔗 Starting MCP server..."
	npm start &

## Docker commands removed

# Infrastructure commands
tf-init:
	@echo "🏗️ Initializing Terraform..."
	cd infra/terraform/envs/dev && terraform init

tf-plan:
	@echo "📋 Planning Terraform deployment..."
	cd infra/terraform/envs/dev && terraform plan -var="project_id=vibrant-period-470810-p7" -var="region=us-central1" -var="bq_location=US"

tf-apply:
	@echo "🚀 Applying Terraform changes..."
	cd infra/terraform/envs/dev && terraform apply -var="project_id=vibrant-period-470810-p7" -var="region=us-central1" -var="bq_location=US"

# Utilities
test:
	@echo "🧪 Running tests..."
	npm run test
	cd frontend && npm run lint
	cd backend && python -m pytest

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf dist/
	rm -rf .next/
	rm -rf node_modules/.cache/
	cd frontend && rm -rf .next/ node_modules/.cache/
	cd backend && rm -rf __pycache__ .pytest_cache
ci-local:
	@echo "🧪 Running backend tests..."
	cd backend && pytest -q
	@echo "🔍 Linting frontend..."
	cd frontend && npm run lint || true
	@echo "🧪 Running frontend tests..."
	cd frontend && npm test --if-present || true

lint-backend:
	cd backend && ruff check app

lint-frontend:
	cd frontend && npm run lint

typecheck-frontend:
	cd frontend && npm run type-check

scan-secrets:
	@echo "🔐 Running TruffleHog (filesystem scan) ..."
	@if command -v trufflehog >/dev/null 2>&1; then \
		trufflehog filesystem --no-update --only-verified . || true; \
	else \
		echo "TruffleHog not found. Install: https://github.com/trufflesecurity/trufflehog#installation"; \
	fi
