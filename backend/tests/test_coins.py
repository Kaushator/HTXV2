from fastapi.testclient import TestClient


def test_get_coins(client: TestClient):
    r = client.get("/api/coins")
    assert r.status_code == 200
    data = r.json()
    assert "coins" in data and isinstance(data["coins"], list)
    assert data["total"] == len(data["coins"]) == 3
    assert all({"symbol", "name", "source"} <= set(c.keys()) for c in data["coins"])


def test_add_and_remove_coin(client: TestClient):
    payload = {"symbol": "TEST", "name": "TestCoin", "source": "Manual"}
    r = client.post("/api/coins", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data["coin"]["symbol"] == "TEST"

    r = client.delete("/api/coins/TEST")
    assert r.status_code == 200
    msg = r.json()["message"].lower()
    assert "removed" in msg and "test" in msg

