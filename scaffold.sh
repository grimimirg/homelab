#!/bin/bash

# ---------------------------------------------------------------
# METHODS

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

# ---------------------------------------------------------------

echo "Starting Homelab creation..."

if [ -f ".env" ]; then
    source .env
else
    echo "ERROR: .env not found!"
    exit 1
fi

REQUIRED_VARS=(
    "DOMAIN"
    "EMAIL"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "GITEA_DB_USER"
    "GITEA_DB_PASS"
    "PAPERLESS_DB_USER"
    "PAPERLESS_DB_PASS"
    "PAPERLESS_SECRET_KEY"
    "SYNAPSE_DB_USER"
    "SYNAPSE_DB_PASS"
    "SYNAPSE_REGISTRATION_SHARED_SECRET"
    "NAVIDROME_MUSIC_FOLDER_PATH"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Missing required variable: $var"
        echo "Please ensure $var is set in .env"
        exit 1
    fi
done

echo "Variables validation passed."
echo "Exporting variables: DOMAIN POSTGRES_PASSWORD SYNAPSE_REGISTRATION_SHARED_SECRET EMAIL"
export DOMAIN EMAIL POSTGRES_USER POSTGRES_PASSWORD SYNAPSE_REGISTRATION_SHARED_SECRET EMAIL

######################################################################
# Directories Creation
######################################################################
echo "Scaffolding..."

mkdir -p nginx/conf.d
mkdir -p db/postgres
mkdir -p n8n
mkdir -p data
mkdir -p data/paperless

######################################################################
# NGINX (Reverse Proxy Container + Config)
######################################################################
# Generate the docker-compose for the proxy container
generate_from_template "templates/nginx/nginx.yaml.template" "nginx/docker-compose.yaml"

# Generate the nginx configuration files
generate_from_template "templates/nginx/nginx.main.conf.template" "nginx/nginx.conf"
generate_from_template "templates/synapse/synapse.conf.template" "nginx/conf.d/synapse.conf"
generate_from_template "templates/n8n/n8n.conf.template" "nginx/conf.d/n8n.conf"
echo "Nginx (proxy) configuration generated."

######################################################################
# DATABASE
######################################################################
generate_from_template "templates/db/db.yaml.template" "db/docker-compose.yaml"
echo "Postgres configuration generated."

######################################################################
# N8N
######################################################################
generate_from_template "templates/n8n/n8n.yaml.template" "n8n/docker-compose.yaml"
echo "n8n configuration generated."

######################################################################
# SYNAPSE
######################################################################
mkdir -p synapse
generate_from_template "templates/synapse/synapse.yaml.template" "synapse/docker-compose.yaml"
echo "Synapse container configuration generated."

######################################################################
# SYNAPSE (Logs)
######################################################################
generate_from_template "templates/homeserver.yaml.template" "data/homeserver.yaml"
cp templates/log.config.template data/log.config

######################################################################
# GITEA
######################################################################
mkdir -p gitea
generate_from_template "templates/gitea/gitea.yaml.template" "gitea/docker-compose.yaml"
echo "Gitea container configuration generated."

######################################################################
# NAVIDROME
######################################################################
mkdir -p navidrome
generate_from_template "templates/navidrome/navidrome.yaml.template" "navidrome/docker-compose.yaml"
echo "Navidrome container configuration generated."

######################################################################
# PAPERLESS
######################################################################
mkdir -p paperless
generate_from_template "templates/paperless/paperless.yaml.template" "paperless/docker-compose.yaml"
echo "Paperless container configuration generated."

# Permissions
[ "$EUID" -eq 0 ] && chown -R 991:991 data/ || sudo chown -R 991:991 data/
chmod -R 755 data/

echo "Setup completed successfully!"
