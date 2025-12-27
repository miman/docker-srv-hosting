# Home Server Hosting

These sub-projects contain docker-compose files used to host servers on your home server(s) to:

-  Avoid paying for cloud services
-  Keep your data private
-  Run services even with no Internet

## Prerequisites

to ensure that all **.sh** files are executable on a Linux machine you need to:
1. run **chmod +x scripts/ensure-executable.sh**
2. run **scripts/ensure-executable.sh**

## Services

| Service             | Description                                            |
| ------------------- | ------------------------------------------------------ |
| Home Assistant      | Home automation platform                               |
| Nextcloud           | File sync and collaboration suite                      |
| Ollama LLM server   | Local LLM (AI) server                                  |
| Ollama Open WebUI   | Web interface for Ollama LLM                           |
| Nginx Reverse Proxy | Reverse proxy for web services                         |
| Headscale           | Self-hosted Tailscale secure network server (like VPN) |
| Glance Dashboard    | Customizable dashboard/monitoring                      |
| Immich              | Self-hosted photo & video backup                       |
| Portainer           | Docker management srv OR Agent                         |
| Traccar             | GPS tracking platform                                  |
| Vaultwarden         | Self-hosted password manager                           |
| Linux-in-Docker     | Lightweight Linux desktop in Docker with Web UI        |
| Docmost             | Self-hosted documentation/wiki platform                |

## Synology

There is also a folder containing scripts if you want to run the containers on a Synology NAS
