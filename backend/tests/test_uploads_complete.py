from fastapi.testclient import TestClient


def test_upload_complete_stub_persists_false_when_no_db(monkeypatch, client: TestClient):
    # No DB configured; no GCS bucket — should return ok with persisted=false
    from app import config as cfg

    monkeypatch.setattr(cfg.settings, "uploads_gcs_bucket", None, raising=False)

    r = client.post("/api/data/upload/complete", json={"object_key": "uploads/abc/file.csv", "size_bytes": 10, "content_type": "text/csv"})
    assert r.status_code == 200
    j = r.json()
    assert j["status"] == "ok"
    assert j["object_key"].endswith("file.csv")
    assert j["persisted"] is False


def test_upload_complete_verification(monkeypatch, client: TestClient):
    from app.services import uploads_meta
    from app import config as cfg

    # Simulate bucket configured
    monkeypatch.setattr(cfg.settings, "uploads_gcs_bucket", "my-bucket", raising=False)

    class Res:
        def __init__(self):
            self.ok = True
            self.size = 100
            self.content_type = "text/csv"

    async def fake_verify(**kwargs):  # type: ignore
        return Res()

    monkeypatch.setattr(uploads_meta, "verify_gcs_object", fake_verify)

    r = client.post(
        "/api/data/upload/complete",
        json={"object_key": "uploads/abc/file.csv", "size_bytes": 100, "content_type": "text/csv"},
    )
    assert r.status_code == 200
    j = r.json()
    assert j["verified"] is True
    assert j["size_bytes"] == 100
    assert j["content_type"] == "text/csv"

