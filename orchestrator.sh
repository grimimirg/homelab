#!/bin/bash

PARENT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$PARENT_DIR" || exit 1

echo "Starting Homelab Orchestrator..."

if ! docker network inspect homelab_net >/dev/null 2>&1; then
    echo "Creating network 'homelab_net'..."
    docker network create homelab_net
else
    echo "Network 'homelab_net' already exists."
fi

echo "Starting Database..."
docker-compose -f db/docker-compose.yaml up -d
echo "Waiting for Database to initialize..."
sleep 5

echo "Starting Nginx..."
docker-compose -f nginx/docker-compose.yaml up -d
sleep 5

echo "Starting n8n..."
docker-compose -f n8n/docker-compose.yaml up -d
sleep 5

echo "Starting Synapse..."
docker-compose -f synapse/docker-compose.yaml up -d
sleep 5

echo "Orchestration complete! All services are now running."
echo "Check their status with: docker-compose -f <folder>/docker-compose.yaml ps"
