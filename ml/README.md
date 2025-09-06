# ML/LLM Stack

Machine Learning and Large Language Model components for cryptocurrency analysis and trading signals.

## Features

- **Local FinGPT**: LoRA-adapted model running in Docker
- **Vertex AI Integration**: Cloud-based models (Gemini, Text-Bison)
- **OpenAI Integration**: Fallback provider for high-quality responses
- **Vector Search**: BigQuery Vector Search for RAG capabilities
- **Feature Engineering**: Technical indicators and market features
- **Signal Generation**: ML-powered trading signals
- **Sentiment Analysis**: News and social media sentiment

## Components

### Models
- `fingpt/` - Local FinGPT model with LoRA adapters
- `vertex_ai/` - Vertex AI model wrappers
- `openai_client.py` - OpenAI API client

### Feature Engineering
- `technical_indicators.py` - Technical analysis features
- `market_features.py` - Market structure features
- `sentiment_features.py` - Sentiment analysis features
- `embedding_generator.py` - Text embeddings for RAG

### Signal Generation
- `signal_generator.py` - Main signal generation pipeline
- `ml_models/` - Trained ML models for prediction
- `backtester.py` - Strategy backtesting framework

### Services
- `llm_selector.py` - LLM provider selection logic
- `model_server.py` - Model serving API
- `prediction_service.py` - Prediction endpoints

## Local FinGPT Setup

### Prerequisites
- NVIDIA GPU with CUDA support
- Docker with GPU support
- At least 8GB VRAM

### Setup
```bash
cd ml/fingpt
docker build -t fingpt:latest .
docker run --gpus all -p 8080:8080 fingpt:latest
```

### Usage
```python
from ml.services.llm_selector import LLMSelector

selector = LLMSelector()
response = await selector.generate_analysis(
    prompt="Analyze Bitcoin price movement",
    context="BTC is currently at $45,000..."
)
```

## Vertex AI Setup

1. Enable Vertex AI APIs in GCP
2. Set up service account credentials
3. Deploy models to Vertex AI Endpoints

```bash
# Deploy model to Vertex AI
gcloud ai models deploy $MODEL_ID \
  --region=us-central1 \
  --endpoint=$ENDPOINT_ID
```

## Vector Search

The system supports vector search for RAG capabilities:

```python
from ml.services.vector_search import VectorSearchService

search = VectorSearchService()
results = await search.similarity_search(
    query="Bitcoin price prediction",
    top_k=10
)
```

## Training Pipeline

Train custom models using Vertex AI Pipelines:

```bash
python training/train_price_prediction.py \
  --config config/training.yaml \
  --experiment-name price-prediction-v1
```

## Monitoring

All models include comprehensive monitoring:
- **Performance Metrics**: Accuracy, precision, recall
- **Drift Detection**: Data and concept drift monitoring
- **A/B Testing**: Model comparison and selection
- **Explainability**: Feature importance and model explanations