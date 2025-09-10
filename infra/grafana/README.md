# HTX Interface - Grafana Dashboards

This directory contains Grafana dashboard configurations and monitoring setup for the HTX Interface system.

## Quick Start

```bash
# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Access Grafana
open http://localhost:3000
# Login: admin / admin123
```

## Contents

### Dashboards
- `htx-system-overview.json` - Main system metrics and health
- `htx-websocket-monitoring.json` - WebSocket connections and real-time data
- `htx-database-performance.json` - Database and Redis performance

### Configuration
- `prometheus.yml` - Prometheus scrape configuration
- `htx_rules.yml` - Recording rules for better performance
- `docker-compose.monitoring.yml` - Complete monitoring stack
- `grafana-provisioning/` - Auto-provisioning configuration

### Documentation
- `../docs/grafana-dashboards-setup.md` - Complete setup guide

## Features

✅ **Real-time Monitoring**
- HTTP request rates and response times
- WebSocket connection tracking
- Error rates and service health

✅ **Performance Metrics**
- Database query performance
- Redis operations monitoring
- System resource utilization

✅ **Business Metrics**
- Active trading symbols
- Ticker message rates
- HTX API latency

✅ **Alerts & Notifications**
- Configurable alert thresholds
- Multiple notification channels
- Automated incident response

## Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ HTX Backend │────│  Prometheus  │────│   Grafana   │
│   :8000     │    │    :9090     │    │    :3000    │
└─────────────┘    └──────────────┘    └─────────────┘
       │                   │                   │
       │           ┌───────┴───────┐          │
       │           │               │          │
   ┌───▼────┐ ┌────▼────┐ ┌────────▼──┐      │
   │  Node  │ │ Redis   │ │PostgreSQL │      │
   │Exporter│ │Exporter │ │ Exporter  │      │
   │ :9100  │ │ :9121   │ │  :9187    │      │
   └────────┘ └─────────┘ └───────────┘      │
                                             │
                                    ┌────────▼────┐
                                    │ Alert       │
                                    │ Manager     │
                                    │ :9093       │
                                    └─────────────┘
```

## Requirements

- Docker & Docker Compose
- HTX Backend with `/metrics` endpoint
- PostgreSQL (optional)
- Redis (optional)

## Support

For detailed setup instructions, see [Grafana Dashboards Setup Guide](../docs/grafana-dashboards-setup.md)
