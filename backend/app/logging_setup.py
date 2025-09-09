import json
import logging
import sys
from datetime import datetime
from typing import Any, Dict, Optional
import contextvars


# Request-scoped context
request_id_var: contextvars.ContextVar[Optional[str]] = contextvars.ContextVar("request_id", default=None)


class JsonFormatter(logging.Formatter):
    """Simple JSON formatter without extra deps.

    Adds common fields and passes through any extra attributes set on the log record
    (e.g., method, path, status_code, duration_ms, client_ip, user_agent, request_id).
    """

    def format(self, record: logging.LogRecord) -> str:  # type: ignore[override]
        payload: Dict[str, Any] = {
            "ts": datetime.utcnow().isoformat(timespec="milliseconds") + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        # Attach request_id if present in context or record extras
        rid = getattr(record, "request_id", None) or request_id_var.get()
        if rid:
            payload["request_id"] = rid

        # Copy select extras from record.__dict__
        for key in (
            "event",
            "method",
            "path",
            "query",
            "status_code",
            "duration_ms",
            "client_ip",
            "user_agent",
            "version",
        ):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value

        # Include exception info if present
        if record.exc_info:
            payload["exc_type"] = record.exc_info[0].__name__ if record.exc_info[0] else None
            payload["exc_text"] = self.formatException(record.exc_info)

        return json.dumps(payload, ensure_ascii=False)


def setup_logging(level: str = "INFO") -> None:
    """Configure root and uvicorn loggers with JSON formatter.

    This keeps a single console handler to avoid duplicate lines and reduces
    noise from uvicorn.access (we emit our own structured access logs).
    """
    root = logging.getLogger()
    root.setLevel(level)

    # Remove pre-existing handlers (e.g., from uvicorn default config)
    for h in list(root.handlers):
        root.removeHandler(h)

    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setLevel(level)
    handler.setFormatter(JsonFormatter())
    root.addHandler(handler)

    # Tune specific loggers
    logging.getLogger("uvicorn").setLevel(level)
    logging.getLogger("uvicorn.error").setLevel(level)

    # Reduce default access noise; our middleware logs structured access entries
    logging.getLogger("uvicorn.access").setLevel("WARNING")

    # App loggers
    logging.getLogger("htx").setLevel(level)
    logging.getLogger("htx.api").setLevel(level)
    logging.getLogger("htx.access").setLevel(level)

