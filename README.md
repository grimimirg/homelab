# Modular Homelab Infrastructure

This project provides a modular, containerized approach to managing your home services
using Docker and Nginx as a reverse proxy. The infrastructure is defined as code (IaC), allowing for rapid setup,
deployment, and cleanup.

## Architecture

The system is built on a modular design where each service has its own directory and lifecycle, coordinated by a central
set of orchestration scripts.

* **Reverse Proxy:** Nginx (Containerized).
* **Database:** PostgreSQL (Centralized).
* **Services:** Synapse, n8n.
* **Network:** Shared bridge network (`homelab_net`).

## Project Structure

```
├── cleanup.sh                               #  Full environment wipe script
├── init-db.sh                               #  Automated DB/User provisioning
├── README.md                                #  Documentation
├── setup.sh                                 #  Scaffolding and config generator
├── setup-ssl.sh                             #  SSL certificate helper
├── startup.sh                               # Orchestrator to boot all services
├── synapse-scripts                          # Administration scripts for Synapse
│    ├── create-user-batch.sh
│    └── create-user.sh
└── templates                                # IaC templates (categorized)
    ├── db                                   # PostgreSQL configuration
    │   └── db.yaml.template
    ├── gitea                                # Gitea & DB definitions
    │   ├── gitea.conf.template
    │   └── gitea.yaml.template
    ├── homeserver.yaml.template
    ├── log.config.template
    ├── n8n                                  # n8n service definitions
    │   ├── n8n.conf.template
    │   └── n8n.yaml.template
    ├── navidrome                            # Music server definitions
    │   ├── navidrome.conf.template
    │   └── navidrome.yml.template
    ├── nginx                                # Reverse proxy configurations
    │   ├── nginx.main.conf.template
    │   └── nginx.yaml.template
    ├── paperless                            # Document management + Redis
    │   ├── paperless.conf.template
    │   └── paperless.yaml.template
    └── synapse                              # Synapse server definitions
        ├── synapse.conf.template
        └── synapse.yaml.template
```

## Deployment

This workflow uses a clear separation between infrastructure generation and service execution.

### 1\. Configuration

Create a `.env` file in the project root with the following variables:

| Variable                           | Description                                                                                 |
|------------------------------------|---------------------------------------------------------------------------------------------|
| DOMAIN                             | The primary domain name used for SSL certificate issuance and public access.                |
| EMAIL                              | Contact email address used by Let's Encrypt for SSL certificate notifications.              |
| POSTGRES_USER                      | The administrative username for PostgreSQL, used by the init-db.sh script for provisioning. |
| POSTGRES_PASSWORD                  | The master password for the PostgreSQL administrator account.                               |
| GITEA_DB_USER                      | Dedicated database username for the Gitea service.                                          |
| GITEA_DB_PASS                      | Dedicated database password for the Gitea service.                                          |
| PAPERLESS_DB_USER                  | Dedicated database username for the Paperless-ngx service.                                  |
| PAPERLESS_DB_PASS                  | Dedicated database password for the Paperless-ngx service.                                  |
| PAPERLESS_SECRET_KEY               | A secure, random string used for session encryption in Paperless-ngx.                       |
| SYNAPSE_DB_USER                    | Dedicated database username for the Synapse service.                                        |
| SYNAPSE_DB_PASS                    | Dedicated database password for the Synapse service.                                        |
| SYNAPSE_REGISTRATION_SHARED_SECRET | A security key required to authorize user registrations on your server.                     |
| NAVIDROME_MUSIC_FOLDER_PATH        | The absolute path on your host server where your music library is stored.                   |

### 2\. Startup Workflow

1. **Prepare:** Configure your `.env` file with all required variables (see above).
2. **Scaffold:** Run `./setup.sh` to generate configurations from `templates/`.
3. **Secure:** Run `./setup-ssl.sh` to prepare your certificates.
4. **Provision:** Run `./startup.sh`. This will spin up the database, wait for readiness, and execute `./init-db.sh` to
   create dedicated DB users and schemas.

## Cleanup

**Warning:** Running `cleanup.sh` will stop containers, remove the network, and delete the generated configurations and
data directories. **This will delete your databases.**

```
./cleanup.sh
```
