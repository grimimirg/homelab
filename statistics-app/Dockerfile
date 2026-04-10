FROM python:3.11-slim

WORKDIR /app

# Install docker group dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY docker-stats-api.py .

EXPOSE 5000

CMD ["python", "docker-stats-api.py"]
