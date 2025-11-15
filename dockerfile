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
# Ensure the database directory (if any) is writable and create a persistent data mount
RUN mkdir -p /app/instance /data || true
VOLUME ["/data"]

# Runtime defaults (can be overridden by environment variables)
ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE=/data/hms.db
EXPOSE 8080

# Create an entrypoint script that writes `config.json` from env vars and starts gunicorn
RUN cat > /entrypoint.sh << 'EOF' \
#!/bin/sh
set -e

# Ensure data directory exists
mkdir -p /data

# Write config.json so the app can read host/port/database as before
cat > /app/config.json <<JSON
{"host":"${HOST}","port":${PORT},"database":"${DATABASE}"}
JSON

# Ensure the database file exists (SQLite)
touch "${DATABASE}"

# Execute gunicorn as the container PID 1
exec gunicorn --bind "0.0.0.0:${PORT}" --workers 3 --threads 2 app:app
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
