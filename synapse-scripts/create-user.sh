#!/bin/bash

# Matrix User Creation Script
echo "=== Matrix User Creation Tool ==="
echo ""

# Check if Matrix server is running
if ! docker-compose ps synapse | grep -q "Up"; then
    echo "ERROR: Synapse container is not running!"
    echo "Start the server with: docker-compose up -d"
    exit 1
fi

# Interactive user creation
read -p "Username (without @domain): " username
read -s -p "Password: " password
echo ""
read -p "Should this user be an admin? (y/N): " is_admin

# Convert admin choice
if [[ "$is_admin" =~ ^[Yy]$ ]]; then
    admin_flag="--admin"
    admin_text="ADMIN"
else
    admin_flag=""
    admin_text="Regular User"
fi

echo ""
echo "Creating user: @$username:$(grep DOMAIN= config.env | cut -d'=' -f2)"
echo "Type: $admin_text"
echo ""

# Create the user
docker-compose exec -T synapse register_new_matrix_user \
    -c /data/homeserver.yaml \
    -u "$username" \
    -p "$password" \
    $admin_flag \
    http://localhost:8008

if [ $? -eq 0 ]; then
    echo ""
    echo "User created successfully!"
    echo "Login at: https://$(grep DOMAIN= config.env | cut -d'=' -f2)"
    echo "Username: @$username:$(grep DOMAIN= config.env | cut -d'=' -f2)"
    source config.env
    echo "Server: $DOMAIN"
else
    echo ""
    echo "Failed to create user. Check the logs:"
    echo "docker-compose logs synapse"
fi
