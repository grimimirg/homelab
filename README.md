# Modular Homelab Infrastructure

This project provides a modular, containerized approach to managing your home services
using Docker and Nginx as a reverse proxy. The infrastructure is defined as code (IaC), allowing for rapid setup,
deployment, and cleanup.

## Table of Contents

- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
  - [1. Configuration](#1-configuration)
  - [2. SSL Setup](#2-ssl-setup)
  - [3. Deployment](#3-deployment)
  - [4. Verify Deployment](#4-verify-deployment)
  - [5. Start and Stop](#5-start-and-stop)
- [Authentication](#authentication)
  - [Authelia SSO](#authelia-sso)
  - [First Login](#first-login)
  - [Managing Users](#managing-users)
- [Network Access](#network-access)
  - [Local Network Access](#local-network-access)
  - [External Access via No-IP](#external-access-via-no-ip)
  - [Wildcard DNS Configuration](#wildcard-dns-configuration)
- [Customization](#customization)
  - [Customizing the Landing Page](#customizing-the-landing-page)
- [Docker Statistics Dashboard](#docker-statistics-dashboard)
  - [Features](#features)
  - [Architecture](#architecture-1)
  - [API Endpoints](#api-endpoints)
  - [Deployment](#deployment)
  - [Testing](#testing)
  - [Customization](#customization-1)
  - [Troubleshooting](#troubleshooting-1)
- [Management](#management)
  - [Service Management](#service-management)
  - [Backup and Restore](#backup-and-restore)
- [Security](#security)
  - [Security Best Practices](#security-best-practices)
  - [SSL Certificate Management](#ssl-certificate-management)
- [Troubleshooting](#troubleshooting)
- [Reference](#reference)
  - [Port Mapping Reference](#port-mapping-reference)

---

## Architecture

The system is built on a modular design where each service has its own directory and lifecycle, coordinated by a central
set of orchestration scripts.

* **Reverse Proxy:** Nginx (Containerized).
* **Authentication:** Authelia SSO (Single Sign-On).
* **Database:** PostgreSQL (Centralized).
* **Services:** Synapse, n8n, gitea, paperless, navidrome.
* **Network:** Shared bridge network.

## Project Structure

```
├── build.sh                                 # Orchestrator to build and boot all services
├── change-authelia-password.sh              # Helper script to change Authelia user passwords
├── cleanup.sh                               # Full environment wipe script
├── index.html                               # (Optional) Custom landing page
├── init-db.sh                               # Automated DB/User provisioning
├── README.md                                # Documentation
├── scaffold.sh                              # Scaffolding and config generator
├── setup-ssl.sh                             # SSL certificate helper
├── shutdown.sh                              # Orchestrator to manually stop all services
├── startup.sh                               # Orchestrator to manually start all services
├── statistics-app                           # Docker stats API application
│    ├── docker-stats-api.py                 # Flask API for Docker statistics
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
    ├── statistics-app                       # Docker statistics API
    │   └── docker-compose.yaml.template     # Docker Compose template for stats API
    └── synapse                              # Synapse server definitions
        ├── synapse.conf.template            # Nginx proxy conf for synapse
        └── synapse.yaml.template            # Docker Compose template for synapse
```

## System Requirements

### Software Dependencies

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Bash**: For running orchestration scripts
- **Certbot**: For SSL certificate generation (installed automatically by setup-ssl.sh)

#### Check Versions

```bash
docker --version
docker compose --version
bash --version
```

### Network Requirements

- Static local IP address (recommended for homelab server)
- Port forwarding configured on router (for external access):
  - Port 80 → Server IP:80
  - Port 443 → Server IP:443
  - Port 8448 → Server IP:8448 (if using Matrix/Synapse)

### Domain Requirements

- Registered domain name (free options: No-IP, DuckDNS, FreeDNS)
- DNS configuration:
  - **Recommended**: Wildcard DNS record (`*.yourdomain.com`) pointing to your public IP
  - **Alternative**: Individual A records for each subdomain
- Dynamic DNS client if you don't have a static public IP (see [External Access via No-IP](#external-access-via-no-ip))

---

## Quick Start

This workflow uses a clear separation between infrastructure generation and service execution.

### 1. Configuration

Create a `.env` file in the project root. You can start from the provided template:

```bash
cp .env.template .env
nano .env  # or use your preferred editor
```

Configure the following variables:

| Variable                           | Description                                                                                 |
|------------------------------------|--------------------------------------------------------------------------------------------|
| DOMAIN                             | The primary domain name used for SSL certificate issuance and public access.                |
| EMAIL                              | Contact email address used by Let's Encrypt for SSL certificate notifications.              |
| SHARED_NETWORK                     | The shared network used by containers to communicate with eachother.                        |
| TZ                                 | Timezone for services (e.g., Europe/Rome, America/New_York, Asia/Tokyo).                   |
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
| AUTHELIA_DB_NAME                   | Dedicated database name for the Authelia SSO service.                                       |
| AUTHELIA_DB_USER                   | Dedicated database username for the Authelia service.                                       |
| AUTHELIA_DB_PASS                   | Dedicated database password for the Authelia service.                                       |
| AUTHELIA_JWT_SECRET                | Secret key for JWT token generation (auto-generated in .env).                               |
| AUTHELIA_SESSION_SECRET            | Secret key for session encryption (auto-generated in .env).                                 |
| AUTHELIA_STORAGE_ENCRYPTION_KEY    | Encryption key for sensitive data storage (auto-generated in .env).                         |

### 2. SSL Setup

Generate SSL certificates for your domain and all subdomains:

```bash
./setup-ssl.sh
```

This script will:
- Install certbot if not present
- Request a multi-domain certificate covering:
  - `yourdomain.com`
  - `auth.yourdomain.com`
  - `git.yourdomain.com`
  - `n8n.yourdomain.com`
  - `music.yourdomain.com`
  - `docs.yourdomain.com`
  - `synapse.yourdomain.com`
- Copy certificates to the `ssl/` directory

**Note**: If you add new services later, you'll need to update `setup-ssl.sh` and regenerate certificates.

### 3. Deployment

Generate configurations and start all services:

```bash
# Generate configurations from templates
./scaffold.sh

# Build and start all services
./build.sh
```

The `build.sh` script will:
1. Create the shared Docker network
2. Start PostgreSQL database
3. Wait for database readiness
4. Provision database users and schemas (including Authelia)
5. Start all services (authelia, stats-api, nginx, gitea, n8n, navidrome, paperless, synapse)
6. Display Authelia login credentials

### 4. Verify Deployment

After deployment, verify all services are running correctly:

```bash
# Check all containers are running
docker ps

# You should see these containers:
# - db (PostgreSQL)
# - authelia (SSO)
# - docker-stats-api (Statistics API)
# - nginx (Reverse Proxy)
# - gitea
# - n8n
# - navidrome
# - paperless-webserver
# - paperless-redis
# - synapse
```

**Access the landing page:**

1. Open your browser and navigate to `https://yourdomain.com`
2. Login with Authelia default credentials:
   - Username: `admin`
   - Password: `admin`
   - **⚠️ Change this password immediately after first login!**
3. You should see:
   - Landing page with service cards
   - **System Status** section showing real-time Docker statistics
   - **Active Containers** list with running containers

**Test the statistics API** (optional):

```bash
# From the statistics-app directory
cd statistics-app
./test-docker-stats.sh

# Or manually test the endpoint (requires authentication)
curl https://yourdomain.com/api/docker/stats
```

### 5. Start and Stop

After initial deployment, use these commands to manage services:

```bash
# Start all services
./startup.sh

# Stop all services
./shutdown.sh
```

### Cleanup

**Warning:** Running `cleanup.sh` will stop containers, remove the network, and delete the generated configurations and
data directories. **This will delete your databases.**

```
./cleanup.sh
```

---

## Authentication

### Authelia SSO

This homelab uses **Authelia** as a Single Sign-On (SSO) solution to protect all services with centralized authentication.

#### How It Works

1. **All services are protected** - Landing page, Gitea, n8n, Navidrome, Paperless, and Synapse require authentication
2. **Single login** - Login once at `https://auth.${DOMAIN}` and access all services
3. **Session-based** - Sessions last 1 hour by default
4. **Custom theme** - Login page uses the same retro/terminal style as the landing page

#### Architecture

```
User → https://yourdomain.com
  ↓
Nginx checks authentication with Authelia
  ↓
Not authenticated? → Redirect to https://auth.yourdomain.com (login)
  ↓
Authenticated? → Show landing page with service links
  ↓
Click on service (e.g., Gitea) → Access granted automatically
```

### First Login

After deployment, access the authentication portal:

```bash
# Open in browser
https://auth.${DOMAIN}
```

**Default credentials:**
- Username: `admin`
- Password: `admin`

**⚠️ Important:** Change the default password immediately after first login!

To change the password, run:
```bash
./change-authelia-password.sh
```

### Managing Users

#### View Current Users

Users are stored in a file-based database:

```bash
cat data/authelia/users_database.yml
```

#### Add a New User

1. Generate a password hash:

```bash
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'your_password_here'
```

2. Edit the users database:

```bash
nano data/authelia/users_database.yml
```

3. Add the new user:

```yaml
users:
  admin:
    disabled: false
    displayname: "Administrator"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: admin@yourdomain.com
    groups:
      - admins
  
  newuser:
    disabled: false
    displayname: "New User"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."  # Generated hash
    email: newuser@yourdomain.com
    groups:
      - users
```

4. Restart Authelia:

```bash
docker compose -f authelia/docker-compose.yaml restart
```

#### Change Password

**Easy Method (Recommended):**

Use the provided script:

```bash
./change-authelia-password.sh
```

The script will:
1. Ask for the username (default: admin)
2. Prompt for new password (with confirmation)
3. Generate the password hash automatically
4. Update the users database
5. Restart Authelia

**Manual Method:**

1. Generate new password hash:
   ```bash
   docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'YourNewPassword'
   ```

2. Update the hash in `data/authelia/users_database.yml`

3. Restart Authelia:
   ```bash
   docker compose -f authelia/docker-compose.yaml restart
   ```

#### Disable a User

Set `disabled: true` in the user's entry:

```yaml
users:
  olduser:
    disabled: true
    displayname: "Old User"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: olduser@yourdomain.com
    groups:
      - users
```

### Session Configuration

Sessions are configured in `data/authelia/configuration.yml`:

```yaml
session:
  expiration: 1h        # Session expires after 1 hour
  inactivity: 1h        # Session expires after 1 hour of inactivity
  remember_me_duration: 1M  # "Remember me" lasts 1 month
```

To change session duration:

1. Edit `templates/authelia/configuration.yml.template`
2. Run `./scaffold.sh` to regenerate configs
3. Restart Authelia

---

## Network Access

### Wildcard DNS Configuration

For external access to all services without creating individual DNS records, configure a **wildcard DNS** on your DNS provider (e.g., No-IP):

1. Log into your DNS provider dashboard
2. Enable wildcard DNS for your domain
3. Create a wildcard record: `*.yourdomain.com` → Your public IP

This single record will automatically route all subdomains (`git.yourdomain.com`, `n8n.yourdomain.com`, etc.) to your server.

**Benefits:**
- ✅ One DNS record covers all services
- ✅ No need to add records when adding new services
- ✅ Simplified DNS management

**After enabling wildcard DNS:**
- `yourdomain.com` → Landing page (protected)
- `auth.yourdomain.com` → Authelia SSO login
- `git.yourdomain.com` → Gitea (protected)
- `n8n.yourdomain.com` → n8n (protected)
- `music.yourdomain.com` → Navidrome (protected)
- `docs.yourdomain.com` → Paperless (protected)
- `synapse.yourdomain.com` → Matrix (protected)

---

## Customization

### Customizing the Landing Page

The homelab includes a default landing page accessible at `http://local.server.name` (or `http://localhost` from the server itself). This page provides a central portal with links to all your services.

## Using the Default Landing Page

By default, `./scaffold.sh` generates a landing page from `templates/landing/default.index.html.template`. This template includes cards for all services with links to their respective URLs.

## Creating a Custom Landing Page

To customize the landing page:

### 1. Edit the Landing Page

Edit `index.html` in the project root to customize:
- Colors and styling
- Service descriptions
- Icons
- Layout
- Additional links or information

### 2. Use Environment Variables (Optional)

Your custom `index.html` can use environment variables from `.env`:

```html
<a href="http://git.${DOMAIN}">Gitea</a>
<p>Network: ${SHARED_NETWORK}</p>
```

These will be replaced when you run `./scaffold.sh`.

### 3. Regenerate Configurations

```bash
./scaffold.sh
```

The custom `index.html` will be used instead of the default template.

### 4. Reload Nginx

```bash
docker exec nginx nginx -s reload
```

Or restart the nginx container:

```bash
cd nginx
docker-compose restart
```

## Reverting to Default

To revert to the default landing page:

```bash
rm index.html
./scaffold.sh
```

**Note:** The `index.html` file in the project root is gitignored, so your customizations won't be committed to version control.

---

## Docker Statistics Dashboard

The homelab includes a real-time Docker statistics dashboard integrated into the landing page. This feature provides live monitoring of your container infrastructure.

### Features

The statistics dashboard displays:

- **General Statistics**
  - Running containers count
  - Stopped containers count
  - Total Docker images
  - Total Docker networks

- **Active Containers List**
  - Container name
  - Image name and version
  - Current state (with color-coded status indicator)
  - Uptime information

- **Auto-refresh**: Statistics update automatically every 10 seconds

### Architecture

The dashboard is powered by a dedicated Flask API service that queries the Docker daemon:

```
Browser → Nginx/Traefik → Statistics API (Python) → Docker Socket → Container Info
```

**Components:**

1. **statistics-app/** - Python Flask application
   - `docker-stats-api.py` - REST API that queries Docker
   - `Dockerfile` - Container definition
   - `requirements.txt` - Python dependencies (flask, flask-cors, docker)

2. **Frontend Integration** - Landing page dashboard
   - JavaScript fetches `/api/docker/stats` every 10 seconds
   - Retro-terminal themed UI matching the landing page style
   - Responsive design for mobile devices

3. **Security**
   - Protected by Authelia SSO (same as other services)
   - Docker socket mounted as read-only
   - HTTPS-only access with Let's Encrypt certificates

### API Endpoints

The statistics API exposes:

- `GET /api/docker/stats` - Returns Docker statistics in JSON format
- `GET /health` - Health check endpoint

**Response Format:**

```json
{
  "running": 5,
  "stopped": 2,
  "images": 12,
  "networks": 3,
  "containers": [
    {
      "name": "gitea",
      "image": "gitea/gitea:latest",
      "state": "running",
      "uptime": "2d 5h"
    },
    {
      "name": "synapse",
      "image": "matrixdotorg/synapse:latest",
      "state": "running",
      "uptime": "1d 3h"
    }
  ]
}
```

### Deployment

The statistics service is automatically deployed with the homelab:

```bash
# Generate configurations (includes statistics API)
./scaffold.sh

# Start all services (includes statistics API)
./startup.sh
```

The service will be available at:
- API: `https://yourdomain.com/api/docker/stats` (requires authentication)
- Dashboard: Integrated into landing page at `https://yourdomain.com`

### Testing

Test the statistics API:

```bash
cd statistics-app
./test-docker-stats.sh
```

Or manually test the endpoints:

```bash
# Health check (may be accessible without auth depending on config)
curl https://yourdomain.com/health

# Statistics endpoint (requires Authelia authentication)
# Access via browser after logging in
```

### Customization

#### Adjust Refresh Interval

Edit `templates/landing/default.index.html.template`:

```javascript
// Change from 10000 (10 seconds) to desired interval
setInterval(fetchDockerStats, 10000);
```

Then regenerate:

```bash
./scaffold.sh
docker exec nginx nginx -s reload
```

#### Modify Dashboard Styling

The dashboard uses the same retro-terminal theme as the landing page. To customize:

1. Edit `templates/landing/homelab-theme.css`
2. Modify the `.stats-section`, `.stat-card`, or `.container-item` classes
3. Regenerate and reload:

```bash
./scaffold.sh
docker exec nginx nginx -s reload
```

### Troubleshooting

#### Dashboard Shows "ERROR LOADING DATA"

**Possible Causes:**
- Statistics API container not running
- Docker socket not accessible
- Network connectivity issues

**Solutions:**

1. Check if the container is running:
   ```bash
   docker ps | grep docker-stats-api
   ```

2. Check container logs:
   ```bash
   docker logs docker-stats-api
   ```

3. Verify Docker socket is mounted:
   ```bash
   docker inspect docker-stats-api | grep docker.sock
   ```

4. Restart the statistics service:
   ```bash
   docker compose -f stats-api/docker-compose.yaml restart
   ```

#### Statistics Not Updating

**Solutions:**

1. Check browser console for JavaScript errors (F12)
2. Verify API endpoint is accessible:
   ```bash
   curl https://yourdomain.com/api/docker/stats
   ```
3. Clear browser cache and reload the page

#### Permission Denied Errors

**Cause:** The API cannot access the Docker socket

**Solution:**

Ensure the Docker socket is mounted with correct permissions in `templates/statistics-app/docker-compose.yaml.template`:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

The `:ro` flag ensures read-only access for security.

---

### Local Network Access

To access your homelab services from other devices on your local network (e.g., `git.local.server.name`, `n8n.local.server.name`), you need to configure DNS resolution on each client device.

#### Prerequisites

- Know the **local IP address** of your homelab server (e.g., `192.168.1.100`)
- Know the **hostname** of your server (e.g., `local.server.name`)

#### Configuration by Operating System

##### Linux

Edit the `/etc/hosts` file with root privileges:

```bash
sudo nano /etc/hosts
```

Add the following lines (replace `192.168.1.100` with your server's IP):

```
192.168.1.100  git.server_name n8n.server_name navidrome.server_name paperless.server_name synapse.server_name
```

Save and exit. Changes take effect immediately.

##### macOS

Edit the `/etc/hosts` file with root privileges:

```bash
sudo nano /etc/hosts
```

Add the following lines (replace `192.168.1.100` with your server's IP):

```
192.168.1.100  git.server_name n8n.server_name navidrome.server_name paperless.server_name synapse.server_name
```

Save and exit. Flush the DNS cache:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

##### Windows

1. Open **Notepad** as Administrator (right-click → Run as administrator)
2. Open the file: `C:\Windows\System32\drivers\etc\hosts`
3. Add the following lines (replace `192.168.1.100` with your server's IP):

```
192.168.1.100  git.server_name n8n.server_name navidrome.server_name paperless.server_name synapse.server_name
```

4. Save the file
5. Flush DNS cache by opening **Command Prompt** as Administrator and running:

```cmd
ipconfig /flushdns
```

#### Testing

After configuration, test the connection from your client device:

```bash
ping git.server_name
curl http://git.server_name
```

#### HTTPS Considerations

**Note:** When accessing services via local hostnames (e.g., `https://git.local.server.name`), your browser will show a certificate warning because the SSL certificate is issued for your public domain (e.g., `yourdomain.com`), not for local hostnames.

**Options:**
- Use **HTTP** instead: `http://git.server_name` (no certificate warning)
- Accept the certificate warning in your browser (not recommended for production)
- Generate self-signed certificates for local hostnames (advanced)

---

### External Access via No-IP

To expose your homelab to the internet with a dynamic IP address, use the **No-IP Dynamic Update Client (DUC) v3**.

#### Method 1: On-Demand

Use this method to run the process only once manually.

```
noip-duc --username [username] \\
   --password [password] \\
   --hostnames [group] \\ # It can be found in https://my.noip.com/ddns-keys
   --once
```

#### Method 2: Direct Daemon

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

#### Method 3: Systemd Service (Recommended)

Systemd ensures the client starts automatically after a reboot and restarts if the process crashes.

##### 1. Create the Service File

Open a terminal and run:

```
sudo nano /etc/systemd/system/noip-duc.service
```

##### 2. Paste the following configuration

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

##### 3. Enable and Start

###### Reload systemd to recognize the new service
```
sudo systemctl daemon-reload
```

###### Enable service to start on boot

```
sudo systemctl enable noip-duc
```

###### Start the service immediately

```
sudo systemctl start noip-duc
```

##### 4. Check Status

```
sudo systemctl status noip-duc
```

**Security Tip:** To avoid leaving your password in a plain text file, consider using **Environment Variables** in a protected `.conf` file as mentioned in the No-IP advanced documentation.

---

## Management

### Service Management

#### Monitoring Services

##### Check Running Containers

View all running containers:

```bash
docker ps
```

View all containers (including stopped):

```bash
docker ps -a
```

##### View Service Logs

View logs for a specific service:

```bash
docker logs -f <container_name>
```

Examples:

```bash
docker logs -f gitea
docker logs -f nginx
docker logs -f synapse
```

View last 100 lines:

```bash
docker logs --tail 100 <container_name>
```

##### Inspect Network

Check the shared network configuration:

```bash
docker network inspect ${SHARED_NETWORK}
```

##### Reload Nginx Configuration

After modifying nginx configuration files:

```bash
docker exec nginx nginx -t          # Test configuration
docker exec nginx nginx -s reload   # Reload if test passes
```

#### Updating Services

##### Update All Services

Pull the latest images and restart containers:

```bash
cd <service_directory>
docker compose pull
docker compose up -d
```

##### Update Specific Service

```bash
cd gitea
docker compose pull
docker compose up -d
```

##### Update All at Once

```bash
./shutdown.sh
docker compose -f db/docker compose.yaml pull
docker compose -f nginx/docker compose.yaml pull
docker compose -f gitea/docker compose.yaml pull
docker compose -f n8n/docker compose.yaml pull
docker compose -f navidrome/docker compose.yaml pull
docker compose -f paperless/docker compose.yaml pull
docker compose -f synapse/docker compose.yaml pull
./startup.sh
```

---

### Backup and Restore

#### What to Backup

##### 1. Environment Configuration

```bash
cp .env .env.backup
```

##### 2. Data Volumes

All service data is stored in the `data/` directory:

```bash
tar -czf homelab-data-backup-$(date +%Y%m%d).tar.gz data/
```

##### 3. PostgreSQL Database

Backup all databases:

```bash
docker exec db pg_dumpall -U ${POSTGRES_USER} > backup-$(date +%Y%m%d).sql
```

Backup specific database:

```bash
docker exec db pg_dump -U ${POSTGRES_USER} gitea > gitea-backup-$(date +%Y%m%d).sql
```

##### 4. SSL Certificates

```bash
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz ssl/
```

#### Restore from Backup

##### Restore Data Volumes

```bash
tar -xzf homelab-data-backup-YYYYMMDD.tar.gz
```

##### Restore PostgreSQL Database

```bash
cat backup-YYYYMMDD.sql | docker exec -i db psql -U ${POSTGRES_USER}
```

##### Restore Specific Database

```bash
cat gitea-backup-YYYYMMDD.sql | docker exec -i db psql -U ${POSTGRES_USER} -d gitea
```

---

## Troubleshooting

### Common Issues

#### Nginx Fails to Start

**Symptom:** Nginx container exits immediately

**Possible Causes:**
- SSL certificates not found
- Configuration syntax error
- Port already in use

**Solutions:**

1. Check SSL certificates exist:
   ```bash
   ls -la ssl/
   ```

2. Test nginx configuration:
   ```bash
   docker run --rm -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
     -v $(pwd)/nginx/conf.d:/etc/nginx/conf.d:ro \
     nginx:alpine nginx -t
   ```

3. Check if ports are already in use:
   ```bash
   sudo netstat -tulpn | grep -E ':(80|443|8448)'
   ```

#### Database Connection Failed

**Symptom:** Services can't connect to PostgreSQL

**Solutions:**

1. Verify database is running:
   ```bash
   docker ps | grep db
   ```

2. Check database logs:
   ```bash
   docker logs db
   ```

3. Verify credentials in `.env` file match those used in `init-db.sh`

4. Test database connection:
   ```bash
   docker exec -it db psql -U ${POSTGRES_USER} -d gitea
   ```

#### 502 Bad Gateway

**Symptom:** Nginx returns 502 error

**Possible Causes:**
- Backend service is not running
- Service is starting up (wait a moment)
- Network configuration issue

**Solutions:**

1. Check if the backend service is running:
   ```bash
   docker ps | grep <service_name>
   ```

2. Check service logs:
   ```bash
   docker logs <service_name>
   ```

3. Verify services are on the same network:
   ```bash
   docker network inspect ${SHARED_NETWORK}
   ```

#### Container Exits Immediately

**Symptom:** Container starts then stops

**Solutions:**

1. Check container logs:
   ```bash
   docker logs <container_name>
   ```

2. Check file permissions (especially for services with `user:` directive):
   ```bash
   ls -la data/<service_name>/
   ```

3. Fix permissions if needed:
   ```bash
   sudo chown -R ${HOST_UID}:${HOST_GID} data/<service_name>/
   ```

#### Services Can't Communicate

**Symptom:** Services can't reach each other

**Solutions:**

1. Verify all services are on the shared network:
   ```bash
   docker network inspect ${SHARED_NETWORK}
   ```

2. Ensure network exists:
   ```bash
   docker network ls | grep ${SHARED_NETWORK}
   ```

3. Recreate network if needed:
   ```bash
   docker network create ${SHARED_NETWORK}
   ```

#### Local Hostname Not Resolving

**Symptom:** `git.local.server.name` doesn't work from client device

**Solutions:**

1. Verify `/etc/hosts` entry exists on client device

2. Flush DNS cache (see Local Network Access section)

3. Test with IP directly:
   ```bash
   curl http://192.168.1.100
   ```

4. Verify nginx is listening:
   ```bash
   docker exec nginx netstat -tulpn | grep :80
   ```

#### Authentication Loop / Redirect Issues

**Symptom:** Redirected to login page repeatedly, or "401 Unauthorized" errors

**Possible Causes:**
- Authelia container not running
- Session cookie issues
- Time synchronization problems

**Solutions:**

1. Check Authelia is running:
   ```bash
   docker ps | grep authelia
   ```

2. Check Authelia logs:
   ```bash
   docker logs authelia
   ```

3. Verify Authelia database connection:
   ```bash
   docker exec authelia cat /config/configuration.yml | grep -A 5 storage
   ```

4. Clear browser cookies for your domain

5. Check system time is synchronized:
   ```bash
   timedatectl status
   ```

6. Restart Authelia:
   ```bash
   docker compose -f authelia/docker-compose.yaml restart
   ```

#### Cannot Login to Authelia

**Symptom:** Login fails with "Incorrect username or password"

**Solutions:**

1. Verify user exists in database:
   ```bash
   cat data/authelia/users_database.yml
   ```

2. Check if user is disabled:
   ```yaml
   users:
     admin:
       disabled: false  # Should be false
   ```

3. Reset admin password to default:
   ```bash
   # Edit users database
   nano data/authelia/users_database.yml
   
   # Replace admin password hash with default (admin/admin)
   password: "$argon2id$v=19$m=65536,t=3,p=4$YnJpbWlyaWdob21lbGFi$VZzFqLFoE3K3xN5qH8vN5xGqJ8mP2wR4tY6uI9oP0qE"
   
   # Restart Authelia
   docker compose -f authelia/docker-compose.yaml restart
   ```

---

## Security

### Security Best Practices

#### Change Default Passwords

After initial setup, change all default passwords:

1. **Authelia admin password** - Login to `https://auth.${DOMAIN}` and change password immediately
2. **PostgreSQL admin password** - Update in `.env` and recreate database
3. **Service-specific passwords** - Update in each service's web interface (note: with SSO, you may not need service-specific logins)
4. **Synapse registration secret** - Update in `.env` and regenerate config

#### Firewall Configuration

Configure your firewall to only allow necessary ports:

```bash
# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Matrix federation (if using Synapse)
sudo ufw allow 8448/tcp

# Enable firewall
sudo ufw enable
```

### SSL Certificate Management

#### SSL Certificate Cleanup

If you need to remove existing certificates before regenerating them:

```bash
# List existing certificates
sudo certbot certificates

# Delete certificate for your domain
sudo certbot delete --cert-name your.domain

# Clean local SSL directory
rm -rf ssl/*
```

After cleanup, regenerate certificates with:

```bash
./setup-ssl.sh
```

#### SSL Certificate Renewal

Let's Encrypt certificates expire every 90 days. Set up automatic renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab for automatic renewal
sudo crontab -e
```

Add this line to renew certificates monthly:

```
0 0 1 * * certbot renew --quiet && docker exec nginx nginx -s reload
```

#### Secure the .env File

Protect your environment file:

```bash
chmod 600 .env
```

Never commit `.env` to version control.

#### Regular Updates

Keep your services updated to patch security vulnerabilities:

```bash
# Update all images monthly
./shutdown.sh
docker compose -f */docker compose.yaml pull
./startup.sh
```

---

## Reference

### Port Mapping Reference

#### External Ports (Exposed to Host)

| Service    | Port | Protocol | Purpose                    |
|------------|------|----------|----------------------------|
| Nginx      | 80   | HTTP     | Web traffic (redirects)    |
| Nginx      | 443  | HTTPS    | Secure web traffic         |
| Nginx      | 8448 | HTTPS    | Matrix federation          |

#### Internal Ports (Container Network Only)

| Service    | Port | Access Via                          |
|------------|------|-------------------------------------|
| PostgreSQL | 5432 | Internal network only               |
| Authelia   | 9091 | `auth.${DOMAIN}` via nginx          |
| Gitea      | 3000 | `git.${DOMAIN}` via nginx           |
| n8n        | 5678 | `n8n.${DOMAIN}` via nginx           |
| Navidrome  | 4533 | `music.${DOMAIN}` via nginx         |
| Paperless  | 8000 | `docs.${DOMAIN}` via nginx          |
| Synapse    | 8008 | `synapse.${DOMAIN}` via nginx       |
| Redis      | 6379 | Paperless only                      |

**Note:** Only nginx exposes ports to the host. All other services are accessed through nginx reverse proxy.

**Authentication:** All services (except Authelia itself) require authentication via Authelia SSO.
