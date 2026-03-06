#!/bin/bash

# List of service directories containing docker-compose.yaml
SERVICES=("db" "nginx" "n8n" "synapse" "gitea" "navidrome" "paperless")

echo "Stopping all homelab services..."

for dir in "${SERVICES[@]}"; do
    if [ -f "$dir/docker-compose.yaml" ]; then
        echo "Stopping service in $dir..."
        docker-compose -f "$dir/docker-compose.yaml" stop
    else
        echo "No docker-compose.yaml found in $dir, skipping."
    fi
done

echo "All services have been stopped."