import time
from typing import Optional

from prometheus_client import Counter, Histogram, Gauge, CONTENT_TYPE_LATEST, generate_latest
from fastapi import APIRouter
from fastapi.responses import Response


# Prometheus metrics
REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests",
    labelnames=("method", "path", "status"),
)

DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    labelnames=("method", "path", "status"),
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)

INPROGRESS = Gauge(
    "http_requests_in_progress",
    "In-progress HTTP requests",
)

ERRORS = Counter(
    "http_errors_total",
    "Total HTTP errors",
    labelnames=("method", "path", "status"),
)

API_KEY_REQUESTS = Counter(
    "api_key_requests_total",
    "API key scoped requests",
    labelnames=("key_prefix", "method", "status"),
)

API_KEY_ERRORS = Counter(
    "api_key_errors_total",
    "API key scoped errors",
    labelnames=("key_prefix", "method", "status"),
)


class MetricsMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):  # type: ignore[override]
        if scope.get("type") != "http":
            return await self.app(scope, receive, send)

        method: str = scope.get("method", "").upper()
        path: str = scope.get("path", "")
        start = time.perf_counter()
        INPROGRESS.inc()
        status_holder = {"value": 500}

        # Extract API key prefix from query or header (do not log full key)
        key_prefix = None
        # query string
        raw_q = scope.get("query_string", b"")
        try:
            q = raw_q.decode("utf-8") if isinstance(raw_q, (bytes, bytearray)) else str(raw_q)
        except Exception:
            q = ""
        if q and "api_key=" in q:
            try:
                from urllib.parse import parse_qs

                parsed = parse_qs(q, keep_blank_values=True)
                vals = parsed.get("api_key")
                if vals:
                    val = vals[0]
                    if isinstance(val, list):
                        val = val[0]
                    if isinstance(val, str) and "." in val:
                        key_prefix = val.split(".", 1)[0]
            except Exception:
                pass
        if not key_prefix:
            # headers
            for k, v in scope.get("headers", []) or []:
                if k == b"x-api-key":
                    try:
                        s = v.decode("utf-8", errors="ignore")
                        if "." in s:
                            key_prefix = s.split(".", 1)[0]
                    except Exception:
                        pass
                    break

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                status_holder["value"] = int(message.get("status", 200))
            if message["type"] == "http.response.body" and not message.get("more_body", False):
                dur = time.perf_counter() - start
                status = str(status_holder["value"])
                # Use raw path to avoid heavy route resolution; acceptable for now
                REQUESTS.labels(method=method, path=path, status=status).inc()
                DURATION.labels(method=method, path=path, status=status).observe(dur)
                if status_holder["value"] >= 400:
                    ERRORS.labels(method=method, path=path, status=status).inc()
                if key_prefix:
                    API_KEY_REQUESTS.labels(key_prefix=key_prefix, method=method, status=status).inc()
                    if status_holder["value"] >= 400:
                        API_KEY_ERRORS.labels(key_prefix=key_prefix, method=method, status=status).inc()
                INPROGRESS.dec()
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        except Exception:
            # Count as 500 if exception bubbles up
            dur = time.perf_counter() - start
            REQUESTS.labels(method=method, path=path, status="500").inc()
            DURATION.labels(method=method, path=path, status="500").observe(dur)
            ERRORS.labels(method=method, path=path, status="500").inc()
            INPROGRESS.dec()
            raise


router = APIRouter()


@router.get("/metrics")
async def metrics_endpoint() -> Response:
    data = generate_latest()
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)
