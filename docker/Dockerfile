# Multi-stage build for security
# Stage 1: Builder
FROM python:3.12-slim-bookworm as builder

WORKDIR /app

# Install only build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime (minimal base)
FROM python:3.12-slim-bookworm

# Update all packages to latest security patches
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    nginx \
    default-mysql-client \
    iproute2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY app/ /app/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create non-root user for better security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Make sure Python packages are in PATH
ENV PATH=/root/.local/bin:$PATH

# Expose port
EXPOSE 80

# Run entrypoint
ENTRYPOINT ["/entrypoint.sh"]