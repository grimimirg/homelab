#!/bin/bash

# List of available services
SERVICES=("db" "authelia" "stats-api" "nginx" "n8n" "synapse" "gitea" "navidrome" "paperless")

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Homelab Service Restart Manager"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""
echo "Available services:"
echo ""

# Display numbered list of services
for i in "${!SERVICES[@]}"; do
    service="${SERVICES[$i]}"
    if [ -f "$service/docker-compose.yaml" ]; then
        echo "  $((i+1)). $service"
    else
        echo "  $((i+1)). $service (not configured)"
    fi
done

echo ""
echo "  0. Exit"
echo ""
read -p "Select a service to restart (0-${#SERVICES[@]}): " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid input. Please enter a number."
    exit 1
fi

# Exit if user chose 0
if [ "$choice" -eq 0 ]; then
    echo "Exiting..."
    exit 0
fi

# Validate choice range
if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#SERVICES[@]}" ]; then
    echo "ERROR: Invalid selection. Please choose a number between 0 and ${#SERVICES[@]}."
    exit 1
fi

# Get selected service
selected_service="${SERVICES[$((choice-1))]}"

# Check if docker-compose.yaml exists
if [ ! -f "$selected_service/docker-compose.yaml" ]; then
    echo "ERROR: No docker-compose.yaml found in $selected_service directory."
    echo "Please run ./scaffold.sh first to generate the configuration."
    exit 1
fi

echo ""
echo "==============================="
echo "Restarting service: $selected_service"
echo ""
echo ""

# Restart the service
docker compose -f "$selected_service/docker-compose.yaml" restart

if [ $? -eq 0 ]; then
    echo ""
    echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
    echo "✓ Service '$selected_service' restarted successfully!"
    echo ""
    echo "To check the status, run:"
    echo "  docker compose -f $selected_service/docker-compose.yaml ps"
    echo ""
    echo "To view logs, run:"
    echo "  docker compose -f $selected_service/docker-compose.yaml logs -f"
    echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
    echo ""
else
    echo ""
    echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
    echo "✗ ERROR: Failed to restart service '$selected_service'."
    echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
    echo ""
    exit 1
fi
