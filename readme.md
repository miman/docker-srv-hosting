# Home Server Hosting

These sub-projects contain docker-compose files used to host servers on your home server(s) to:

-  Avoid paying for cloud services
-  Keep your data private
-  Run services even with no Internet

### Core idea of this repo
The core idea is to automatically setup a local cloud with most services you would use cloud services for:

### Services

| Service             | Description                                            |
| ------------------- | ------------------------------------------------------ |
| [ComfyUI](ai/comfy_ui/ReadMe.md) | Powerful and modular stable diffusion GUI/backend |
| [Docmost](cloud-services/docmost/readme.md)             | Self-hosted documentation/wiki platform                |
| [Glance Dashboard](cloud-services/glance-dashboard/readme.md)    | Customizable dashboard/monitoring                      |
| [Headscale](infrastructure/headscale/readme.md)           | Self-hosted Tailscale secure network server (like VPN) |
| [Home Assistant](cloud-services/home-assistant/ReadMe.md)      | Home automation platform                               |
| [Immich](cloud-services/immich/readme.md)              | Self-hosted photo & video backup                       |
| [Linux-in-Docker](cloud-services/linux-in-docker/readme.md)     | Lightweight Linux desktop in Docker with Web UI        |
| [Lyra](ai/3d/Lyra/readme.md) | NVIDIA Lyra-2.0 for high-performance AI generation |
| [Netbird](infrastructure/netbird/readme.md) | Zero-configuration VPN for secure device connectivity |
| [Nextcloud](cloud-services/nextcloud/readme.md)           | File sync and collaboration suite                      |
| [Nextcloud AIO](cloud-services/nextcloud-aio/readme.md)       | Easy-to-deploy Nextcloud All-in-One version            |
| [Nginx Reverse Proxy](infrastructure/nginx-reverse-proxy/readme.md) | Reverse proxy for web services                         |
| [DuckDNS Updater](infrastructure/duckdns-updater/readme.md) | Dynamic DNS updater for DuckDNS service to keep your domain name updated with your current IP address.                                    | 
| [Ollama LLM server](ai/ollama/ReadMe.md)   | Local LLM (AI) server                                  |
| [Open WebUI for Ollama](ai/open-webui/ReadMe.md)   | Web interface for Ollama LLM                           |
| [Portainer](infrastructure/portainer/readme.md)           | Docker management srv OR Agent                         |
| [Registry](infrastructure/registry/readme.md)           | Local Docker registry                         |
| [SearXNG](ai/searxng/readme.md)   | Privacy-respecting metasearch engine (used for web search in local AI)                  |
| [Synapse](cloud-services/synapse/readme.md) | Matrix homeserver for secure communication (chat/video)  |
| [Traccar](cloud-services/traccar/readme.md)             | GPS tracking platform                                  |
| [Vaultwarden](cloud-services/vaultwarden/readme.md)         | Self-hosted password manager                           |
| [Verdaccio](development/verdaccio/README.md)         | Local NPM registry                           |
| [Watchtower](infrastructure/watchtower/readme.md) | Automates Docker container image updates               |

### Volume folders & Backup

You can decide where the root folder for all volumes should be. This is where all your service data is stored. 

This enables you to recreate the Docker containers without loosing any data.

You can also select to automatically do backup of the volumes to a dedicated backup disk or an existing folder.

## What should I install ?

See the [what-should-i-install.md](docs/installation-tips/what-should-i-install.md) for the recommended setup.

## Installation & Setup

1. **Start the Installer**
   Run the main installation script. This serves as a unified entry point for setting up your environment, configuring backups, and installing services.
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Configuration Steps**
   The script will guide you through:
   - **Docker Root**: Where to store your service configuration and data (default: `~/docker_stacks`).
   - **Base DNS**: Domain for your services (e.g., `example.duckdns.org`).
   - **Backups**: 
     - Choose between backing up to a **Dedicated Backup Disk** (formatted automatically) or an **Existing Folder**.
     - Backups are automatically scheduled (defaults to daily at 03:00 AM).

3. **Service Selection**
   - You will be presented with a list of available services (e.g., Immich, Home Assistant, Nextcloud).
   - Select the services you want to install.

### Advanced Options
- **`-askwatchtower`**: By default, the installer remembers your Watchtower preference for each service in `watchtower_configs.yaml`. If you want to change these settings for already-installed services, run the installer with this flag:
  ```bash
  ./install.sh -askwatchtower
  ```

### Smart Backups
This project handles backups automatically for installed services.
- **Auto-Discovery**: When you install a service via `install.sh`, a dedicated backup script is generated for it in its directory (e.g., `cloud-services/immich/backup.sh`).
- **Context-Aware**:
  - Services with Databases (Postgres) get a script that dumps the DB + syncs files.
  - Other services get a smart Rsync backup.
- **Master Schedule**: All active services are added to a master backup schedule (`backup/master-backup.sh`).

### Adding More Services Later
Want to install another service later? Just run `./install.sh` again!
- It detects your existing configuration.
- It asks if you want to use the existing settings.
- It skips directly to the service selection menu so you can add new apps quickly.

### Restoring Data (Legacy Support)
Some services support importing config from previous installations:
1. Copy your config folders to the local `backup` folder.
2. Go into the specific service folder & run `restore-from-backup.sh` (if available).
This is supported for: `headscale`, `nginx-reverse-proxy`.

### Overview

![deployemnt](docs/overview.drawio.svg)

## Synology

There is also a folder (**synology-nas**) containing scripts if you want to run the containers on a Synology NAS
