# 🚀 Deployment Repository

A comprehensive deployment repository for running multiple Large Language Models (LLMs) with unified API access, monitoring, and management capabilities.

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Services](#-services)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Monitoring](#-monitoring)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **Multi-Model Support**: Deploy and manage multiple LLM models simultaneously
- **Unified API**: Single endpoint access to all deployed models via LiteLLM proxy
- **GPU Resource Management**: Optimized GPU allocation and utilization
- **Monitoring & Observability**: Prometheus metrics and health checks
- **RAG Capabilities**: Integrated RAGFlow for document processing and retrieval
- **Scalable Architecture**: Docker-based deployment with service isolation
- **Production Ready**: Health checks, logging, and restart policies

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   LiteLLM Proxy │    │     Clients     │
│   (Port 4000)   │◄──►│   OpenAI API    │
└─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐
│   Inference     │    │     RAGFlow     │
│   Services      │    │   (Port 9380)   │
├─────────────────┤    └─────────────────┘
│ • vLLM Models   │           ▲
│   - Qwen2.5-14B │           │
│   - Qwen3-30B   │           │
│ • Xinference    │           │
└─────────────────┘    ┌─────────────────┐
         ▲            │   Vector DB      │
         │            │   (Elasticsearch)│
         └────────────┼─────────────────┘
                      │   MinIO Storage │
                      └─────────────────┘
```

## 🔧 Services

### Core Services

| Service | Port | Description | Technology |
|---------|------|-------------|------------|
| **LiteLLM Proxy** | 4000 | Unified API gateway for all models | Python/FastAPI |
| **vLLM Qwen2.5-14B** | 9998 | High-performance inference for Qwen2.5-14B | vLLM/CUDA |
| **vLLM Qwen3-30B** | 9999 | High-performance inference for Qwen3-30B | vLLM/CUDA |
| **Xinference** | 9900 | Flexible model inference server | Xinference |
| **RAGFlow** | 9380 | RAG system with document processing | RAGFlow |

### Supporting Services

| Service | Port | Description |
|---------|------|-------------|
| **PostgreSQL** | 5432 | Database for LiteLLM |
| **Prometheus** | 9090 | Metrics collection and monitoring |
| **Elasticsearch** | 1200 | Vector database for RAGFlow |
| **MinIO** | 9000/9001 | Object storage |
| **Redis** | 6379 | Caching and session storage |
| **MySQL** | 5455 | Database for RAGFlow |

## 📋 Prerequisites

- **Docker** >= 24.0
- **Docker Compose** >= 2.0
- **NVIDIA GPU** with CUDA support (for GPU services), version 12.8
- **NVIDIA Docker** runtime
- **Hugging Face** account and API token
- **4GB+ RAM** recommended
- **Linux/macOS** (Windows with WSL2)

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vllm
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Hugging Face token and other settings
   ```

3. **Create shared network**
   ```bash
   docker network create shared-vllm-network
   ```

4. **Deploy all services**
   ```bash
   make deploy-all
   ```

5. **Verify deployment**
   ```bash
   make health-check
   ```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Hugging Face
HUGGING_FACE_HUB_TOKEN=your_huggingface_token_here

# Database
POSTGRES_PASSWORD=your_postgres_password
MYSQL_PASSWORD=your_mysql_password

# MinIO
MINIO_USER=your_minio_user
MINIO_PASSWORD=your_minio_password

# Redis
REDIS_PASSWORD=your_redis_password

# Elasticsearch
ELASTIC_PASSWORD=your_elastic_password
```

### Model Configuration

Each model service can be configured independently:

- **vLLM Models**: Edit `vllm/*/docker-compose.yaml`
- **Xinference**: Configure via web UI at http://localhost:9900
- **LiteLLM**: Configure via admin UI at http://localhost:4000

## 🐳 Deployment

### Individual Services

```bash
# Deploy specific services
make deploy-litellm      # LiteLLM proxy only
make deploy-vllm         # vLLM models only
make deploy-ragflow      # RAGFlow only
make deploy-xinference   # Xinference only

# Stop services
make stop-all
make stop-litellm
```

### Production Deployment

1. **Update configurations** for production settings
2. **Configure SSL/TLS** certificates
3. **Set up reverse proxy** (nginx/caddy)
4. **Configure monitoring** and alerting
5. **Set up backups** for databases

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [vLLM](https://github.com/vllm-project/vllm) - High-performance LLM serving
- [LiteLLM](https://github.com/BerriAI/litellm) - Unified LLM API
- [RAGFlow](https://github.com/infiniflow/ragflow) - RAG system
- [Xinference](https://github.com/xorbitsai/inference) - Model inference server
- [Qwen](https://github.com/QwenLM/Qwen) - Language models

---

For more detailed documentation, see the individual service directories and their respective README files.
