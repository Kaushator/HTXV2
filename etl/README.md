# ETL Pipeline

Extract, Transform, Load (ETL) pipelines for cryptocurrency data ingestion and processing.

## Features

- **Data Sources**: HTX, Coingecko, Cryptopanic APIs
- **Real-time Processing**: WebSocket connections for live data
- **Batch Processing**: Scheduled jobs for historical data
- **Data Validation**: Schema validation and data quality checks
- **Error Handling**: Retry mechanisms and dead letter queues
- **Monitoring**: Metrics and logging for pipeline health

## Components

### Data Extractors
- `htx_extractor.py` - HTX (Huobi) exchange data
- `coingecko_extractor.py` - CoinGecko market data
- `cryptopanic_extractor.py` - CryptoPanic news data
- `file_extractor.py` - CSV/XLSX file processing

### Data Transformers
- `price_transformer.py` - Price data normalization
- `news_transformer.py` - News sentiment analysis
- `volume_transformer.py` - Volume data aggregation

### Data Loaders
- `bigquery_loader.py` - Load to BigQuery
- `postgres_loader.py` - Load to PostgreSQL
- `gcs_loader.py` - Load to Google Cloud Storage

### Orchestration
- `scheduler.py` - Job scheduling and coordination
- `pipeline.py` - Pipeline orchestration
- `monitoring.py` - Health checks and metrics

## Usage

### Local Development
```bash
cd etl
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run specific extractor
python extractors/htx_extractor.py

# Run full pipeline
python pipeline.py --config dev.yaml
```

### Production Deployment
```bash
# Deploy as Cloud Run Job
gcloud run jobs deploy htx-etl \
  --image gcr.io/project-id/htx-etl:latest \
  --region us-central1

# Schedule with Cloud Scheduler
gcloud scheduler jobs create http htx-ingestion \
  --schedule="*/5 * * * *" \
  --uri="https://us-central1-project-id.cloudfunctions.net/htx-ingestion"
```

## Configuration

Configuration is managed through YAML files:
- `dev.yaml` - Development environment
- `staging.yaml` - Staging environment
- `prod.yaml` - Production environment

## Monitoring

Pipelines include comprehensive monitoring:
- **Metrics**: Data volume, processing time, error rates
- **Alerts**: Failed jobs, data quality issues
- **Dashboards**: Real-time pipeline status