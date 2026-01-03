# Home Server Hosting

These sub-projects contain docker-compose files used to host servers on your home server(s) to:

-  Avoid paying for cloud services
-  Keep your data private
-  Run services even with no Internet

## Prerequisites

to ensure that all **.sh** files are executable on a Linux machine you need to run the following
```
cd scripts
chmod +x ensure-executable.sh
./ensure-executable.sh
cd ..
```

Then you should run the following which:
* sets common environment variables
* installs docker
* installs tailscale client

```
./install-core.sh
```

## Usage

### Use config from previous installations

Some services has support for inporting config from installations done on previous machines.

For these you need to:
1. Copy your config folders to the **backup** folder in this project (see the readme in that folder)
2. go into the specific folders & run the scripts named **restore-from-backup.sh**

This is supported for:
* headscale
* nginx-reverse-proxy

### Install services
To install the different services you just run, this will ask you for which services you want to install
```
./install.sh
```
It will use the common env settings you set in the install-core script

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

### Overview

![deployemnt](docs/overview.drawio.svg)

## Synology

There is also a folder containing scripts if you want to run the containers on a Synology NAS
