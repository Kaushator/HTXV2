# Backend API

FastAPI-based backend with SQLAlchemy, PostgreSQL, and pgvector integration.

## Features

- **FastAPI**: Modern, fast web framework
- **SQLAlchemy**: ORM with async support
- **PostgreSQL**: Primary database with pgvector extension
- **Redis**: Caching and session storage
- **Alembic**: Database migrations
- **Authentication**: JWT-based auth with Google OAuth2
- **WebSocket**: Real-time data streaming
- **Background Tasks**: Celery integration
- **API Documentation**: Automatic OpenAPI/Swagger docs

## Setup

1. Create virtual environment:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Run database migrations:
   ```bash
   alembic upgrade head
   ```

5. Start the development server:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Testing

Run tests with pytest:
```bash
pytest tests/
```

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── core/                # Core configuration and utilities
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── api/                 # API endpoints
│   ├── services/            # Business logic
│   ├── db/                  # Database utilities
│   └── utils/               # Utility functions
├── tests/                   # Test files
├── alembic/                 # Database migrations
├── requirements.txt         # Python dependencies
└── .env.example            # Environment variables template
```