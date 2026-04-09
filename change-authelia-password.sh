#!/bin/bash

echo "========================================="
echo "  Authelia Password Change"
echo "========================================="
echo ""

if [ ! -f "data/authelia/users_database.yml" ]; then
    echo "ERROR: Authelia users database not found!"
    echo "Make sure Authelia is deployed first (run ./build.sh)"
    exit 1
fi

echo "This script will change the password for an Authelia user."
echo ""

# Ask for username
read -p "Enter username (default: admin): " username
username=${username:-admin}

# Check if user exists
if ! grep -q "^  $username:" data/authelia/users_database.yml; then
    echo "ERROR: User '$username' not found in database!"
    echo ""
    echo "Available users:"
    grep "^  [a-zA-Z]" data/authelia/users_database.yml | sed 's/://g'
    exit 1
fi

echo ""
echo "Enter new password for user '$username':"
read -s new_password

if [ -z "$new_password" ]; then
    echo "ERROR: Password cannot be empty!"
    exit 1
fi

echo ""
echo "Confirm new password:"
read -s confirm_password

if [ "$new_password" != "$confirm_password" ]; then
    echo ""
    echo "ERROR: Passwords do not match!"
    exit 1
fi

echo ""
echo "Generating password hash..."

# Check if authelia container is running
if ! docker ps --format '{{.Names}}' | grep -q '^authelia$'; then
    echo "ERROR: Authelia container is not running!"
    exit 1
else
    hash=$(docker exec authelia authelia crypto hash generate argon2 --password "$new_password" | grep "Digest:" | awk '{print $2}')
fi

if [ -z "$hash" ]; then
    echo "ERROR: Failed to generate password hash!"
    exit 1
fi

echo "Hash generated successfully!"
echo ""

# Backup current file
cp data/authelia/users_database.yml data/authelia/users_database.yml.backup
echo "✓ Backup created: data/authelia/users_database.yml.backup"

# Escape special characters in hash for sed
escaped_hash=$(echo "$hash" | sed 's/[\/&]/\\&/g')

# Replace password hash for the user
sed -i "/^  $username:/,/^    password:/ s|^    password:.*|    password: \"$escaped_hash\"|" data/authelia/users_database.yml

echo "✓ Password updated in users_database.yml"
echo ""

# Restart Authelia
echo "Restarting Authelia container..."
docker compose -f authelia/docker-compose.yaml restart

echo ""
echo "========================================="
echo "  Password Changed Successfully!"
echo "========================================="
echo ""
echo "User: $username"
echo "You can now login with the new password."
echo ""
