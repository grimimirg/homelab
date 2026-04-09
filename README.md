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
├── index.html                               # (Optional) Custom landing page
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

# Customizing the Landing Page

The homelab includes a default landing page accessible at `http://jarvis` (or `http://localhost` from the server itself). This page provides a central portal with links to all your services.

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

- - -

# Local Network Access

To access your homelab services from other devices on your local network (e.g., `git.server_name`, `n8n.server_name`), you need to configure DNS resolution on each client device.

## Prerequisites

- Know the **local IP address** of your homelab server (e.g., `192.168.1.100`)
- Know the **hostname** of your server (e.g., `jarvis`)

## Configuration by Operating System

### Linux

Edit the `/etc/hosts` file with root privileges:

```bash
sudo nano /etc/hosts
```

Add the following lines (replace `192.168.1.100` with your server's IP):

```
192.168.1.100  git.server_name n8n.server_name navidrome.server_name paperless.server_name synapse.server_name
```

Save and exit. Changes take effect immediately.

### macOS

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

### Windows

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

## Testing

After configuration, test the connection from your client device:

```bash
ping git.server_name
curl http://git.server_name
```

## HTTPS Considerations

**Note:** When accessing services via local hostnames (e.g., `https://git.server_name`), your browser will show a certificate warning because the SSL certificate is issued for your public domain (e.g., `grimilab.ddns.net`), not for local hostnames.

**Options:**
- Use **HTTP** instead: `http://git.server_name` (no certificate warning)
- Accept the certificate warning in your browser (not recommended for production)
- Generate self-signed certificates for local hostnames (advanced)

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

- - -

# Service Management

## Monitoring Services

### Check Running Containers

View all running containers:

```bash
docker ps
```

View all containers (including stopped):

```bash
docker ps -a
```

### View Service Logs

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

### Inspect Network

Check the shared network configuration:

```bash
docker network inspect ${SHARED_NETWORK}
```

### Reload Nginx Configuration

After modifying nginx configuration files:

```bash
docker exec nginx nginx -t          # Test configuration
docker exec nginx nginx -s reload   # Reload if test passes
```

## Updating Services

### Update All Services

Pull the latest images and restart containers:

```bash
cd <service_directory>
docker compose pull
docker compose up -d
```

### Update Specific Service

```bash
cd gitea
docker compose pull
docker compose up -d
```

### Update All at Once

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

- - -

# Backup and Restore

## What to Backup

### 1. Environment Configuration

```bash
cp .env .env.backup
```

### 2. Data Volumes

All service data is stored in the `data/` directory:

```bash
tar -czf homelab-data-backup-$(date +%Y%m%d).tar.gz data/
```

### 3. PostgreSQL Database

Backup all databases:

```bash
docker exec db pg_dumpall -U ${POSTGRES_USER} > backup-$(date +%Y%m%d).sql
```

Backup specific database:

```bash
docker exec db pg_dump -U ${POSTGRES_USER} gitea > gitea-backup-$(date +%Y%m%d).sql
```

### 4. SSL Certificates

```bash
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz ssl/
```

## Restore from Backup

### Restore Data Volumes

```bash
tar -xzf homelab-data-backup-YYYYMMDD.tar.gz
```

### Restore PostgreSQL Database

```bash
cat backup-YYYYMMDD.sql | docker exec -i db psql -U ${POSTGRES_USER}
```

### Restore Specific Database

```bash
cat gitea-backup-YYYYMMDD.sql | docker exec -i db psql -U ${POSTGRES_USER} -d gitea
```

- - -

# Troubleshooting

## Common Issues

### Nginx Fails to Start

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

### Database Connection Failed

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

### 502 Bad Gateway

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

### Container Exits Immediately

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

### Services Can't Communicate

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

### Local Hostname Not Resolving

**Symptom:** `git.jarvis` doesn't work from client device

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

- - -

# Security Best Practices

## Change Default Passwords

After initial setup, change all default passwords:

1. **PostgreSQL admin password** - Update in `.env` and recreate database
2. **Service-specific passwords** - Update in each service's web interface
3. **Synapse registration secret** - Update in `.env` and regenerate config

## Firewall Configuration

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

## SSL Certificate Renewal

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

## Secure the .env File

Protect your environment file:

```bash
chmod 600 .env
```

Never commit `.env` to version control.

## Regular Updates

Keep your services updated to patch security vulnerabilities:

```bash
# Update all images monthly
./shutdown.sh
docker compose -f */docker compose.yaml pull
./startup.sh
```

- - -

# Port Mapping Reference

## External Ports (Exposed to Host)

| Service    | Port | Protocol | Purpose                    |
|------------|------|----------|----------------------------|
| Nginx      | 80   | HTTP     | Web traffic (redirects)    |
| Nginx      | 443  | HTTPS    | Secure web traffic         |
| Nginx      | 8448 | HTTPS    | Matrix federation          |

## Internal Ports (Container Network Only)

| Service    | Port | Access Via                          |
|------------|------|-------------------------------------|
| PostgreSQL | 5432 | Internal network only               |
| Gitea      | 3000 | `git.${DOMAIN}` via nginx           |
| n8n        | 5678 | `n8n.${DOMAIN}` via nginx           |
| Navidrome  | 4533 | `music.${DOMAIN}` via nginx         |
| Paperless  | 8000 | `docs.${DOMAIN}` via nginx          |
| Synapse    | 8008 | `synapse.${DOMAIN}` via nginx       |
| Redis      | 6379 | Paperless only                      |

**Note:** Only nginx exposes ports to the host. All other services are accessed through nginx reverse proxy.

- - -

# System Requirements

## Software Dependencies

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Bash**: For running orchestration scripts
- **OpenSSL**: For SSL certificate generation

### Check Versions

```bash
docker --version
docker compose --version
bash --version
openssl version
```

## Network Requirements

- Static local IP address (recommended for homelab server)
- Port forwarding configured on router (for external access):
  - Port 80 → Server IP:80
  - Port 443 → Server IP:443
  - Port 8448 → Server IP:8448 (if using Matrix/Synapse)

## Domain Requirements

- Registered domain name (free options: No-IP, DuckDNS, FreeDNS)
- DNS A record pointing to your public IP
- Dynamic DNS client if you don't have a static public IP (see No-IP DUC section)
