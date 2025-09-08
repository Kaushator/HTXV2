FROM python:3.11-slim
WORKDIR /app
COPY pyproject.toml /app/
RUN pip install --upgrade pip && pip install -e .[dev]
COPY app /app/app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
