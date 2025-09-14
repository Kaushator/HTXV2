"""
API endpoint tests for HTXV2 trading endpoints.
"""

import pytest
from fastapi.testclient import TestClient


def test_trading_endpoints_exist(client: TestClient):
    """Test that trading endpoints exist (even if they return errors due to missing auth)."""
    # Test that endpoints exist and don't return 404
    endpoints = [
        "/api/v1/trading/markets",
        "/api/v1/trading/tickers",
        "/api/v1/trading/orders",
    ]

    for endpoint in endpoints:
        response = client.get(endpoint)
        # Should not be 404 (not found), can be 401/403 (auth required) or 422 (validation)
        assert response.status_code != 404, f"Endpoint {endpoint} not found"


def test_portfolio_endpoints_exist(client: TestClient):
    """Test that portfolio endpoints exist."""
    endpoints = [
        "/api/v1/portfolio/positions",
        "/api/v1/portfolio/balance",
        "/api/v1/portfolio/history",
    ]

    for endpoint in endpoints:
        response = client.get(endpoint)
        # Should not be 404 (not found)
        assert response.status_code != 404, f"Endpoint {endpoint} not found"


def test_auth_endpoints_exist(client: TestClient):
    """Test that auth endpoints exist."""
    # GET endpoints
    get_endpoints = ["/api/v1/auth/me"]

    for endpoint in get_endpoints:
        response = client.get(endpoint)
        assert response.status_code != 404, f"Endpoint {endpoint} not found"

    # POST endpoints that should accept data
    post_endpoints = ["/api/v1/auth/login", "/api/v1/auth/register"]

    for endpoint in post_endpoints:
        response = client.post(endpoint, json={})
        # Should not be 404, can be 422 for invalid data
        assert response.status_code != 404, f"Endpoint {endpoint} not found"


def test_data_endpoints_exist(client: TestClient):
    """Test that data endpoints exist."""
    endpoints = ["/api/v1/data/upload", "/api/v1/data/files"]

    for endpoint in endpoints:
        response = client.get(endpoint)
        assert response.status_code != 404, f"Endpoint {endpoint} not found"


def test_mcp_endpoints_exist(client: TestClient):
    """Test that MCP endpoints exist."""
    endpoints = ["/api/v1/mcp/status", "/api/v1/mcp/tools"]

    for endpoint in endpoints:
        response = client.get(endpoint)
        assert response.status_code != 404, f"Endpoint {endpoint} not found"
