.PHONY: help install dev-install test format lint clean build deploy-all deploy-litellm deploy-vllm deploy-ragflow deploy-xinference stop-all stop-litellm stop-vllm stop-ragflow stop-xinference logs logs-litellm logs-vllm logs-ragflow logs-xinference health-check network-create network-remove env-check status backup restore update-models scale-up scale-down restart-all restart-litellm restart-vllm restart-ragflow restart-xinference dev prod setup-monitoring setup-alerts docs serve-docs docker-clean system-info gpu-info

# Default target
help: ## Show this help message
	@echo "🚀 Deployment Repository"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation and Setup
install: ## Install production dependencies
	pip install -e .

dev-install: ## Install development dependencies
	pip install -e ".[dev,docs,monitoring]"

setup: ## Initial project setup
	@echo "🔧 Setting up Deployment Repository..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "✅ Created .env file from template"; fi
	@make network-create
	@echo "✅ Setup complete! Run 'make deploy-all' to start services"

env-check: ## Check if required environment variables are set
	@echo "🔍 Checking environment variables..."
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'cp .env.example .env' first"; exit 1; fi
	@if ! grep -q "HUGGING_FACE_HUB_TOKEN" .env; then echo "❌ HUGGING_FACE_HUB_TOKEN not set in .env"; exit 1; fi
	@echo "✅ Environment variables look good"

# Development
dev: ## Start development environment
	@echo "🚀 Starting development environment..."
	@make env-check
	docker-compose -f docker-compose.dev.yml up -d

test: ## Run tests
	pytest tests/ -v --cov=vllm_deployment --cov-report=html --cov-report=term

format: ## Format code with black and isort
	black vllm_deployment/ tests/
	isort vllm_deployment/ tests/

lint: ## Run linting checks
	ruff check vllm_deployment/ tests/
	mypy vllm_deployment/
	flake8 vllm_deployment/ tests/

clean: ## Clean up build artifacts and cache
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .mypy_cache -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	rm -rf build/ dist/ .coverage htmlcov/

# Building
build: ## Build the project
	python -m build

# Docker Network Management
network-create: ## Create shared Docker network
	@echo "🌐 Creating shared-vllm-network..."
	@docker network create shared-vllm-network 2>/dev/null || echo "Network already exists"

network-remove: ## Remove shared Docker network
	@echo "🌐 Removing shared-vllm-network..."
	@docker network rm shared-vllm-network 2>/dev/null || echo "Network doesn't exist"

# Deployment - All Services
deploy-all: ## Deploy all services
	@echo "🚀 Deploying all services..."
	@make env-check
	@make network-create
	docker-compose up -d
	@echo "⏳ Waiting for services to be healthy..."
	@sleep 30
	@make health-check

deploy-litellm: ## Deploy only LiteLLM proxy
	@echo "🚀 Deploying LiteLLM proxy..."
	cd litellm && docker-compose up -d

deploy-vllm: ## Deploy vLLM models
	@echo "🚀 Deploying vLLM models..."
	cd vllm/qwen25-14b-instruct-1m && docker-compose up -d
	cd vllm/qwen3-30b-a3b-instruct-2507 && docker-compose up -d

deploy-ragflow: ## Deploy RAGFlow
	@echo "🚀 Deploying RAGFlow..."
	cd ragflow && docker-compose up -d

deploy-xinference: ## Deploy Xinference
	@echo "🚀 Deploying Xinference..."
	cd xinference && docker-compose up -d

# Stop Services
stop-all: ## Stop all services
	@echo "🛑 Stopping all services..."
	docker-compose down
	cd litellm && docker-compose down
	cd vllm/qwen25-14b-instruct-1m && docker-compose down
	cd vllm/qwen3-30b-a3b-instruct-2507 && docker-compose down
	cd ragflow && docker-compose down
	cd xinference && docker-compose down

stop-litellm: ## Stop LiteLLM proxy
	cd litellm && docker-compose down

stop-vllm: ## Stop vLLM models
	cd vllm/qwen25-14b-instruct-1m && docker-compose down
	cd vllm/qwen3-30b-a3b-instruct-2507 && docker-compose down

stop-ragflow: ## Stop RAGFlow
	cd ragflow && docker-compose down

stop-xinference: ## Stop Xinference
	cd xinference && docker-compose down

# Restart Services
restart-all: ## Restart all services
	@make stop-all
	@make deploy-all

restart-litellm: ## Restart LiteLLM proxy
	@make stop-litellm
	@make deploy-litellm

restart-vllm: ## Restart vLLM models
	@make stop-vllm
	@make deploy-vllm

restart-ragflow: ## Restart RAGFlow
	@make stop-ragflow
	@make deploy-ragflow

restart-xinference: ## Restart Xinference
	@make stop-xinference
	@make deploy-xinference

# Logging
logs: ## Show logs for all services
	docker-compose logs -f

logs-litellm: ## Show LiteLLM logs
	cd litellm && docker-compose logs -f

logs-vllm: ## Show vLLM logs
	cd vllm/qwen25-14b-instruct-1m && docker-compose logs -f &
	cd vllm/qwen3-30b-a3b-instruct-2507 && docker-compose logs -f

logs-ragflow: ## Show RAGFlow logs
	cd ragflow && docker-compose logs -f

logs-xinference: ## Show Xinference logs
	cd xinference && docker-compose logs -f

# Health and Monitoring
health-check: ## Check health of all services
	@echo "🏥 Checking service health..."
	@python -c "
import requests
import time
import sys

services = [
    ('LiteLLM', 'http://localhost:4000/health/liveliness'),
    ('vLLM Qwen2.5-14B', 'http://localhost:9998/health'),
    ('vLLM Qwen3-30B', 'http://localhost:9999/health'),
    ('Xinference', 'http://localhost:9900/health'),
    ('RAGFlow', 'http://localhost:9380/'),
    ('Prometheus', 'http://localhost:9090/-/healthy'),
]

all_healthy = True
for name, url in services:
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            print(f'✅ {name}: Healthy')
        else:
            print(f'⚠️  {name}: Status {response.status_code}')
            all_healthy = False
    except Exception as e:
        print(f'❌ {name}: Unreachable ({str(e)[:50]}...)')
        all_healthy = False

if not all_healthy:
    print('\n❌ Some services are unhealthy. Check logs with \"make logs\"')
    sys.exit(1)
else:
    print('\n🎉 All services are healthy!')
"

status: ## Show status of all services
	@echo "📊 Service Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Scaling
scale-up: ## Scale up vLLM services (requires replicas in compose)
	@echo "⬆️  Scaling up services..."
	docker-compose up -d --scale vllm-qwen25-14b-instruct-1m=2
	docker-compose up -d --scale vllm-qwen3-30b-a3b-instruct-2507=2

scale-down: ## Scale down vLLM services
	@echo "⬇️  Scaling down services..."
	docker-compose up -d --scale vllm-qwen25-14b-instruct-1m=1
	docker-compose up -d --scale vllm-qwen3-30b-a3b-instruct-2507=1

# Backup and Restore
backup: ## Create backup of databases and configurations
	@echo "💾 Creating backup..."
	@mkdir -p backups
	@timestamp=$(shell date +%Y%m%d_%H%M%S)
	@docker exec litellm_db pg_dump -U llmproxy litellm > backups/litellm_$${timestamp}.sql
	@docker exec ragflow_mysql mysqldump -u root rag_flow > backups/ragflow_$${timestamp}.sql
	@echo "✅ Backup created in backups/ directory"

restore: ## Restore from backup (requires BACKUP_FILE variable)
	@if [ -z "$(BACKUP_FILE)" ]; then echo "❌ Please specify BACKUP_FILE variable"; exit 1; fi
	@echo "🔄 Restoring from $(BACKUP_FILE)..."
	@docker exec -i litellm_db psql -U llmproxy litellm < $(BACKUP_FILE)
	@echo "✅ Database restored"

# Model Management
update-models: ## Update all models to latest versions
	@echo "🔄 Updating models..."
	@make stop-vllm
	@make stop-xinference
	@echo "📥 Pulling latest model images..."
	docker pull vllm/vllm-openai:v0.10.1
	docker pull xprobe/xinference:v1.9.1-cu128
	@make deploy-vllm
	@make deploy-xinference
	@echo "✅ Models updated!"

# System Information
system-info: ## Show system information
	@echo "💻 System Information:"
	@echo "OS: $(shell uname -s) $(shell uname -r)"
	@echo "Docker: $(shell docker --version)"
	@echo "Docker Compose: $(shell docker-compose --version)"
	@echo "Python: $(shell python --version)"
	@echo "GPU Available: $(shell nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1 2>/dev/null || echo "None")"

gpu-info: ## Show GPU information
	@echo "🖥️  GPU Information:"
	@nvidia-smi --query-gpu=index,name,memory.total,memory.used,memory.free,temperature.gpu,utilization.gpu --format=csv,noheader,nounits || echo "No NVIDIA GPU detected"

# Docker Cleanup
docker-clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	docker system prune -f
	docker volume prune -f
	docker network prune -f

# Documentation
docs: ## Build documentation
	sphinx-build -b html docs/ docs/_build/html

serve-docs: ## Serve documentation locally
	sphinx-build -b html docs/ docs/_build/html
	cd docs/_build/html && python -m http.server 8000

# Production
prod: ## Deploy in production mode
	@echo "🏭 Deploying in production mode..."
	@make env-check
	DOCKER_BUILDKIT=1 docker-compose -f docker-compose.prod.yml up -d --build
	@echo "⏳ Waiting for services to be healthy..."
	@sleep 60
	@make health-check

# Monitoring Setup
setup-monitoring: ## Set up monitoring and alerting
	@echo "📊 Setting up monitoring..."
	@make deploy-all
	@echo "🔗 Grafana: http://localhost:3000"
	@echo "📈 Prometheus: http://localhost:9090"
	@echo "📋 LiteLLM UI: http://localhost:4000"

setup-alerts: ## Set up alerting rules
	@echo "🚨 Setting up alerting..."
	@if [ ! -f prometheus/alert_rules.yml ]; then echo "❌ Alert rules file not found"; exit 1; fi
	@echo "✅ Alert rules configured"

# Quick Commands
quick-start: ## Quick start for development
	@make setup
	@make deploy-all
	@make health-check
	@echo "🎉 Ready! Access services at:"
	@echo "  • LiteLLM API: http://localhost:4000"
	@echo "  • RAGFlow UI: http://localhost:9380"
	@echo "  • Xinference UI: http://localhost:9900"
	@echo "  • Prometheus: http://localhost:9090"

quick-stop: ## Quick stop all services
	@make stop-all
	@make docker-clean
