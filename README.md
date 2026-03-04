# Modular Homelab Infrastructure

This project provides a modular, containerized approach to managing your home services (Matrix/Synapse, n8n, PostgreSQL) using Docker and Nginx as a reverse proxy. The infrastructure is defined as code (IaC), allowing for rapid setup, deployment, and cleanup.

## Architecture

The system is built on a modular design where each service has its own directory and lifecycle, coordinated by a central set of orchestration scripts.

*   **Reverse Proxy:** Nginx (Containerized).
*   **Database:** PostgreSQL (Centralized).
*   **Services:** Synapse, n8n.
*   **Network:** Shared bridge network (`homelab_net`).

## Project Structure

```
.
├── db/              # PostgreSQL service definitions
├── n8n/             # n8n service definitions
├── nginx/           # Reverse proxy configuration
├── synapse/         # Matrix server definitions
├── data/            # Synapse persistent configuration (generated)
├── templates/       # Configuration templates (IaC)
├── setup.sh         # Script to generate configs based on .env
├── orchestrator.sh  # Script to deploy/start services
└── cleanup.sh       # Script to wipe the environment
```
    

## Deployment

This workflow uses a clear separation between infrastructure generation and service execution.

### 1\. Configuration

Create a `.env` file in the project root with the following variables:

DOMAIN="your.domain.com"
EMAIL="your@email.com"
POSTGRES\_PASSWORD="your\_strong\_password"
SYNAPSE\_REGISTRATION\_SHARED\_SECRET="your\_secret\_key"
    

### 2\. Prepare the Infrastructure

Run the setup script to generate configurations and directory structures from templates:

```
chmod +x setup.sh
./setup.sh
```

### 3\. Deploy

Launch the services in the correct dependency order:

```
chmod +x orchestrator.sh
./orchestrator.sh
```

## Cleanup

**Warning:** Running `cleanup.sh` will stop containers, remove the network, and delete the generated configurations and data directories. **This will delete your databases.**

```
./cleanup.sh
```
