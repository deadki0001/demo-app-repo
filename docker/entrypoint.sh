#!/bin/bash
set -e

# Start Nginx
service nginx start

# Start Flask application with Gunicorn
cd /app
gunicorn --bind 0.0.0.0:5000 app:app