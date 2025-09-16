.PHONY: help env-check network-create deploy-litellm deploy-vllm deploy-ragflow deploy-xinference stop-litellm stop-vllm stop-ragflow stop-xinference

# Default target
help: ## Show this help message
	@echo "🚀 Deployment Repository"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

env-check: ## Check if required environment variables are set
	@echo "🔍 Checking environment variables..."
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'cp .env.example .env' first"; exit 1; fi
	@if ! grep -q "HUGGING_FACE_HUB_TOKEN" .env; then echo "❌ HUGGING_FACE_HUB_TOKEN not set in .env"; exit 1; fi
	@echo "✅ Environment variables look good"

network-create: ## Create shared Docker network
	@echo "🌐 Creating shared-vllm-network..."
	@docker network create shared-vllm-network 2>/dev/null || echo "Network already exists"

deploy-litellm: ## Deploy only LiteLLM proxy
	@echo "🚀 Deploying LiteLLM proxy..."
	@make env-check
	cd litellm && docker compose up -d && cd ..

deploy-vllm: ## Deploy vLLM models
	@echo "🚀 Deploying vLLM models..."
	@make env-check
	@make network-create
	cd vllm/qwen25-14b-instruct-1m && docker compose up -d && cd ../..
	cd vllm/qwen3-30b-a3b-instruct-2507 && docker compose up -d && cd ../..

deploy-ragflow: ## Deploy RAGFlow
	@echo "🚀 Deploying RAGFlow..."
	cd ragflow && docker compose up -d && cd ..

deploy-xinference: ## Deploy Xinference
	@echo "🚀 Deploying Xinference..."
	cd xinference && docker compose up -d && cd ..

stop-litellm: ## Stop LiteLLM proxy
	cd litellm && docker compose down

stop-vllm: ## Stop vLLM models
	cd vllm/qwen25-14b-instruct-1m && docker compose down
	cd vllm/qwen3-30b-a3b-instruct-2507 && docker compose down

stop-ragflow: ## Stop RAGFlow
	cd ragflow && docker compose down

stop-xinference: ## Stop Xinference
	cd xinference && docker compose down
