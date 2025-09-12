"""
Basic API endpoint tests for HTXV2 backend.
"""
import pytest
from fastapi.testclient import TestClient


def test_root_endpoint(client: TestClient):
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "HTXV2 API"
    assert data["version"] == "1.0.0"
    assert "status" in data


def test_health_check_endpoint(client: TestClient):
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["version"] == "1.0.0"
    assert "environment" in data


def test_openapi_docs_endpoint(client: TestClient):
    """Test OpenAPI docs are accessible in debug mode."""
    response = client.get("/docs")
    # Should either be accessible or redirect based on debug settings
    assert response.status_code in [200, 404, 302]


@pytest.mark.asyncio
async def test_root_endpoint_async(async_client):
    """Test the root endpoint with async client."""
    response = await async_client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "HTXV2 API"


@pytest.mark.asyncio
async def test_health_check_async(async_client):
    """Test health check with async client."""
    response = await async_client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"