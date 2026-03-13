# Modular Homelab Infrastructure

This project provides a modular, containerized approach to managing your home services
using Docker and Nginx as a reverse proxy. The infrastructure is defined as code (IaC), allowing for rapid setup,
deployment, and cleanup.

## Architecture

The system is built on a modular design where each service has its own directory and lifecycle, coordinated by a central
set of orchestration scripts.

* **Reverse Proxy:** Nginx (Containerized).
* **Database:** PostgreSQL (Centralized).
* **Services:** Synapse, n8n, gitea, paperless, navidrome.
* **Network:** Shared bridge network.

## Project Structure

```
├── build.sh                                 # Orchestrator to build and boot all services
├── cleanup.sh                               # Full environment wipe script
├── init-db.sh                               # Automated DB/User provisioning
├── README.md                                # Documentation
├── scaffold.sh                              # Scaffolding and config generator
├── setup-ssl.sh                             # SSL certificate helper
├── shutdown.sh                              # Orchestrator to manually stop all services
├── startup.sh                               # Orchestrator to manually start all services
├── synapse-scripts                          # Administration scripts for Synapse
│    ├── create-user-batch.sh                # Utility script for batch user creation
│    └── create-user.sh                      # Utility script for user creation
└── templates                                # IaC templates (categorized)
    ├── homeserver.yaml.template             # Synapse settings
    ├── log.config.template                  # Log settings
    ├── db                                   # PostgreSQL configuration
    │   └── db.yaml.template                 # Docker Compose template for postgres
    ├── gitea                                # Gitea & DB definitions
    │   ├── gitea.conf.template              # Nginx proxy conf for n8n
    │   └── gitea.yaml.template              # Docker Compose template for gitea
    ├── n8n                                  # n8n service definitions
    │   ├── n8n.conf.template                # Nginx proxy conf for n8n
    │   └── n8n.yaml.template                # Docker Compose template for n8n
    ├── navidrome                            # Music server definitions
    │   ├── navidrome.conf.template          # Nginx proxy conf for navidrome
    │   └── navidrome.yml.template           # Docker Compose template for navidrome
    ├── nginx                                # Reverse proxy configurations
    │   ├── nginx.main.conf.template         # Nginx proxy main configuration
    │   └── nginx.yaml.template              # Docker Compose template for nginx
    ├── paperless                            # Document management + Redis
    │   ├── paperless.conf.template          # Nginx proxy conf for paperless
    │   └── paperless.yaml.template          # Docker Compose template for paperless
    └── synapse                              # Synapse server definitions
        ├── synapse.conf.template            # Nginx proxy conf for synapse
        └── synapse.yaml.template            # Docker Compose template for synapse
```

## Deployment

This workflow uses a clear separation between infrastructure generation and service execution.

### 1\. Configuration

Create a `.env` file in the project root with the following variables:

| Variable                           | Description                                                                                 |
|------------------------------------|---------------------------------------------------------------------------------------------|
| DOMAIN                             | The primary domain name used for SSL certificate issuance and public access.                |
| EMAIL                              | Contact email address used by Let's Encrypt for SSL certificate notifications.              |
| SHARED_NETWORK                     | The shared network used by containers to communicate with eachother.                        |
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
2. **Secure:** Run `./setup-ssl.sh` to prepare your certificates.
3. **Scaffold:** Run `./scaffold.sh` to generate configurations from `templates/`.
4. **Provision:** Run `./build.sh`. This will spin up the database, wait for readiness, and execute `./init-db.sh` to
   create dedicated DB users and schemas.

## Start and Stop

Use `startup.sh` to start all containers at once, and `shutdown.sh` to stop all containers at once.

## Cleanup

**Warning:** Running `cleanup.sh` will stop containers, remove the network, and delete the generated configurations and
data directories. **This will delete your databases.**

```
./cleanup.sh
```

- - -

# Expose the homelab via No-IP DUC

Here below 3 ways on how to run the **No-IP Dynamic Update Client (DUC) v3**


## Method 1: On-Demand

Use this method to run the process only once manually.

```
noip-duc --username [username] \\
   --password [password] \\
   --hostnames [group] \\ # It can be found in https://my.noip.com/ddns-keys
   --once
```

## Method 2: Direct Daemon

Use this built-in method to fork the process into the background manually. This creates a PID file to track the process.

```
noip-duc --username [username] \\
   --password [password] \\
   --hostnames [group] \\  # It can be found in https://my.noip.com/ddns-keys
   --daemonize \\
   --daemon-user nobody \\
   --daemon-group nogroup \\
   --daemon-pid-file /var/run/noip-duc.pid
```

## Method 3: Systemd Service (Recommended)

Systemd ensures the client starts automatically after a reboot and restarts if the process crashes.

### 1\. Create the Service File

Open a terminal and run:

```
sudo nano /etc/systemd/system/noip-duc.service
```

### 2\. Paste the following configuration

```
[Unit]
   Description=No-IP Dynamic Update Client
   After=network.target

[Service]
   Type=simple
   # Ensure the path to noip-duc is correct (check with 'which noip-duc')
   ExecStart=/usr/bin/noip-duc --username [username] --password [password]
   Restart=always
   RestartSec=30

[Install]
   WantedBy=multi-user.target
```

### 3\. Enable and Start

#### Reload systemd to recognize the new service
```
sudo systemctl daemon-reload
```

#### Enable service to start on boot

```
sudo systemctl enable noip-duc
```

#### Start the service immediately

```
sudo systemctl start noip-duc
```

### 4\. Check Status

```
sudo systemctl status noip-duc
```

**Security Tip:** To avoid leaving your password in a plain text file, consider using **Environment Variables** in a protected `.conf` file as mentioned in the No-IP advanced documentation.
