from fastapi.testclient import TestClient


def test_request_id_header_present(client: TestClient):
    r = client.get("/health")
    assert r.status_code == 200
    assert "x-request-id" in {k.lower(): v for k, v in r.headers.items()}


def test_404_structured_error(client: TestClient):
    r = client.get("/no_such_path")
    assert r.status_code == 404
    data = r.json()
    assert data["status"] == "error"
    assert data["error"]["code"] == "http_404"
    assert data["http_status"] == 404
    assert data["path"] == "/no_such_path"
    assert data.get("request_id")


def test_422_validation_error(client: TestClient):
    # POST endpoint expects JSON dict; send invalid body to trigger 422
    r = client.post("/api/coins", data="invalid")
    assert r.status_code == 422
    data = r.json()
    assert data["status"] == "error"
    assert data["error"]["code"] == "validation_error"
    assert data["http_status"] == 422
    assert data.get("request_id")

