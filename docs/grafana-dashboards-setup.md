# HTX Interface - Grafana Dashboards Setup Guide

## Overview
This guide provides complete setup instructions for Grafana dashboards to monitor the HTX Interface system, including WebSocket connections, database performance, and system metrics.

## Quick Start

### 1. Prerequisites
- Docker and Docker Compose installed
- HTX Interface backend running with metrics endpoint (`/metrics`)
- PostgreSQL and Redis running (if used)

### 2. Start Monitoring Stack
```bash
cd infra/grafana
docker-compose -f docker-compose.monitoring.yml up -d
```

### 3. Access Grafana
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin123`

## Dashboard Overview

### Available Dashboards

1. **HTX Interface - System Overview** (`htx-system-overview.json`)
   - Request rate and response times
   - Error rates and service health
   - CPU and memory usage
   - WebSocket connections and message rates

2. **HTX Interface - WebSocket Monitoring** (`htx-websocket-monitoring.json`)
   - WebSocket connection metrics
   - Message processing rates
   - Ticker data distribution
   - Connection errors and latency

3. **HTX Interface - Database & Performance** (`htx-database-performance.json`)
   - PostgreSQL connection pools
   - Query performance and latency
   - Redis operations and memory usage
   - Database query distribution

## Manual Dashboard Import

If automatic provisioning doesn't work, import dashboards manually:

### 1. Open Grafana UI
Navigate to http://localhost:3000 and log in

### 2. Import Dashboard
1. Click the "+" icon in the sidebar
2. Select "Import"
3. Upload the JSON file or paste the content
4. Configure data source (select "Prometheus")
5. Click "Import"

### 3. Required Data Sources
Ensure these data sources are configured:
- **Prometheus**: http://prometheus:9090 (or http://localhost:9090 for local)

## Dashboard Configuration

### Prometheus Configuration
The dashboards expect these metric names from your backend:

#### HTTP Metrics
```
http_requests_total{method, endpoint, status}
http_request_duration_seconds_bucket{method, endpoint}
http_requests_active
```

#### WebSocket Metrics
```
websocket_connections_active
websocket_connections_total
websocket_messages_sent_total
websocket_messages_received_total
websocket_message_duration_seconds_bucket
websocket_errors_total{error_type}
ticker_messages_sent_total{symbol}
```

#### Database Metrics
```
database_query_duration_seconds_bucket{query_type}
postgresql_connections_active
postgresql_connections_idle
postgresql_max_connections
postgresql_queries_total{query_type}
```

#### Redis Metrics
```
redis_commands_total{command}
redis_memory_used_bytes
redis_memory_max_bytes
redis_keys_total{db}
```

#### External Service Metrics
```
htx_api_latency_seconds
ticker_update_interval_seconds
```

### Backend Integration

Add to your FastAPI backend (`app/metrics.py`):

```python
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import time

# HTTP metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
ACTIVE_REQUESTS = Gauge('http_requests_active', 'Active HTTP requests')

# WebSocket metrics
WS_CONNECTIONS = Gauge('websocket_connections_active', 'Active WebSocket connections')
WS_MESSAGES_SENT = Counter('websocket_messages_sent_total', 'WebSocket messages sent')
WS_ERRORS = Counter('websocket_errors_total', 'WebSocket errors', ['error_type'])
TICKER_MESSAGES = Counter('ticker_messages_sent_total', 'Ticker messages sent', ['symbol'])

# Database metrics
DB_QUERY_DURATION = Histogram('database_query_duration_seconds', 'Database query duration', ['query_type'])

# External service metrics
HTX_API_LATENCY = Gauge('htx_api_latency_seconds', 'HTX API latency')

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

## Customization

### Adding Custom Panels

1. **Clone Existing Panel**
   - Right-click on a panel → "More" → "Duplicate"
   - Modify the query and visualization settings

2. **Create New Panel**
   - Click "Add panel" in dashboard edit mode
   - Choose visualization type
   - Write Prometheus query
   - Configure display options

### Common Queries

#### Request Rate by Endpoint
```promql
rate(http_requests_total{job="htx-backend"}[5m])
```

#### 95th Percentile Response Time
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="htx-backend"}[5m])) * 1000
```

#### Error Rate Percentage
```promql
rate(http_requests_total{job="htx-backend",status=~"4..|5.."}[5m]) / rate(http_requests_total{job="htx-backend"}[5m]) * 100
```

#### WebSocket Message Rate by Symbol
```promql
rate(ticker_messages_sent_total{job="htx-backend"}[5m])
```

### Variable Configuration

Add dashboard variables for dynamic filtering:

1. **Environment Variable**
   - Name: `environment`
   - Type: `Query`
   - Query: `label_values(up, environment)`

2. **Service Variable**
   - Name: `service`
   - Type: `Query`
   - Query: `label_values(up{environment="$environment"}, job)`

Use variables in queries: `{job="$service", environment="$environment"}`

## Alerting

### Alert Rules Configuration

Create alerting rules in `htx_alerts.yml`:

```yaml
groups:
  - name: htx_alerts
    rules:
      - alert: HighErrorRate
        expr: htx:error_rate_5m > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% for the last 5 minutes"

      - alert: HighResponseTime
        expr: htx:response_time_p95_5m > 1000
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}ms"

      - alert: WebSocketConnectionsHigh
        expr: websocket_connections_active > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High WebSocket connection count"
          description: "{{ $value }} active WebSocket connections"
```

### Notification Channels

Configure in Grafana UI:
1. Go to Alerting → Notification channels
2. Add new channel (Slack, Email, Webhook)
3. Test the configuration
4. Link to alert rules

## Troubleshooting

### Common Issues

1. **No Data in Dashboards**
   - Check Prometheus targets: http://localhost:9090/targets
   - Verify metrics endpoint: http://localhost:8000/metrics
   - Ensure correct job names in Prometheus config

2. **Connection Refused Errors**
   - Check if services are running: `docker-compose ps`
   - Verify network connectivity between containers
   - Check firewall settings

3. **Dashboard Import Fails**
   - Verify JSON syntax
   - Check data source configuration
   - Ensure Grafana version compatibility

4. **Metrics Not Updating**
   - Check scrape interval in prometheus.yml
   - Verify backend metrics implementation
   - Look for errors in Prometheus logs

### Debug Commands

```bash
# Check running containers
docker-compose -f docker-compose.monitoring.yml ps

# View Prometheus logs
docker logs htx-prometheus

# View Grafana logs
docker logs htx-grafana

# Check Prometheus configuration
curl http://localhost:9090/api/v1/status/config

# Test metrics endpoint
curl http://localhost:8000/metrics
```

## Performance Optimization

### Recording Rules
Pre-calculate complex queries using recording rules in `htx_rules.yml`:

```yaml
- record: htx:request_rate_5m
  expr: rate(http_requests_total{job="htx-backend"}[5m])
```

Use in dashboards: `htx:request_rate_5m` instead of complex rate calculation.

### Dashboard Performance
- Use appropriate time ranges
- Limit the number of series in queries
- Use recording rules for complex calculations
- Set reasonable refresh intervals

## Security

### Access Control
- Change default Grafana password
- Configure authentication (LDAP, OAuth)
- Set up role-based access control
- Use HTTPS in production

### Network Security
- Restrict Prometheus scrape targets
- Use authentication for metrics endpoints
- Configure firewall rules
- Monitor access logs

## Production Deployment

### High Availability
- Deploy multiple Grafana instances behind load balancer
- Use external database for Grafana (PostgreSQL/MySQL)
- Set up Prometheus federation for multiple instances
- Configure persistent storage for metrics

### Backup Strategy
- Regular backups of Grafana database
- Export dashboard configurations
- Backup Prometheus data directory
- Document restoration procedures

## Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [FastAPI Metrics](https://fastapi.tiangolo.com/advanced/custom-request-and-route/)
- [Prometheus Python Client](https://github.com/prometheus/client_python)
