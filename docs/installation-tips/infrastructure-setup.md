# Infrastructure setup

The minimal setup of infrastructure services to get a secure network with HTTPS-certificate for you local services.

These are the base services required for running the other services in this repository.

## Recommended services

These services are required for the minimal setup (Netbird is optional if you use it through LAN only).

| Service             | Description                                            |
| ------------------- | ------------------------------------------------------ |
| Docker | Docker is used to run all the services in this project |
| [Netbird](../../infrastructure/netbird/readme.md) | Zero-configuration VPN for secure device connectivity |
| [Nginx Reverse Proxy](../../infrastructure/nginx-reverse-proxy/readme.md) | Reverse proxy for web services                         |
| [Watchtower](../../infrastructure/watchtower/readme.md) | Automates Docker container image updates               |
| [Portainer](infrastructure/portainer/readme.md)           | Docker management srv OR Agent                         |

## Optional services

These services are not required for the minimal setup, but could be nice if you have that specific need.

| Service             | Description                                            |
| ------------------- | ------------------------------------------------------ |
| [Synapse](../../cloud-services/synapse/readme.md) | Matrix homeserver for secure communication (chat/video), if you want to have notifications when services are automatically updated by Watchtower  |
| [Glance Dashboard](../../cloud-services/glance-dashboard/readme.md)    | Customizable dashboard/monitoring                      |
| [Headscale](../../infrastructure/headscale/readme.md)           | Self-hosted Tailscale secure network server (like VPN) |
| [DuckDNS Updater](../../infrastructure/duckdns-updater/readme.md) | Dynamic DNS updater for DuckDNS service to keep your domain name updated with your current IP address.                                    | 
| [Glance Dashboard](../../cloud-services/glance-dashboard/readme.md)    | Customizable dashboard/monitoring                      |
| [Linux-in-Docker](../../cloud-services/linux-in-docker/readme.md)     | Lightweight Linux desktop in Docker with Web UI        |
| [Registry](infrastructure/registry/readme.md)           | Local Docker registry                         |



## Prerequisites

### DuckDNS name
You MUST have created an account & a DNS domain for you the machine you will install the NGINX Proxy Manager on [DuckDNS](https://www.duckdns.org/) before installing this.

Ex: if the machine you will run NGINX Proxy Manager on has the internal IP address **192.168.0.42** you should create a DuckDNS domain like ***mynet.duckdns.org*** set it to **192.168.0.42**.

Where **mynet** should be replaced with your name.
