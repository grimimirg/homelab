#!/bin/bash

# List of service directories containing docker-compose.yaml
# Ensure the order matches your dependency requirements
#
#####################################################
# NOTE: DB needs always to start before the others! #
#####################################################
#
SERVICES=("db" "nginx" "n8n" "synapse" "gitea" "navidrome" "paperless")

echo "Starting all homelab services..."

for dir in "${SERVICES[@]}"; do
    if [ -f "$dir/docker-compose.yaml" ]; then
        echo "Starting service in $dir..."
        # Using 'up -d' ensures that the services are started in detached mode
        # and it will recreate them if the configuration was changed.
        docker compose -f "$dir/docker-compose.yaml" up -d
    else
        echo "No docker-compose.yaml found in $dir, skipping."
    fi
done

echo "All services have been started."