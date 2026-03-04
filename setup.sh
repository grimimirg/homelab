#!/bin/bash

# METHODS
render_template() {
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


PARENT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$PARENT_DIR" || exit 1

echo "Starting Homelab creation..."

if [ -f "config.env" ]; then
    source config.env
    [ -f ".env" ] && source .env
else
    echo "ERROR: config.env not found!"
    exit 1
fi

REQUIRED_VARS=("DOMAIN" "POSTGRES_PASSWORD" "SYNAPSE_REGISTRATION_SHARED_SECRET" "EMAIL")

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Missing required variable: $var"
        echo "Please ensure $var is set in config.env or .env"
        exit 1
    fi
done

echo "Variables validation passed."
echo "Exporting variables: DOMAIN POSTGRES_PASSWORD SYNAPSE_REGISTRATION_SHARED_SECRET EMAIL"
export DOMAIN POSTGRES_PASSWORD SYNAPSE_REGISTRATION_SHARED_SECRET EMAIL

######################################################################
# Directories Creation
######################################################################
echo "Scaffolding..."

mkdir -p nginx/conf.d
mkdir -p db/postgres
mkdir -p n8n
mkdir -p data

######################################################################
# NGINX (Reverse Proxy Container + Config)
######################################################################
# Generate the docker-compose for the proxy container
render_template "templates/nginx.yaml.template" "nginx/docker-compose.yaml"

# Generate the nginx configuration files
render_template "templates/nginx.main.conf.template" "nginx/nginx.conf"
render_template "templates/synapse.conf.template" "nginx/conf.d/synapse.conf"
render_template "templates/n8n.conf.template" "nginx/conf.d/n8n.conf"
echo "Nginx (proxy) configuration generated."

######################################################################
# DATABASE
######################################################################
render_template "templates/db.yaml.template" "db/docker-compose.yaml"
echo "Postgres configuration generated."

######################################################################
# N8N
######################################################################
render_template "templates/n8n.yaml.template" "n8n/docker-compose.yaml"
echo "n8n configuration generated."

######################################################################
# SYNAPSE
######################################################################
mkdir -p synapse
render_template "templates/synapse.yaml.template" "synapse/docker-compose.yaml"
echo "Synapse container configuration generated."

######################################################################
# SYNAPSE (Logs)
######################################################################
render_template "templates/homeserver.yaml.template" "data/homeserver.yaml"
cp templates/log.config.template data/log.config

# Permissions
[ "$EUID" -eq 0 ] && chown -R 991:991 data/ || sudo chown -R 991:991 data/
chmod -R 755 data/

echo "Setup completed successfully!"

