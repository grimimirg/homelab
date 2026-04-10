#!/bin/bash

source .env

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Starting homelab for ${DOMAIN}..."
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""

if ! docker network inspect "$SHARED_NETWORK" >/dev/null 2>&1; then
    echo "Creating network $SHARED_NETWORK..."
    docker network create "$SHARED_NETWORK"
else
    echo "Network $SHARED_NETWORK already exists."
fi
echo ""

echo "Starting Database..."
docker compose -f db/docker-compose.yaml up -d
echo ""

echo "Waiting for Postgres to be ready..."
until docker exec shared_postgres pg_isready -U "$POSTGRES_USER"; do
  echo "Postgres is unavailable - sleeping"
  sleep 5
done
echo ""

echo "==============================="
echo "Database is up! Provisioning..."
./init-db.sh
echo ""

echo "==============================="
echo "Starting n8n..."
docker compose -f n8n/docker-compose.yaml up -d
echo ""

echo "==============================="
echo "Starting Synapse..."
docker compose -f synapse/docker-compose.yaml up -d
echo ""

echo "==============================="
echo "Starting Gitea..."
docker compose -f gitea/docker-compose.yaml up -d
echo ""

echo "==============================="
echo "Starting Navidrome..."
docker compose -f navidrome/docker-compose.yaml up -d
echo ""

echo "==============================="
echo "Starting Paperless..."
docker compose -f paperless/docker-compose.yaml up -d
echo ""

echo "==============================="
echo "Starting Authelia..."
docker compose -f authelia/docker-compose.yaml up -d
echo ""

echo "==============================="
echo "Starting Docker Stats API..."
docker compose -f stats-api/docker-compose.yaml up -d --build
echo ""

sleep 2

echo "==============================="
echo "Starting Nginx..."
docker compose -f nginx/docker-compose.yaml up -d
echo ""

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Complete! All services are now running."
echo "Check their status with: docker-compose -f <folder>/docker-compose.yaml ps"
echo ""
echo "Access at: https://auth.${DOMAIN}"
echo "Default login: admin / admin"
echo ""
echo "NOTE: Keep in mind to change the default password for the admin user as soon as possible by running ./change-authelia-password.sh"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
