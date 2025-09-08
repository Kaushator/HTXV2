FROM python:3.11-slim
WORKDIR /srv
RUN pip install fastapi uvicorn
COPY server.py .
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8055"]
