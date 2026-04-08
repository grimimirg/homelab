#!/bin/bash

echo "Starting Homelab..."

source .env

if ! docker network inspect "$SHARED_NETWORK" >/dev/null 2>&1; then
    echo "Creating network $SHARED_NETWORK..."
    docker network create "$SHARED_NETWORK"
else
    echo "Network $SHARED_NETWORK already exists."
fi

echo "Starting Database..."
docker compose -f db/docker-compose.yaml up -d
echo "Waiting for Database to initialize..."

echo "Waiting for Postgres to be ready..."
# Wait until the container is ready
until docker exec shared_postgres pg_isready -U "$POSTGRES_USER"; do
  echo "Postgres is unavailable - sleeping"
  sleep 5
done

echo "Database is up! Provisioning..."
./init-db.sh

echo "Starting n8n..."
docker compose -f n8n/docker-compose.yaml up -d

echo "Starting Synapse..."
docker compose -f synapse/docker-compose.yaml up -d

echo "Starting Gitea..."
docker compose -f gitea/docker-compose.yaml up -d

echo "Starting Navidrome..."
docker compose -f navidrome/docker-compose.yaml up -d

echo "Starting Paperless..."
docker compose -f paperless/docker-compose.yaml up -d

sleep 2

echo "Starting Nginx..."
docker compose -f nginx/docker-compose.yaml up -d

echo "Complete! All services are now running."
echo "Check their status with: docker-compose -f <folder>/docker-compose.yaml ps"
