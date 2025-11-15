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
