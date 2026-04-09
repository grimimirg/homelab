#!/bin/bash

source .env

DB_CONTAINER="shared_postgres"

provision_db() {
    local db_name=$1
    local db_user=$2
    local db_pass=$3
    # Optional parameter: defaults to empty string (system default collation)
    local collation=${4:-""}

    echo "--- Provisioning: $db_name (User: $db_user) ---"

    # 1. Check/Create User
    # Verify if user exists, otherwise create it
    if ! docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$db_user'" | grep -q 1; then
        echo "Creating user $db_user..."
        docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" psql -U "$POSTGRES_USER" -c "CREATE USER $db_user WITH PASSWORD '$db_pass';"
    else
        echo "User $db_user already exists."
    fi

    # 2. Check/Create Database
    # Verify if database exists
    if ! docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "Creating database $db_name..."

        # If collation is set to 'C', use template0 to override system locale constraints
        if [ "$collation" == "C" ]; then
            echo "Applying C collation (using template0)..."
            docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" createdb -U "$POSTGRES_USER" -T template0 --lc-collate=C --lc-ctype=C "$db_name"
        else
            # Use standard creation for other services
            docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" createdb -U "$POSTGRES_USER" "$db_name"
        fi

        # Assign ownership to the specific user
        docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$DB_CONTAINER" psql -U "$POSTGRES_USER" -c "ALTER DATABASE $db_name OWNER TO $db_user;"
    else
        echo "Database $db_name already exists."
    fi
}



# Execution for services
# Gitea and Paperless use the default system collation
provision_db "$GITEA_DB_NAME" "$GITEA_DB_USER" "$GITEA_DB_PASS"
provision_db "$PAPERLESS_DB_NAME" "$PAPERLESS_DB_USER" "$PAPERLESS_DB_PASS"
provision_db "$AUTHELIA_DB_NAME" "$AUTHELIA_DB_USER" "$AUTHELIA_DB_PASS"

# Synapse specifically requires 'C' collation
provision_db "$SYNAPSE_DB_NAME" "$SYNAPSE_DB_USER" "$SYNAPSE_DB_PASS" "C"

echo "Database creation completed successfully."