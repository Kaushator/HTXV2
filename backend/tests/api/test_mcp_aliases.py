from fastapi.testclient import TestClient


def test_mcp_status_exists(client: TestClient):
    # No auth token provided -> expect not 404, typically 401
    resp = client.get("/api/v1/mcp/status")
    assert resp.status_code != 404


def test_mcp_tools_ok(client: TestClient):
    resp = client.get("/api/v1/mcp/tools")
    assert resp.status_code == 200
    data = resp.json()
    assert "endpoints" in data
    assert any(e.get("path") == "/api/v1/mcp/health" for e in data.get("endpoints", []))
