<div align="center">

<img src="homelab-logo.jpeg" alt="Homelab Logo" width="40%">

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

</div>

## What is a Homelab?

A **homelab** is a personal server environment set up at home for learning, experimentation, and self-hosting services. It allows you to run your own applications, manage your data privately, and gain hands-on experience with server administration, networking, and DevOps practices.

## About This Project

This project provides a **complete, production-ready homelab infrastructure** built with modern DevOps principles:

- **🐳 Containerized Services**: All applications run in Docker containers, ensuring isolation, portability, and easy management
- **🔄 Reverse Proxy Architecture**: <span style="color: #009639;">**Nginx**</span> acts as a central gateway, routing traffic to different services based on subdomain
- **🔐 Centralized Authentication**: <span style="color: #DC382D;">**Authelia**</span> provides Single Sign-On (SSO) with two-factor authentication for all services
- **📦 Infrastructure as Code (IaC)**: The entire infrastructure is defined in configuration files and scripts, meaning you can:
  - Deploy the complete stack with a single command
  - Version control your infrastructure
  - Reproduce the same environment on any machine
  - Easily backup, restore, and migrate your setup

Whether you're a DevOps enthusiast, a privacy-conscious user wanting to self-host your services, or someone learning about server infrastructure, this homelab provides a solid foundation to build upon.

> **🚧 DISCLAIMER 🚧**
>
> This project is under development. You may experience malfunctions, bugs, or significant changes to
> the structure and functionality.
>
> **For any issues or assistance, please open an issue.**

## Table of Contents

- [Architecture](#architecture)
  - [Directory Structure](#directory-structure)
  - [Required Variables](#required-variables)
  - [Secret Generation](#secret-generation)
- [Quick Setup](#quick-setup)
  - [Prerequisites](#prerequisites)
  - [Setup Steps](#setup-steps)
- [DNS Configuration with No-IP](#dns-configuration-with-no-ip)
  - [Why No-IP?](#why-no-ip)
  - [Setting Up No-IP](#setting-up-no-ip)
  - [Important Notes](#important-notes)
- [Included Services](#included-services)
- [Management Scripts](#management-scripts)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Monitoring](#monitoring)
- [Security](#security)
- [Additional Notes](#additional-notes)
- [Customization](#customization)
- [Support](#support)
- [License](#license)

---

## Architecture

The system is built on a modular design where each service has its own directory and lifecycle, coordinated by a central
set of orchestration scripts.

* **Reverse Proxy:** <span style="color: #009639;">**Nginx**</span>.
* **Authentication:** <span style="color: #DC382D;">**Authelia SSO**</span>.
* **Database:** <span style="color: #316192;">**PostgreSQL**</span>.
* **Services:** <span style="color: #609926;">**Synapse**</span>,
  <span style="color: #EA4B71;">**n8n**</span>, <span style="color: #609926;">**gitea**</span>,
  <span style="color: #46A046;">**paperless**</span>, <span style="color: #4B8BBE;">**navidrome**</span>.
* **Network:** Shared bridge network.

> 📝 **NOTE**: You are free to add or remove services from this setup. However, modifications to the service stack
> are not covered in this documentation. Proceed only if you understand the infrastructure and dependencies.

### Directory Structure

```
├── backup.sh                                # Automated backup script for all container data
├── build.sh                                 # Orchestrator to build and boot all services in correct order
├── change-authelia-password.sh              # Interactive script to change Authelia user passwords
├── cleanup.sh                               # Full environment wipe script (containers, images, data, network)
├── index.html                               # (Optional) Custom landing page
├── init-db.sh                               # Automated PostgreSQL DB/User provisioning for all services
├── README.md                                # Documentation
├── restart-service.sh                       # Interactive script to restart individual services
├── restore.sh                               # Interactive restore script with backup selection and safety backup
├── scaffold.sh                              # Scaffolding and config generator from templates
├── setup-authelia.sh                        # Authelia SSO initial setup helper
├── setup-ssl.sh                             # SSL certificate generation and auto-renewal setup
├── shutdown.sh                              # Stop all homelab services
├── startup.sh                               # Start all homelab services
├── system-metrics-api                       # System metrics and Docker stats API
│    ├── app.py                              # Flask API for system and Docker metrics
│    ├── Dockerfile                          # Container definition
│    ├── requirements.txt                    # Python dependencies
│    ├── README.md                           # Application documentation
│    └── test-docker-stats.sh                # Testing script
├── synapse-scripts                          # Administration scripts for Synapse
│    ├── create-user-batch.sh                # Utility script for batch user creation
│    └── create-user.sh                      # Utility script for user creation
└── templates                                # IaC templates (categorized)
    ├── homeserver.yaml.template             # Synapse settings
    ├── log.config.template                  # Log settings
    ├── authelia                             # Authelia SSO definitions
    │   ├── authelia.conf.template           # Nginx proxy conf for authelia
    │   ├── authelia.yaml.template           # Docker Compose template for authelia
    │   ├── configuration.yml.template       # Authelia configuration
    │   ├── users_database.yml.template      # User database
    │   └── theme.css                        # Custom theme (terminal style)
    ├── db                                   # PostgreSQL configuration
    │   └── db.yaml.template                 # Docker Compose template for postgres
    ├── gitea                                # Gitea & DB definitions
    │   ├── gitea.conf.template              # Nginx proxy conf for gitea
    │   └── gitea.yaml.template              # Docker Compose template for gitea
    ├── landing                              # Landing page
    │   ├── default.index.html.template      # Default landing page template
    │   └── landing.conf.template            # Nginx configuration for landing page
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
    ├── system-metrics-api                   # System metrics and Docker statistics API
    │   └── docker-compose.yaml.template     # Docker Compose template for metrics API
    └── synapse                              # Synapse server definitions
        ├── synapse.conf.template            # Nginx proxy conf for synapse
        └── synapse.yaml.template            # Docker Compose template for synapse
```

### Required Variables

| Variable                           | Description                                                                                 |
|------------------------------------|------------------------------------------------------------------------------------------|
| DOMAIN                             | The primary domain name used for SSL certificate issuance and public access.                |
| EMAIL                              | Contact email address used by Let's Encrypt for SSL certificate notifications.              |
| SHARED_NETWORK                     | The shared network used by containers to communicate with each other.                       |
| TZ                                 | Timezone for services (e.g., Europe/Rome, America/New_York, Asia/Tokyo).                    |
| POSTGRES_USER                      | The administrative username for PostgreSQL, used by the init-db.sh script for provisioning. |
| POSTGRES_PASSWORD                  | The master password for the PostgreSQL administrator account.                               |
| GITEA_DB_NAME                      | Dedicated database name for the Gitea service.                                              |
| GITEA_DB_USER                      | Dedicated database username for the Gitea service.                                          |
| GITEA_DB_PASS                      | Dedicated database password for the Gitea service.                                          |
| PAPERLESS_DB_NAME                  | Dedicated database name for the Paperless-ngx service.                                      |
| PAPERLESS_DB_USER                  | Dedicated database username for the Paperless-ngx service.                                  |
| PAPERLESS_DB_PASS                  | Dedicated database password for the Paperless-ngx service.                                  |
| PAPERLESS_SECRET_KEY               | A secure, random string used for session encryption in Paperless-ngx.                       |
| SYNAPSE_DB_NAME                    | Dedicated database name for the Synapse service.                                            |
| SYNAPSE_DB_USER                    | Dedicated database username for the Synapse service.                                        |
| SYNAPSE_DB_PASS                    | Dedicated database password for the Synapse service.                                        |
| SYNAPSE_REGISTRATION_SHARED_SECRET | A security key required to authorize user registrations on your Synapse server.             |
| NAVIDROME_MUSIC_FOLDER_PATH        | The absolute path on your host server where your music library is stored.                   |
| AUTHELIA_DB_NAME                   | Dedicated database name for the Authelia SSO service.                                       |
| AUTHELIA_DB_USER                   | Dedicated database username for the Authelia service.                                       |
| AUTHELIA_DB_PASS                   | Dedicated database password for the Authelia service.                                       |
| AUTHELIA_JWT_SECRET                | Secret key for JWT token generation (auto-generated in .env).                               |
| AUTHELIA_SESSION_SECRET            | Secret key for session encryption (auto-generated in .env).                                 |
| AUTHELIA_STORAGE_ENCRYPTION_KEY    | Encryption key for sensitive data storage (auto-generated in .env).                         |

### Secret Generation

To generate secure secret keys:

```bash
# Generate a random 32-character string
openssl rand -base64 32

# Or
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
```

---

## Quick Setup

### Prerequisites

- **Docker and Docker Compose installed**
  
  Install Docker:
  ```bash
  # Ubuntu/Debian
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  
  # Log out and log back in for group changes to take effect
  ```
  
  Install Docker Compose:
  ```bash
  # Download the latest version (check https://github.com/docker/compose/releases for the latest version)
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  
  # Apply executable permissions
  sudo chmod +x /usr/local/bin/docker-compose
  
  # Verify installation
  docker-compose --version
  ```

- **Domain configured with DNS pointing to your server** (see [DNS Configuration with No-IP](#dns-configuration-with-no-ip))
- **Sudo access** for SSL configuration
- **Ports 80 and 443 available**

### Setup Steps

```bash
# 1. Clone the repository
git clone <repository-url>
cd homelab

# 2. Configure environment variables
cp .env.template .env
nano .env  # Fill in all required fields

# 3. Generate SSL certificates
./setup-ssl.sh

# 4. Generate configuration and prepare directories
./scaffold.sh

# 5. Start the infrastructure
./build.sh
```

After these steps, the infrastructure will be accessible at `https://auth.YOURDOMAIN`.

**Default credentials:**

- Username: `admin`
- Password: `admin`

⚠️ **IMPORTANT**: Change the default password immediately by running `./change-authelia-password.sh`

---

## DNS Configuration with No-IP

This homelab infrastructure was designed and tested using **No-IP**, a free dynamic DNS service that provides basic functionality at no cost. No-IP is ideal for home servers with dynamic IP addresses, as it automatically updates your DNS records when your public IP changes.

### Why No-IP?

- **Free tier available**: Offers basic DDNS functionality without cost
- **Easy to use**: Simple setup and configuration
- **Automatic updates**: Keeps your domain pointing to your current IP address
- **Reliable**: Well-established service with good uptime

### Setting Up No-IP

#### 1. Create a No-IP Account

1. Visit [https://www.noip.com](https://www.noip.com)
2. Click on **Sign Up** and create a free account
3. Verify your email address

#### 2. Create a Hostname

1. Log in to your No-IP account
2. Go to **Dynamic DNS** → **No-IP Hostnames**
3. Click **Create Hostname**
4. Choose your desired hostname (e.g., `myhomelab.ddns.net`)
5. Select a domain from the free options (e.g., `ddns.net`, `hopto.org`, etc.)
6. The IP address should auto-populate with your current public IP
7. Click **Create Hostname**

#### 3. Install No-IP Dynamic Update Client (DUC)

To keep your DNS records updated automatically:

```bash
# Download and install the No-IP DUC
cd /usr/local/src
sudo wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
sudo tar xzf noip-duc-linux.tar.gz
cd noip-2.1.9-1
sudo make
sudo make install

# Configure the client (enter your No-IP credentials when prompted)
sudo /usr/local/bin/noip2 -C

# Start the client
sudo /usr/local/bin/noip2
```

#### 4. Configure the Client to Start on Boot

Create a systemd service:

```bash
sudo nano /etc/systemd/system/noip2.service
```

Add the following content:

```ini
[Unit]
Description=No-IP Dynamic DNS Update Client
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable noip2
sudo systemctl start noip2
sudo systemctl status noip2
```

#### 5. Update Your .env File

Once you have your No-IP hostname, update your `.env` file:

```bash
DOMAIN=myhomelab.ddns.net
```

### Important Notes

- **Free tier limitations**: No-IP free accounts require you to confirm your hostname every 30 days via email
- **Wildcard subdomains**: The free tier does not support wildcard DNS, but you can create multiple hostnames for different subdomains (e.g., `auth.myhomelab.ddns.net`, `git.myhomelab.ddns.net`)
- **SSL certificates**: Let's Encrypt works perfectly with No-IP domains
- **Alternative services**: While this homelab was built with No-IP, you can use other DDNS services like DuckDNS, Dynu, or purchase a custom domain

---

## Included Services

### 1. <span style="color: #DC382D;">**Authelia**</span> - SSO Authentication

- **URL**: `https://auth.YOURDOMAIN`
- **Description**: Centralized authentication system with 2FA
- **Database**: Dedicated <span style="color: #316192;">**PostgreSQL**</span>

### 2. <span style="color: #609926;">**Gitea**</span> - Git Repository Manager

- **URL**: `https://git.YOURDOMAIN`
- **Description**: Self-hosted Git platform (GitHub alternative)
- **Database**: Dedicated <span style="color: #316192;">**PostgreSQL**</span>

### 3. <span style="color: #EA4B71;">**n8n**</span> - Workflow Automation

- **URL**: `https://n8n.YOURDOMAIN`
- **Description**: Workflow automation (Zapier alternative)
- **Database**: Dedicated <span style="color: #316192;">**PostgreSQL**</span>

### 4. <span style="color: #609926;">**Synapse**</span> - Matrix Homeserver

- **URL**: `https://synapse.YOURDOMAIN`
- **Description**: Federated Matrix messaging server
- **Database**: <span style="color: #316192;">**PostgreSQL**</span> with 'C' collation

### 5. <span style="color: #4B8BBE;">**Navidrome**</span> - Music Server

- **URL**: `https://music.YOURDOMAIN`
- **Description**: Music streaming server (Subsonic compatible)

### 6. <span style="color: #46A046;">**Paperless-ngx**</span> - Document Management

- **URL**: `https://docs.YOURDOMAIN`
- **Description**: Document management system with OCR
- **Database**: Dedicated <span style="color: #316192;">**PostgreSQL**</span>

---

## Management Scripts

### `scaffold.sh` - Configuration Generation

Generates all configuration files from templates and prepares directories.

```bash
./scaffold.sh
```

**What it does:**

- Validates all required environment variables
- Creates directory structure with correct permissions
- Generates `docker-compose.yaml` files for each service
- Generates <span style="color: #009639;">**NGINX**</span> configurations
- Sets executable permissions on scripts

### `setup-ssl.sh` - SSL Certificates

Obtains and configures SSL certificates via Let's Encrypt.

```bash
./setup-ssl.sh
```

**What it does:**

- Installs certbot (if necessary)
- Requests SSL certificates for all subdomains
- Copies certificates to `ssl/` directory
- Configures automatic renewal via cron

**Certified subdomains:**

- `DOMAIN`
- `auth.DOMAIN`
- `git.DOMAIN`
- `n8n.DOMAIN`
- `music.DOMAIN`
- `docs.DOMAIN`
- `synapse.DOMAIN`

### `build.sh` - Complete Deployment

Starts the entire infrastructure in the correct order.

```bash
./build.sh
```

**Startup sequence:**

1. Creates shared Docker network
2. Starts <span style="color: #316192;">**PostgreSQL**</span>
3. Waits for <span style="color: #316192;">**PostgreSQL**</span> to be ready
4. Provisions databases (`init-db.sh`)
5. Starts services in order: <span style="color: #EA4B71;">**n8n**</span>, <span style="color: #609926;">**Synapse**</span>, <span style="color: #609926;">**Gitea**</span>, <span style="color: #4B8BBE;">**Navidrome**</span>, <span style="color: #46A046;">**Paperless**</span>, <span style="color: #DC382D;">**Authelia**</span>
6. Starts System Metrics API
7. Starts <span style="color: #009639;">**NGINX**</span> (reverse proxy)

### `startup.sh` - Start Services

Starts all services (useful after a server reboot).

```bash
./startup.sh
```

### `shutdown.sh` - Stop Services

Stops all services without removing containers.

```bash
./shutdown.sh
```

### `restart-service.sh` - Restart Single Service

Restarts a specific service via interactive menu.

```bash
./restart-service.sh
```

**Available services:**

1. db (<span style="color: #316192;">**PostgreSQL**</span>)
2. <span style="color: #DC382D;">**authelia**</span>
3. stats-api
4. <span style="color: #009639;">**nginx**</span>
5. <span style="color: #EA4B71;">**n8n**</span>
6. <span style="color: #609926;">**synapse**</span>
7. <span style="color: #609926;">**gitea**</span>
8. <span style="color: #4B8BBE;">**navidrome**</span>
9. <span style="color: #46A046;">**paperless**</span>

### `init-db.sh` - Database Provisioning

Creates <span style="color: #316192;">**PostgreSQL**</span> databases and users for all services.

```bash
./init-db.sh
```

**What it does:**

- Creates <span style="color: #316192;">**PostgreSQL**</span> users for each service
- Creates dedicated databases
- Assigns appropriate privileges
- Applies 'C' collation for <span style="color: #609926;">**Synapse**</span> (specific requirement)

### `change-authelia-password.sh` - Password Change

Changes the password for an <span style="color: #DC382D;">**Authelia**</span> user.

```bash
./change-authelia-password.sh
```

**Interactive process:**

1. Requests username (default: admin)
2. Requests new password
3. Confirms password
4. Generates Argon2 hash
5. Updates user database
6. Restarts <span style="color: #DC382D;">**Authelia**</span>

### `cleanup.sh` - Complete Cleanup

⚠️ **WARNING**: Removes EVERYTHING (containers, images, volumes, data).

```bash
./cleanup.sh
```

**What it removes:**

- All Docker containers
- All Docker images
- Shared Docker network
- All data and configuration directories

**Use only if you want to start from scratch!**

---

## Backup and Restore

### Backup

Creates a complete infrastructure backup.

```bash
./backup.sh
```

**What gets saved:**

- All `data/` directories
- <span style="color: #316192;">**PostgreSQL**</span> database (`db/`)
- <span style="color: #009639;">**NGINX**</span> configurations (`nginx/`)
- Landing page (`landing/`)
- Configuration files (`.env`, `index.html`)

**Backup location:** `~/bkp/homelab_backup_YYYYMMDD_HHMMSS.tar.gz`

**Best practices:**

- Stop services before backup for data consistency
- Backup includes a warning if containers are running
- Schedule regular backups via cron

### Restore

Restores a previous backup.

```bash
sudo ./restore.sh
```

**Interactive process:**

1. Shows list of the last 10 available backups
2. Allows selection of backup to restore
3. Offers to stop running containers
4. Creates a safety backup of current data
5. Restores data from selected backup
6. Sets correct permissions

⚠️ **Requires sudo** to properly manage permissions.

**Safety backup:** Before restore, a backup of current data is automatically created at
`~/bkp/pre_restore_backup_YYYYMMDD_HHMMSS.tar.gz`

---

## Troubleshooting

### Services won't start

```bash
# Check container status
docker ps -a

# Check logs for a specific service
docker compose -f <service>/docker-compose.yaml logs -f

# Example for Authelia
docker compose -f authelia/docker-compose.yaml logs -f
```

### <span style="color: #316192;">**PostgreSQL**</span> won't connect

```bash
# Verify PostgreSQL is running
docker exec shared_postgres pg_isready -U postgres

# Check logs
docker compose -f db/docker-compose.yaml logs -f

# Restart database
docker compose -f db/docker-compose.yaml restart
```

### SSL certificate issues

```bash
# Verify certificates
ls -la ssl/

# Regenerate certificates
./setup-ssl.sh

# Check expiration
openssl x509 -in ssl/fullchain.pem -noout -dates
```

### Permission errors

```bash
# Re-run scaffold to restore permissions
./scaffold.sh

# Or manually for a specific service
sudo chown -R $(id -u):$(id -g) data/<service>
chmod -R 755 data/<service>
```

### Forgotten <span style="color: #DC382D;">**Authelia**</span> password reset

```bash
# Use the dedicated script
./change-authelia-password.sh

# Or restore default 'admin:admin' by re-running scaffold
./scaffold.sh
docker compose -f authelia/docker-compose.yaml restart
```

### Docker network not found

```bash
# Recreate the network
docker network create homelab_net

# Or re-run build
./build.sh
```

### Insufficient disk space

```bash
# Clean unused images and containers
docker system prune -a

# Check space usage
docker system df

# Check data directory sizes
du -sh data/*
```

---

## Monitoring

### Check service status

```bash
# All containers
docker ps

# Specific service
docker compose -f <service>/docker-compose.yaml ps

# Resource usage
docker stats
```

### Logs

```bash
# Real-time logs for a service
docker compose -f <service>/docker-compose.yaml logs -f

# Last 100 logs
docker compose -f <service>/docker-compose.yaml logs --tail=100

# Logs saved to disk
ls -lh logs/
```

---

## Security

### Best Practices

1. **Change default passwords immediately**
   ```bash
   ./change-authelia-password.sh
   ```

2. **Use strong passwords** for all databases and services

3. **Keep SSL certificates updated**
    - Automatic renewal is configured via cron
    - Check periodically: `openssl x509 -in ssl/fullchain.pem -noout -dates`

4. **Regular backups**
    - Configure automatic daily/weekly backups
    - Test restore periodically

5. **Firewall**
    - Expose only ports 80 and 443
    - Block direct access to service ports

6. **Updates**
    - Regularly update Docker images
   ```bash
   docker compose -f <service>/docker-compose.yaml pull
   docker compose -f <service>/docker-compose.yaml up -d
   ```

---

## Additional Notes

### Landing Page Customization

You can customize the landing page by modifying `index.html` in the project root before running `./scaffold.sh`.

### Adding new services

To add a new service:

1. Create a template in `templates/<service>/`
2. Add generation in `scaffold.sh`
3. Add the service in `build.sh`, `startup.sh`, `shutdown.sh`
4. Create <span style="color: #009639;">**NGINX**</span> configuration in `templates/nginx/`

### Service Access

After deployment, services are accessible via:

- Landing page: `https://YOURDOMAIN`
- <span style="color: #DC382D;">**Authelia**</span> SSO: `https://auth.YOURDOMAIN`
- <span style="color: #609926;">**Gitea**</span>: `https://git.YOURDOMAIN`
- <span style="color: #EA4B71;">**n8n**</span>: `https://n8n.YOURDOMAIN`
- <span style="color: #609926;">**Synapse**</span>: `https://synapse.YOURDOMAIN`
- <span style="color: #4B8BBE;">**Navidrome**</span>: `https://music.YOURDOMAIN`
- <span style="color: #46A046;">**Paperless**</span>: `https://docs.YOURDOMAIN`

---

## Customization

Customize the landing page by creating `index.html` in the project root.

After editing, regenerate and reload:

```bash
./scaffold.sh
docker exec nginx -s reload
```

---

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Verify service logs
3. Consult the official documentation for individual services

---

## License

This project is provided "as-is" for personal use.
