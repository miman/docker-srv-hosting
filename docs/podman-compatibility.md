# Podman & Docker Hybrid Compatibility Guide

This document explains how the Home Server Center hosts services compatibility between standard Docker and rootless Podman (on cgroupv2 systems like Ubuntu).

To keep the codebase clean, maintainable, and prevent polluting base configurations, we use a **dynamic overlay system**.

---

## 🛠️ The Architecture

Instead of modifying the main `docker-compose.yml` to mix security options and volume overrides, we split them:
1. **`docker-compose.yml`**: Contains the standard, clean configuration for Docker.
2. **`docker-compose.podman.yml`**: Contains only the Podman-specific overrides.

### How it is executed (`run_compose`)
We defined a custom wrapper function called `run_compose` in `scripts/read-config.sh` and exported it as the `$COMPOSE_CMD`.
- When running under **Docker**, it executes:
  `docker compose ...` (using only `docker-compose.yml`).
- When running under **Podman**, it automatically detects if a `.podman.yml` (or `.podman.yaml`) counterpart exists in the directory and overlays it:
  `podman compose -f docker-compose.yml -f docker-compose.podman.yml ...`

This makes it immediately obvious which services have Podman-specific modifications, as they will contain a `docker-compose.podman.yml` file.

---

## 📋 The Podman Compatibility Rules

Whenever adapting a service for Podman, do not touch the base `docker-compose.yml`. Instead, create a `docker-compose.podman.yml` in the same directory and implement these three rules:

### 1. Disable SELinux labeling & use Kubernetes file logging
Podman requires `security_opt: ["label=disable"]` to access the Docker socket/host directories without permission errors and `logging.driver: "k8s-file"` to avoid cgroupv2/swappiness errors.
```yaml
services:
  service-name:
    security_opt:
      - "label=disable"
    logging:
      driver: "k8s-file"
```

### 2. Append `:Z` flags to bind mounts
Rootless Podman uses SELinux/AppArmor mapping which requires appending `:Z` to volume and socket mounts to allow access inside the container:
```yaml
services:
  service-name:
    volumes:
      - ${DOCKER_SOCK:-/var/run/docker.sock}:/var/run/docker.sock:Z
      - ${DOCKER_VOLUMES:-/var/lib/docker/volumes}:/var/lib/docker/volumes:Z
```

### 3. Keep environment variables generic
Ensure the base `docker-compose.yml` uses the exported environment variables rather than hardcoded paths, so they remain fully compatible with both engines:
- Use `${DOCKER_SOCK:-/var/run/docker.sock}` for sockets.
- Use `${DOCKER_VOLUMES:-/var/lib/docker/volumes}` for volumes.

---

## 🟢 Currently Configured Services

| Service | Subdirectory | Podman Supported? | Overrides File |
| :--- | :--- | :---: | :--- |
| **Portainer Agent** | `infrastructure/portainer/portainer-agent` | Yes | `docker-compose.podman.yml` |
| **Matrix Synapse** | `cloud-services/synapse` | Yes | `docker-compose.podman.yaml`<br>`docker-compose.element-web.podman.yaml` |

---

## 🚀 How to Add Podman Support to a New Service

1. **Verify Base Compose**: Ensure the base `docker-compose.yml` uses `${DOCKER_SOCK:-/var/run/docker.sock}` and `${DOCKER_VOLUMES:-/var/lib/docker/volumes}` instead of hardcoded paths.
2. **Create Overrides**: Create `docker-compose.podman.yml` in the service folder.
3. **Define Overrides**: Specify only the fields that need overrides (such as `security_opt`, `logging`, and `volumes` with `:Z`).
4. **Deploy**: Run `./install.sh` (or the service's own install script) normally. The installer will automatically merge and apply the overrides when `CONTAINER_ENGINE=podman` is active.
