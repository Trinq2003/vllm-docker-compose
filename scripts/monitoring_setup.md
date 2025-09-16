# 📊 Monitoring Setup Guide

This guide explains how to set up comprehensive monitoring for the Deployment Repository.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Prometheus    │
│    Services     │───►│   (Metrics)     │
└─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│     Grafana     │    │    Alerting     │
│   (Dashboards)  │    │   (Notifications)|
└─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- Docker and Docker Compose
- At least 2GB RAM for monitoring stack
- Network access to send alerts (optional)

## 🚀 Quick Start

### 1. Start Monitoring Stack

```bash
# Using the provided Makefile
make setup-monitoring

# Or manually
docker-compose -f docker-compose.monitoring.yml up -d
```

### 2. Access Monitoring Interfaces

- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `admin` (change on first login)

- **Prometheus**: http://localhost:9090

- **Alert Manager**: http://localhost:9093

### 3. Import Dashboards

1. Open Grafana at http://localhost:3000
2. Go to **Dashboards** → **Import**
3. Import the dashboard JSON files from `monitoring/dashboards/`

## 📈 Metrics Collection

### Application Metrics

The platform collects metrics from:

- **LiteLLM Proxy**: Request count, latency, error rates
- **vLLM Services**: GPU utilization, inference latency, queue depth
- **Xinference**: Model loading status, inference metrics
- **RAGFlow**: Document processing, search performance
- **System Resources**: CPU, memory, disk, network usage

### Custom Metrics

Additional custom metrics are available:

```python
from prometheus_client import Counter, Histogram, Gauge

# Request metrics
REQUEST_COUNT = Counter('llm_requests_total', 'Total LLM requests', ['model', 'status'])
REQUEST_LATENCY = Histogram('llm_request_duration_seconds', 'Request latency', ['model'])

# Resource metrics
GPU_UTILIZATION = Gauge('gpu_utilization_percent', 'GPU utilization percentage', ['gpu_id'])
MEMORY_USAGE = Gauge('memory_usage_bytes', 'Memory usage in bytes', ['type'])
```

## 📊 Pre-built Dashboards

### 1. System Overview Dashboard

Shows:
- Overall system health status
- Resource utilization (CPU, memory, disk)
- Network traffic and errors
- Service availability

### 2. LLM Performance Dashboard

Displays:
- Model inference latency
- Request throughput by model
- Error rates and types
- GPU utilization per model
- Queue depth and wait times

### 3. Application Metrics Dashboard

Includes:
- API endpoint performance
- Database connection pools
- Cache hit rates
- Background job status

## 🚨 Alerting Configuration

### Alert Rules

Pre-configured alerts include:

```yaml
# High error rate alert
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value }}% for {{ $labels.service }}"

# GPU utilization alert
- alert: HighGPUUtilization
  expr: gpu_utilization_percent > 95
  for: 10m
  labels:
    severity: critical
  annotations:
    summary: "High GPU utilization"
    description: "GPU {{ $labels.gpu_id }} utilization is {{ $value }}%"
```

### Alert Channels

Configure alert notifications:

#### Slack Integration

```yaml
slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#alerts'
    title: '{{ .GroupLabels.alertname }}'
    text: '{{ .CommonAnnotations.description }}'
```

#### Email Notifications

```yaml
email_configs:
  - to: 'admin@example.com'
    from: 'alerts@example.com'
    smarthost: 'smtp.example.com:587'
    auth_username: 'alerts@example.com'
    auth_password: 'your-password'
```

## 🔧 Configuration Files

### Prometheus Configuration

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'litellm'
    static_configs:
      - targets: ['litellm:4000']
    metrics_path: '/metrics'

  - job_name: 'vllm'
    static_configs:
      - targets: ['vllm-qwen25:8000', 'vllm-qwen3:8000']
    metrics_path: '/metrics'

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Grafana Provisioning

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true

  - name: Loki
    type: loki
    url: http://loki:3100
```

## 📊 Custom Dashboards

### Creating Custom Dashboards

1. **Access Grafana**: http://localhost:3000
2. **Create Dashboard**: Click "+" → "New Dashboard"
3. **Add Panels**: Choose visualization type
4. **Configure Queries**: Use PromQL for Prometheus metrics

### Example Queries

```promql
# Request rate by model
rate(llm_requests_total[5m])

# Average latency by model
histogram_quantile(0.95, rate(llm_request_duration_seconds_bucket[5m]))

# GPU memory usage
gpu_memory_used_bytes / gpu_memory_total_bytes * 100

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

## 🔍 Troubleshooting

### Common Issues

#### Metrics Not Appearing

1. Check if services are running:
   ```bash
   docker-compose ps
   ```

2. Verify Prometheus targets:
   - Visit http://localhost:9090/targets
   - Check endpoint status

3. Check service logs:
   ```bash
   docker-compose logs prometheus
   ```

#### Alerts Not Working

1. Verify Alertmanager configuration
2. Check alert rules syntax
3. Test notification channels

#### High Resource Usage

1. Adjust scrape intervals in `prometheus.yml`
2. Reduce retention period
3. Scale monitoring resources

### Debugging Commands

```bash
# Check Prometheus health
curl http://localhost:9090/-/healthy

# Query metrics
curl "http://localhost:9090/api/v1/query?query=up"

# Check Grafana logs
docker-compose logs grafana

# Validate configuration
promtool check config /etc/prometheus/prometheus.yml
```

## 📚 Advanced Configuration

### High Availability Setup

For production deployments:

1. **Prometheus Federation**: Multiple Prometheus instances
2. **Thanos**: Long-term storage and querying
3. **Cortex**: Horizontally scalable Prometheus
4. **Grafana HA**: Multiple Grafana instances

### Security Considerations

- Enable authentication for Grafana
- Use HTTPS for all monitoring endpoints
- Restrict network access to monitoring ports
- Regularly update monitoring stack versions

### Performance Tuning

```yaml
# Prometheus performance tuning
global:
  scrape_interval: 30s  # Increase from 15s for lower resource usage
  evaluation_interval: 30s

# Storage settings
storage:
  tsdb:
    retention.time: 30d  # Adjust based on disk space
    wal_compression: true
```

## 📖 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Monitoring Best Practices](https://prometheus.io/docs/practices/)

---

For issues or questions about monitoring setup, please check the [troubleshooting](#-troubleshooting) section or create an issue in the repository.
