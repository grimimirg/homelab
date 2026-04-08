#!/bin/bash

generate_from_template() {
    local template_file=$1
    local output_file=$2

    if [ ! -f "$template_file" ]; then
        echo "ERROR: Template $template_file not found!"
        exit 1
    fi

    mkdir -p "$(dirname "$output_file")"

    echo "Generating $output_file..."

    if [[ "$template_file" == *.conf.template ]]; then
        sed -e "s/\${DOMAIN}/$DOMAIN/g" \
            -e "s/\${DOLLAR}/\$/g" \
            "$template_file" > "$output_file"
    else
        envsubst < "$template_file" > "$output_file"
    fi
}

prepare_directories() {
    echo "Scaffolding directories and setting permissions..."

    local base_dirs=("nginx/conf.d" "db/postgres" "data/n8n" "data/paperless"
    "data/gitea" "data/navidrome" "data/synapse" "logs")

    for d in "${base_dirs[@]}"; do
        if [ ! -d "$d" ]; then
            mkdir -p "$d"
        fi
    done

    echo "Setting permissions for UID $HOST_UID services..."
    sudo chown -R $HOST_UID:$HOST_GID data/n8n data/gitea data/navidrome data/paperless
    chmod -R 755 data/n8n data/gitea data/navidrome data/paperless

    echo "Setting strict permissions for PostgreSQL..."
    sudo chown -R $HOST_UID:$HOST_GID db/postgres
    chmod -R 700 db/postgres

    echo "Directories are ready with correct ownership and secure permissions."
}

echo "Starting Homelab creation..."

if [ -f ".env" ]; then
    source .env
else
    echo "ERROR: .env not found!"
    exit 1
fi

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)
export DOLLAR='$'

echo "Current HOST_UID: $HOST_UID"
echo "Current HOST_GID: $HOST_GID"

REQUIRED_VARS=(
    "DOMAIN" "EMAIL" "SHARED_NETWORK" "POSTGRES_USER" "POSTGRES_PASSWORD"
    "GITEA_DB_USER" "GITEA_DB_PASS" "PAPERLESS_DB_USER" "PAPERLESS_DB_PASS"
    "PAPERLESS_SECRET_KEY" "SYNAPSE_DB_USER" "SYNAPSE_DB_PASS"
    "SYNAPSE_REGISTRATION_SHARED_SECRET" "NAVIDROME_MUSIC_FOLDER_PATH"
    "SYNAPSE_DB_NAME" "PAPERLESS_DB_NAME" "GITEA_DB_NAME"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Missing required variable: $var"
        exit 1
    fi
done

echo "======================="
echo "DEBUG: Values"
echo "======================="

for var in "${REQUIRED_VARS[@]}"; do
    echo "${!var}"
done

echo "======================="

echo "Variables validation passed. Exporting..."
export "${REQUIRED_VARS[@]}"

prepare_directories

######################################################################
# TEMPLATE GENERATION
######################################################################

# NGINX
generate_from_template "templates/nginx/nginx.yaml.template" "nginx/docker-compose.yaml"
generate_from_template "templates/nginx/nginx.main.conf.template" "nginx/nginx.conf"

# DATABASE
generate_from_template "templates/db/db.yaml.template" "db/docker-compose.yaml"

# N8N
generate_from_template "templates/n8n/n8n.yaml.template" "n8n/docker-compose.yaml"
generate_from_template "templates/n8n/n8n.conf.template" "nginx/conf.d/n8n.conf"

# SYNAPSE
generate_from_template "templates/synapse/synapse.yaml.template" "synapse/docker-compose.yaml"
generate_from_template "templates/synapse/synapse.conf.template" "nginx/conf.d/synapse.conf"
generate_from_template "templates/homeserver.yaml.template" "data/synapse/homeserver.yaml"
cp templates/log.config.template data/synapse/log.config

# GITEA
generate_from_template "templates/gitea/gitea.yaml.template" "gitea/docker-compose.yaml"
generate_from_template "templates/gitea/gitea.conf.template" "nginx/conf.d/gitea.conf"

# NAVIDROME
generate_from_template "templates/navidrome/navidrome.yaml.template" "navidrome/docker-compose.yaml"
generate_from_template "templates/navidrome/navidrome.conf.template" "nginx/conf.d/navidrome.conf"

# PAPERLESS
generate_from_template "templates/paperless/paperless.yaml.template" "paperless/docker-compose.yaml"
generate_from_template "templates/paperless/paperless.conf.template" "nginx/conf.d/paperless.conf"

echo "Setup completed successfully!"