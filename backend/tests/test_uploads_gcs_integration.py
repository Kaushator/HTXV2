from fastapi.testclient import TestClient


def test_signed_url_uses_gcs_when_configured(monkeypatch, client: TestClient):
    # Configure bucket
    from app import config as cfg

    monkeypatch.setattr(cfg.settings, "uploads_gcs_bucket", "my-bucket", raising=False)

    # Patch generator to avoid real GCS call
    from app.services import uploads as svc_uploads

    def fake_gen(bucket_name: str, object_key: str, content_type: str, expires_seconds: int):
        assert bucket_name == "my-bucket"
        assert content_type in ("text/csv", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        assert expires_seconds > 0
        return f"https://storage.googleapis.com/{bucket_name}/{object_key}?X-Goog-Signature=fake"

    monkeypatch.setattr(svc_uploads, "generate_gcs_signed_put_url", fake_gen)

    payload = {
        "filename": "data.csv",
        "content_type": "text/csv",
        "size_bytes": 1024,
    }
    r = client.post("/api/data/upload/request-signed-url", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["upload_url"].startswith("https://storage.googleapis.com/")
    assert data["object_key"].endswith("/data.csv")

