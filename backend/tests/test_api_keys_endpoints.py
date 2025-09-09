from fastapi.testclient import TestClient


def test_api_keys_not_implemented_without_db(client: TestClient):
    # Without DATABASE_URL configured, endpoints should respond 501
    r1 = client.get("/api/keys/")
    assert r1.status_code == 501
    j1 = r1.json()
    assert j1["status"] == "error"
    assert j1["error"]["code"] == "http_501"

    r2 = client.post("/api/keys/", json={"name": "test"})
    assert r2.status_code == 501
    j2 = r2.json()
    assert j2["error"]["code"] == "http_501"

    r3 = client.post("/api/keys/abc/disable")
    assert r3.status_code == 501
    r4 = client.post("/api/keys/abc/enable")
    assert r4.status_code == 501
