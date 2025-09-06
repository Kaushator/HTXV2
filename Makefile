# Development Commands
.PHONY: help dev-backend dev-frontend dev-all test-backend test-frontend test-all lint-backend lint-frontend lint-all clean setup tf-init tf-plan tf-apply tf-destroy
.PHONY: docker-build-all docker-start docker-stop docker-restart docker-logs docker-clean
.PHONY: deploy-dev deploy-prod test-performance test-api check-endpoints

help:
	@echo "Available commands:"
	@echo "  setup           - Set up development environment"
	@echo "  dev-backend     - Run backend development server"
	@echo "  dev-frontend    - Run frontend development server"
	@echo "  dev-all         - Run both frontend and backend"
	@echo "  test-backend    - Run backend tests"
	@echo "  test-frontend   - Run frontend tests"
	@echo "  test-all        - Run all tests"
	@echo "  test-performance - Run performance and bottleneck tests"
	@echo "  test-api        - Test API endpoint completeness"
	@echo "  check-endpoints - Check for empty/missing endpoints"
	@echo "  lint-backend    - Lint backend code"
	@echo "  lint-frontend   - Lint frontend code"
	@echo "  lint-all        - Lint all code"
	@echo "  clean           - Clean build artifacts"
	@echo ""
	@echo "Docker Commands:"
	@echo "  docker-build-all - Build all Docker images"
	@echo "  docker-start     - Start all services with Docker"
	@echo "  docker-stop      - Stop all Docker services"
	@echo "  docker-restart   - Restart all Docker services"
	@echo "  docker-logs      - Show Docker service logs"
	@echo "  docker-clean     - Clean Docker containers and volumes"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  deploy-dev       - Deploy development environment"
	@echo "  deploy-prod      - Deploy production environment"
	@echo ""
	@echo "Infrastructure Commands:"
	@echo "  tf-init         - Initialize Terraform"
	@echo "  tf-plan         - Plan Terraform changes"
	@echo "  tf-apply        - Apply Terraform changes"
	@echo "  tf-destroy      - Destroy Terraform resources"

setup:
	@echo "Setting up development environment..."
	cd backend && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
	cd frontend && npm install
	cd etl && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
	cd ml && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
	@echo "Setup complete!"

dev-backend:
	cd backend && source venv/bin/activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend:
	cd frontend && npm run dev

dev-all:
	@echo "Starting backend and frontend..."
	make dev-backend &
	make dev-frontend &
	wait

test-backend:
	cd backend && source venv/bin/activate && pytest tests/

test-frontend:
	cd frontend && npm test

test-all: test-backend test-frontend

test-performance:
	@echo "Running performance and bottleneck tests..."
	./scripts/test-performance.sh all

test-api:
	@echo "Testing API endpoint completeness..."
	python3 tests/test_api_endpoints.py

check-endpoints: test-api

lint-backend:
	cd backend && source venv/bin/activate && black . && isort . && flake8 .

lint-frontend:
	cd frontend && npm run lint

lint-all: lint-backend lint-frontend

clean:
	cd backend && rm -rf __pycache__ .pytest_cache .coverage
	cd frontend && rm -rf .next node_modules/.cache
	cd infrastructure && rm -rf .terraform
	docker system prune -f

# Docker Commands
docker-build-all:
	@echo "Building all Docker images..."
	cd docker && docker compose build

docker-start:
	@echo "Starting all services with Docker..."
	cd docker && docker compose up -d

docker-stop:
	@echo "Stopping all Docker services..."
	cd docker && docker compose down

docker-restart:
	@echo "Restarting all Docker services..."
	cd docker && docker compose restart

docker-logs:
	@echo "Showing Docker service logs..."
	cd docker && docker compose logs -f

docker-clean:
	@echo "Cleaning Docker containers and volumes..."
	cd docker && docker compose down -v
	docker system prune -af

# Deployment Commands
deploy-dev:
	@echo "Deploying development environment..."
	./scripts/deploy.sh --env development deploy

deploy-prod:
	@echo "Deploying production environment..."
	./scripts/deploy.sh --env production deploy

deploy-prod-monitoring:
	@echo "Deploying production environment with monitoring..."
	./scripts/deploy.sh --env production --profile monitoring deploy

deploy-prod-full:
	@echo "Deploying full production stack with proxy and monitoring..."
	./scripts/deploy.sh --env production --profile "proxy,monitoring" deploy

# Infrastructure Commands
tf-init:
	cd infrastructure && terraform init

tf-plan:
	cd infrastructure && terraform plan

tf-apply:
	cd infrastructure && terraform apply

tf-destroy:
	cd infrastructure && terraform destroy