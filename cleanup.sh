#!/bin/bash

source .env

echo "WARNING: This will destroy ALL containers, networks, and data directories (db/postgres, synapse data, etc.)."
echo "Are you sure you want to proceed? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Starting cleanup..."

    echo "Removing services..."
    docker compose -f db/docker-compose.yaml down 2>/dev/null
    docker compose -f nginx/docker-compose.yaml down 2>/dev/null
    docker compose -f n8n/docker-compose.yaml down 2>/dev/null
    docker compose -f synapse/docker-compose.yaml down 2>/dev/null
    docker compose -f gitea/docker-compose.yaml down 2>/dev/null
    docker compose -f navidrome/docker-compose.yaml down 2>/dev/null
    docker compose -f paperless/docker-compose.yaml down 2>/dev/null

    echo "Removing network 'homelab_net'..."
    docker network rm "$SHARED_NETWORK" 2>/dev/null

    echo "Removing generated directories..."
    rm -rf nginx db db/postgres n8n synapse data gitea navidrome paperless logs landing

    echo "Cleanup complete!"
else
    echo "Cleanup aborted."
fi
