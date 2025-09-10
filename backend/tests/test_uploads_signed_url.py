from fastapi.testclient import TestClient


def test_signed_url_csv_success(client: TestClient):
    payload = {
        "filename": "data.csv",
        "content_type": "text/csv",
        "size_bytes": 1024,
    }
    r = client.post("/api/data/upload/request-signed-url", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["method"] == "PUT"
    assert data["headers"]["Content-Type"] == "text/csv"
    assert data["upload_url"].startswith("https://upload.invalid/")
    assert data["object_key"].endswith("/data.csv")


def test_signed_url_xlsx_success(client: TestClient):
    payload = {
        "filename": "report.xlsx",
        "content_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "size_bytes": 2048,
    }
    r = client.post("/api/data/upload/request-signed-url", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["headers"]["Content-Type"].startswith("application/vnd.openxmlformats-officedocument")
    assert data["object_key"].endswith("/report.xlsx")


def test_signed_url_invalid_extension(client: TestClient):
    payload = {
        "filename": "image.png",
        "content_type": "text/csv",
        "size_bytes": 100,
    }
    r = client.post("/api/data/upload/request-signed-url", json=payload)
    assert r.status_code == 400
    data = r.json()
    assert data["status"] == "error"
    assert data["error"]["code"] == "http_400"


def test_signed_url_invalid_content_type(client: TestClient):
    payload = {
        "filename": "data.csv",
        "content_type": "application/octet-stream",
    }
    r = client.post("/api/data/upload/request-signed-url", json=payload)
    assert r.status_code == 400
    data = r.json()
    assert data["status"] == "error"
    assert data["error"]["code"] == "http_400"


def test_signed_url_too_large(client: TestClient, monkeypatch):
    # Reduce max size for the test
    from app import config as cfg

    monkeypatch.setattr(cfg.settings, "uploads_max_size_mb", 1, raising=False)  # 1 MB

    payload = {
        "filename": "big.csv",
        "content_type": "text/csv",
        "size_bytes": 2 * 1024 * 1024,  # 2 MB
    }
    r = client.post("/api/data/upload/request-signed-url", json=payload)
    assert r.status_code == 400
    data = r.json()
    assert data["status"] == "error"
    assert data["error"]["code"] == "http_400"

