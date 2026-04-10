#!/bin/bash

SERVICES=("db" "authelia" "stats-api" "nginx" "n8n" "synapse" "gitea" "navidrome" "paperless")

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Stopping all homelab services..."
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""

for dir in "${SERVICES[@]}"; do
    if [ -f "$dir/docker-compose.yaml" ]; then
        echo "Stopping service in $dir..."
        docker compose -f "$dir/docker-compose.yaml" stop
    else
        echo "No docker-compose.yaml found in $dir, skipping."
    fi
done

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "All services have been stopped."
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""
