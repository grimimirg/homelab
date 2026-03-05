#!/bin/bash

generate_from_template() {
    local template_file=$1
    local output_file=$2

    if [ ! -f "$template_file" ]; then
        echo "ERROR: Template $template_file not found!"
        exit 1
    fi

    echo "Generating $output_file..."

    if [[ "$template_file" == *.conf.template ]]; then
        sed -e "s/\${DOMAIN}/$DOMAIN/g" \
            -e 's/${DOLLAR}/$/g' \
            "$template_file" > "$output_file"
    else
        envsubst < "$template_file" > "$output_file"
    fi
}

prepare_directories() {
    echo "Scaffolding directories and setting permissions..."

    local dirs=(
        "nginx" "nginx/conf.d"
        "db" "db/postgres"
        "n8n"
        "data" "logs"
        "data/paperless" "data/gitea" "data/navidrome" "data/synapse"
        "gitea" "synapse" "navidrome" "paperless"
    )

    for d in "${dirs[@]}"; do
        if [ ! -d "$d" ]; then
            mkdir -p "$d"
        fi

        sudo chown -R $(id -u):$(id -g) "$d"
        chmod -R 777 "$d"
    done
    echo "Directories are ready and owned by $(whoami)."
}

echo "Starting Homelab creation..."

if [ -f ".env" ]; then
    source .env
else
    echo "ERROR: .env not found!"
    exit 1
fi

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

echo "Variables validation passed. Exporting..."
export "${REQUIRED_VARS[@]}"

prepare_directories

######################################################################
# TEMPLATE GENERATION
######################################################################

# NGINX
generate_from_template "templates/nginx/nginx.yaml.template" "nginx/docker-compose.yaml"
generate_from_template "templates/nginx/nginx.main.conf.template" "nginx/nginx.conf"
generate_from_template "templates/synapse/synapse.conf.template" "nginx/conf.d/synapse.conf"
generate_from_template "templates/n8n/n8n.conf.template" "nginx/conf.d/n8n.conf"

# DATABASE
generate_from_template "templates/db/db.yaml.template" "db/docker-compose.yaml"

# N8N
generate_from_template "templates/n8n/n8n.yaml.template" "n8n/docker-compose.yaml"

# SYNAPSE
generate_from_template "templates/synapse/synapse.yaml.template" "synapse/docker-compose.yaml"
generate_from_template "templates/homeserver.yaml.template" "data/homeserver.yaml"
cp templates/log.config.template data/log.config

# GITEA
generate_from_template "templates/gitea/gitea.yaml.template" "gitea/docker-compose.yaml"

# NAVIDROME
generate_from_template "templates/navidrome/navidrome.yaml.template" "navidrome/docker-compose.yaml"

# PAPERLESS
generate_from_template "templates/paperless/paperless.yaml.template" "paperless/docker-compose.yaml"

echo "Setup completed successfully!"