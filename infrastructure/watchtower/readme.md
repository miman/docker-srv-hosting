# Watchtower

This docker-compose.yml file installs [Watchtower](https://containrrr.dev/watchtower/), an essential "set-it-and-forget-it" automation tool for anyone running a Docker-based home lab or server.

## 🚀 Project Description: Watchtower
[Watchtower](https://containrrr.dev/watchtower/) is an open-source utility that automates the lifecycle of your Docker containers. Instead of manually checking for updates, pulling new images, and restarting services, Watchtower handles the entire maintenance pipeline in the background.

### Core Workflow
**Monitor**: It periodically checks the Docker Hub (or your private registry) to see if a newer version of your running images has been released.

**Pull & Compare**: If an update is found, it downloads the new image.

**Restart**: It gracefully shuts down your existing container and restarts it using the exact same settings (volumes, network, environment variables) but with the new image.

**Cleanup**: It removes the old, redundant images to save disk space.

## Why use this?
**Security**: Automatically applies the latest security patches to your apps.

**Stability**: Keeps your software on the latest stable releases without manual effort.

**Efficiency**: Eliminates the "chore" of updating 10+ different containers one by one.

## Technical Note
Watchtower communicates directly with the Docker Daemon via the docker.sock volume. This gives it the "admin" rights needed to manage other containers on your behalf.

## Manually enable checks for project
In the docker compose file, WATCHTOWER_LABEL_ENABLE=true. 

This tells Watchtower: "Do not touch any container unless I specifically give you permission."

To give for example Immich permission to auto-update, you just need to add one line to your Immich docker-compose.yml under the services you want to update:

```YAML
services:
  immich-server:
    # ... your other settings ...
    labels:
      - com.centurylinklabs.watchtower.enable=true

  immich-machine-learning:
    # ... your other settings ...
    labels:
      - com.centurylinklabs.watchtower.enable=true
```

## Environment variables
Here is a description on the env variables used in the docker compose file


|Variable |	Function |
|----|-----|
|WATCHTOWER_CLEANUP	| When set to true, Watchtower deletes the old image after it pulls the new one. Without this, your hard drive would eventually fill up with multiple versions of the same app. |
| WATCHTOWER_POLL_INTERVAL	| Defines how often (in seconds) Watchtower checks for updates. 86400 seconds equals exactly 24 hours. |
|WATCHTOWER_LABEL_ENABLE |	This is a "safety first" setting. When true, Watchtower will only update containers that have a specific Docker label (com.centurylinklabs.watchtower.enable=true). It prevents it from accidentally updating everything on your system. |
| DOCKER_API_VERSION | Sets the Docker API version. Required for compatibility with some Docker environments. |
| WATCHTOWER_HTTP_API_UPDATE | Enables the HTTP API for triggering updates manually. |
| WATCHTOWER_HTTP_API_PERIODIC_POLLS | Ensures that the periodic timer still runs even when the HTTP API is enabled. |
| WATCHTOWER_HTTP_API_TOKEN | A security token required to authorize requests to the HTTP API. |
| WATCHTOWER_DEBUG | When enabled, provides verbose logging for troubleshooting. |

## HTTP API & Manual Triggers
Watchtower is configured with an HTTP API enabled on port `8080` (bound to `localhost`). This allows you to force an update check immediately instead of waiting for the 24-hour timer.

### Trigger Script
You can use the included script to trigger an update:
```bash
./trigger-update.sh
```

### Automation (Run on Startup)
To make Watchtower check for updates 3 minutes after every system boot, add the following to your crontab (`crontab -e`):
```bash
@reboot sleep 180 && /path/to/watchtower/trigger-update.sh
```

