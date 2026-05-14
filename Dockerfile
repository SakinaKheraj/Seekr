# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Ensure logs appear in real-time in CloudWatch / docker logs
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install dependencies securely
RUN pip install --no-cache-dir -r requirements.txt

# Copy the server directory logic into the container
COPY server/ /app/server/

# Ensure the container listens on port 8000 (FastAPI internal port)
EXPOSE 8000

# Health check so Docker/EC2 knows when the app is ready
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# 2 Gunicorn workers = safe for t2.micro (1 vCPU, 1GB RAM)
# UvicornWorker preserves async/await support from FastAPI
CMD ["gunicorn", "server.main:app", \
     "-w", "2", \
     "-k", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
