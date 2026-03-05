#!/bin/bash

# Load variables from the .env file
source .env

# Container name as defined in your docker-compose.yaml
DB_CONTAINER="shared_postgres"

# Function to handle user and database provisioning
provision_db() {
    local db_name=$1
    local db_user=$2
    local db_pass=$3

    echo "--- Provisioning: $db_name (User: $db_user) ---"

    # 1. Check/Create User
    if ! docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$db_user'" | grep -q 1; then
        echo "Creating user $db_user..."
        docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -c "CREATE USER $db_user WITH PASSWORD '$db_pass';"
    else
        echo "User $db_user already exists."
    fi

    # 2. Check/Create Database
    if ! docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "Creating database $db_name..."
        docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db_name OWNER $db_user;"
    else
        echo "Database $db_name already exists."
    fi
}

# --- EXECUTION ---
# Ensure these variables are present in your .env file!

provision_db "gitea" "$GITEA_DB_USER" "$GITEA_DB_PASS"
provision_db "paperless" "$PAPERLESS_DB_USER" "$PAPERLESS_DB_PASS"
provision_db "synapse" "$SYNAPSE_DB_USER" "$SYNAPSE_DB_PASS"

echo "Database creation completed successfully."