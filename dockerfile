# Dockerfile for Fly.io deployment of the HMS Flask app
# Uses a slim Python base, installs requirements and runs gunicorn

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies needed by some Python packages (kept minimal)
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app

# Ensure the database directory (if any) is writable
RUN mkdir -p /app/instance || true

# Fly.io provides the port via the $PORT env var. Default to 8080 if not set.
ENV PORT 8080
EXPOSE 8080

# Use gunicorn to serve the Flask app defined in app.py (app:app)
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "--workers", "3", "--threads", "2", "app:app"]
