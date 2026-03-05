#!/bin/bash

echo "Starting Homelab..."

source .env

if ! docker network inspect homelab_net >/dev/null 2>&1; then
    echo "Creating network 'homelab_net'..."
    docker network create homelab_net
else
    echo "Network 'homelab_net' already exists."
fi

echo "Starting Database..."
docker-compose -f db/docker-compose.yaml up -d
echo "Waiting for Database to initialize..."

echo "Waiting for Postgres to be ready..."
# Wait until the container is ready
until docker exec shared_postgres pg_isready -U postgres_user; do
  echo "Postgres is unavailable - sleeping"
  sleep 2
done

echo "Database is up! Provisioning..."
./init-db.sh

check_and_create_db "gitea"
check_and_create_db "paperless"

echo "Starting Nginx..."
docker-compose -f nginx/docker-compose.yaml up -d
sleep 5

echo "Starting n8n..."
docker-compose -f n8n/docker-compose.yaml up -d
sleep 5

echo "Starting Synapse..."
docker-compose -f synapse/docker-compose.yaml up -d
sleep 5

echo "Starting Gitea..."
docker-compose -f gitea/docker-compose.yaml up -d
sleep 5

echo "Starting Navidrome..."
docker-compose -f navidrome/docker-compose.yaml up -d
sleep 5

echo "Starting Paperless..."
docker-compose -f paperless/docker-compose.yaml up -d
sleep 5

echo "Complete! All services are now running."
echo "Check their status with: docker-compose -f <folder>/docker-compose.yaml ps"
