from fastapi.testclient import TestClient


def test_metrics_endpoint_ok(client: TestClient):
    # touch a couple of endpoints to generate some metrics
    client.get("/health")
    client.get("/")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert r.headers.get("content-type", "").startswith("text/plain")
    body = r.text
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body


def test_errors_counter_on_404(client: TestClient):
    client.get("/surely-not-found")
    r = client.get("/metrics")
    assert r.status_code == 200
    text = r.text
    assert "http_errors_total" in text


def test_api_key_counter_with_prefix(client: TestClient):
    # Use a syntactically valid key with prefix
    key = "abcD1234.somesecretvalue"
    client.get(f"/health?api_key={key}")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "api_key_requests_total" in r.text
