from fastapi.testclient import TestClient


def test_get_analysis(client: TestClient):
    r = client.get("/api/analysis/BTC")
    assert r.status_code == 200
    data = r.json()
    assert data["symbol"] == "BTC"
    assert "analysis" in data and isinstance(data["analysis"], str)
    assert "confidence" in data and 0 <= data["confidence"] <= 1
    assert isinstance(data.get("signals", []), list)

