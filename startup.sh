#!/bin/bash

SERVICES=("db" "authelia" "pihole" "stats-api" "nginx" "n8n" "synapse" "gitea" "navidrome" "paperless")

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Starting all homelab services..."
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""

for dir in "${SERVICES[@]}"; do
    if [ -f "$dir/docker-compose.yaml" ]; then
        echo "Starting service in $dir..."
        docker compose -f "$dir/docker-compose.yaml" up -d
    else
        echo "No docker-compose.yaml found in $dir, skipping."
    fi
done

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "All services have been started."
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""
