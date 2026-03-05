#!/bin/bash

PARENT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$PARENT_DIR" || exit 1

echo "WARNING: This will destroy ALL containers, networks, and data directories (db/postgres, synapse data, etc.)."
echo "Are you sure you want to proceed? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Starting cleanup..."

    echo "Removing services..."
    docker-compose -f db/docker-compose.yaml down 2>/dev/null
    docker-compose -f nginx/docker-compose.yaml down 2>/dev/null
    docker-compose -f n8n/docker-compose.yaml down 2>/dev/null
    docker-compose -f synapse/docker-compose.yaml down 2>/dev/null
    docker-compose -f gitea/docker-compose.yaml down 2>/dev/null
    docker-compose -f navidrome/docker-compose.yaml down 2>/dev/null
    docker-compose -f paperless/docker-compose.yaml down 2>/dev/null

    echo "Removing network 'homelab_net'..."
    docker network rm homelab_net 2>/dev/null

    echo "Removing generated directories..."
    rm -rf nginx db db/postgres n8n synapse data gitea navidrome paperless

    echo "Removing project-specific images..."
    docker rmi -f postgres:15 nginx:alpine n8nio/n8n:latest matrixdotorg/synapse:latest 2>/dev/null

    echo "Cleanup complete!"
else
    echo "Cleanup aborted."
fi
