FROM python:3.9-slim

# Install required packages
RUN apt-get update && apt-get install -y nginx default-mysql-client

# Set up application directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app/ /app/
COPY nginx.conf /etc/nginx/sites-available/default

# Make script executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 80
EXPOSE 80

# Set up entrypoint
ENTRYPOINT ["/entrypoint.sh"]