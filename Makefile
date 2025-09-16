# Development Commands
.PHONY: help dev-backend dev-frontend dev-all test-backend test-frontend test-all lint-backend lint-frontend lint-all clean setup tf-init tf-plan tf-apply tf-destroy gpu-start gpu-stop gpu-monitor gpu-test

help:
	@echo "Available commands:"
	@echo "  setup           - Set up development environment"
	@echo "  dev-backend     - Run backend development server"
	@echo "  dev-frontend    - Run frontend development server"
	@echo "  dev-all         - Run both frontend and backend"
	@echo "  test-backend    - Run backend tests"
	@echo "  test-frontend   - Run frontend tests"
	@echo "  test-all        - Run all tests"
	@echo "  lint-backend    - Lint backend code"
	@echo "  lint-frontend   - Lint frontend code"
	@echo "  lint-all        - Lint all code"
	@echo "  clean           - Clean build artifacts"
	@echo "  tf-init         - Initialize Terraform"
	@echo "  tf-plan         - Plan Terraform changes"
	@echo "  tf-apply        - Apply Terraform changes"
	@echo "  tf-destroy      - Destroy Terraform resources"
	@echo ""
	@echo "GPU/AI Commands:"
	@echo "  gpu-start       - Start GPU-enabled environment (RTX 4060)"
	@echo "  gpu-stop        - Stop GPU environment"
	@echo "  gpu-monitor     - Monitor GPU usage and AI services"
	@echo "  gpu-test        - Test AI model performance"

setup:
	@echo "Setting up development environment..."
	cd backend && python3 -m venv venv && ./venv/bin/pip install -r requirements.txt
	cd frontend && npm install
	@echo "Setup complete!"

dev-backend:
	cd backend && ./venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend:
	cd frontend && npm run dev

dev-all:
	@echo "Starting backend and frontend..."
	make dev-backend &
	make dev-frontend &
	wait

test-backend:
	cd backend && ./venv/bin/pytest tests/

test-frontend:
	cd frontend && npm test

test-all: test-backend test-frontend

lint-backend:
	cd backend && ./venv/bin/black . && ./venv/bin/isort . && ./venv/bin/flake8 .

lint-frontend:
	cd frontend && npm run lint

lint-all: lint-backend lint-frontend

clean:
	cd backend && rm -rf __pycache__ .pytest_cache .coverage
	cd frontend && rm -rf .next node_modules/.cache
	cd infrastructure && rm -rf .terraform

tf-init:
	cd infrastructure && terraform init

tf-plan:
	cd infrastructure && terraform plan

tf-apply:
	cd infrastructure && terraform apply

tf-destroy:
	cd infrastructure && terraform destroy

# GPU/AI Commands
gpu-start:
	@echo "🚀 Starting GPU-enabled AI environment..."
	./scripts/start-local-ai.sh

gpu-stop:
	@echo "🛑 Stopping GPU environment..."
	cd docker && docker compose -f docker-compose.gpu.yml down

gpu-monitor:
	@echo "📊 Starting GPU monitoring..."
	./scripts/monitor-gpu.sh

gpu-test:
	@echo "🧪 Testing AI models..."
	python3 scripts/test-ai.py